import fs from "node:fs";
import { roundDir, runsReviewsDir, verifyResultFile } from "./wo-paths.mjs";
import { writeState, writeUpdated, writeModeLock, formatTimestamp } from "./write-mutations.mjs";
import { parseFrontmatter } from "../shared/parse-frontmatter.mjs";
import { loadWo } from "./load-wo.mjs";
import { validateWo } from "./validate-wo.mjs";
import { woIntegrationMode } from "./integration-mode.mjs";
import { VERIFY_MODES } from "./cmd-verify.mjs";

function latestRound(woPath) {
  const dir = runsReviewsDir(woPath);
  if (!fs.existsSync(dir)) return 0;
  let maxN = 0;
  for (const n of fs.readdirSync(dir)) {
    const m = n.match(/^round_(\d+)$/);
    if (m) maxN = Math.max(maxN, Number(m[1]));
  }
  return maxN;
}

function latestSpecReviewResult(woPath) {
  const n = latestRound(woPath);
  if (n === 0) return null;
  const file = verifyResultFile(roundDir(woPath, n));
  if (!fs.existsSync(file)) return null;
  try {
    const { frontmatter } = parseFrontmatter(fs.readFileSync(file, "utf8"));
    if (frontmatter.Result !== "SUCCESS" || frontmatter.Mode !== VERIFY_MODES.SPEC_REVIEW) return null;
    return { round: n, file, mtimeMs: fs.statSync(file).mtimeMs };
  } catch { return null; }
}

function contractFilesChangedAfterReview(bundle, reviewedAtMs) {
  const changed = [];
  const files = [bundle.bfPath, ...bundle.tasks.map(t => t.specPath)];
  const localPipelineIds = new Set(
    bundle.tasks
      .filter(t => t.spec)
      .map(t => t.spec.frontmatter.Pipeline)
  );
  if (fs.existsSync(bundle.localPipelinesDir)) {
    for (const name of fs.readdirSync(bundle.localPipelinesDir)) {
      const m = name.match(/^([a-z][a-z0-9-]*)\.yml$/);
      if (m && localPipelineIds.has(m[1])) files.push(`${bundle.localPipelinesDir}/${name}`);
    }
  }
  for (const file of files) {
    const stat = fs.statSync(file);
    if (stat.mtimeMs > reviewedAtMs) changed.push(file);
  }
  return changed;
}

export async function cmdAccept({ baseHome, woId, installDir, now = new Date() }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  if (bundle.bf.frontmatter.State !== "Draft") {
    return { ok: false, error: `already accepted (State=${bundle.bf.frontmatter.State})` };
  }
  const validation = validateWo(bundle);
  if (!validation.ok) return { ok: false, error: "lint failed", details: validation.errors };
  const specReview = latestSpecReviewResult(bundle.woPath);
  if (!specReview) {
    return { ok: false, error: "no Spec Review SUCCESS in latest round; run start-review + spec review + verify first" };
  }
  const changed = contractFilesChangedAfterReview(bundle, specReview.mtimeMs);
  if (changed.length > 0) {
    return {
      ok: false,
      error: "contract changed after latest Spec Review SUCCESS; run start-review + spec review + verify again",
      details: changed.map(file => ({
        code: "CONTRACT_CHANGED_AFTER_REVIEW",
        message: `file changed after ${specReview.file}`,
        ref: file,
      })),
    };
  }

  const ts = formatTimestamp(now);
  // Mode B 5.5 accept-lock: stamp the effective integration mode into the
  // harness-owned Mode-Lock anchor, atomically with the State flip. validateWo
  // then rejects (INTEGRATION_LOCKED) any post-accept Integration value that
  // diverges from this anchor. Mode is valid here — validateWo passed above.
  const acceptedMode = woIntegrationMode(bundle.bf);
  let bfText = fs.readFileSync(bundle.bfPath, "utf8");
  bfText = writeState(bfText, "Accepted", { kind: "bf" });
  bfText = writeModeLock(bfText, acceptedMode);
  bfText = writeUpdated(bfText, ts);
  fs.writeFileSync(bundle.bfPath, bfText);

  const transitions = {};
  for (const t of bundle.tasks) {
    let text = fs.readFileSync(t.specPath, "utf8");
    text = writeState(text, "Ready", { kind: "taskSpec" });
    text = writeUpdated(text, ts);
    fs.writeFileSync(t.specPath, text);
    transitions[t.id] = { from: "Draft", to: "Ready" };
  }
  return {
    ok: true,
    transitioned: {
      bf: { from: "Draft", to: "Accepted" },
      tasks: transitions,
      timestamp: ts,
    },
  };
}

/**
 * Format the result of cmdAccept as line-oriented text.
 * Success:
 *   SUCCESS
 *   bf.md: Draft -> Accepted
 *   <task-id>: Draft -> Ready
 *   Updated: <timestamp>
 * Failure:
 *   FAIL
 *   <blank line>
 *   <top-level error message>
 *   <blank line>
 *   <CODE> at <ref>
 *     <message>
 *   ...
 *
 * The FAIL body shape mirrors format-lint (blank line separator, indented
 * detail block). When cmdAccept returns structured `details`, render them with
 * the same `<code> at <ref>` / `LOAD_ERROR at -` blocks as the lint formatter.
 *
 * cmd-accept returns transitions as structured `{from, to}` pairs so this
 * formatter — not the cmd module — owns the display string (arrow glyph,
 * direction, capitalization). To switch `->` to `→`, edit this file only.
 */
function renderTransition(t) {
  if (!t) return "";
  return `${t.from} -> ${t.to}`;
}

function renderDetail(e) {
  if (typeof e === "string") {
    const msg = e.replace(/\n/g, "\n  ");
    return [`LOAD_ERROR at -`, `  ${msg}`];
  }
  const code = (e.code || "ERROR").replace(/\n/g, " ");
  const ref = (e.ref || "-").replace(/\n/g, " ");
  const msg = (e.message || "").replace(/\n/g, "\n  ");
  return [`${code} at ${ref}`, `  ${msg}`];
}

export function formatAccept(r) {
  if (!r.ok) {
    const lines = ["FAIL", "", r.error || "accept failed"];
    const details = Array.isArray(r.details) ? r.details : [];
    for (const e of details) {
      lines.push("");
      lines.push(...renderDetail(e));
    }
    return lines.join("\n") + "\n";
  }
  const t = r.transitioned || {};
  const lines = ["SUCCESS"];
  if (t.bf) lines.push(`bf.md: ${renderTransition(t.bf)}`);
  for (const [taskId, transition] of Object.entries(t.tasks || {})) {
    lines.push(`${taskId}: ${renderTransition(transition)}`);
  }
  if (t.timestamp) lines.push(`Updated: ${t.timestamp}`);
  return lines.join("\n") + "\n";
}
