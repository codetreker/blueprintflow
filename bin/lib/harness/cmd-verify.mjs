import fs from "node:fs";
import { woDir, taskDir, roundDir, verifyResultFile } from "./wo-paths.mjs";
import { findLatestRound, listResultFiles } from "./verify-round.mjs";
import { parseReviewResult } from "./parse-review-result.mjs";
import { writeVerifyResultMd } from "./write-verify-result.mjs";
import { formatTimestamp } from "./write-updated.mjs";
import { loadWo } from "./load-wo.mjs";
import { verifyModeA } from "./cmd-verify-mode-a.mjs";
import { verifyModeB } from "./cmd-verify-mode-b.mjs";
import { verifyModeC } from "./cmd-verify-mode-c.mjs";

function decideMode({ taskId, bf, bundle }) {
  const state = bf.frontmatter.State;
  if (!taskId && state === "Draft") return "A";
  if (taskId && ["Accepted", "Implementing"].includes(state)) return "B";
  if (!taskId && state === "Implementing") {
    const allCompleted = bundle.tasks.every(t => t.spec?.frontmatter.State === "Completed");
    return allCompleted ? "C" : null;
  }
  return null;
}

export async function cmdVerify({ baseHome, woId, taskId = null, repoRoot, now = new Date() }) {
  const bundle = await loadWo({ baseHome, woId, repoRoot });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  const mode = decideMode({ taskId, bf: bundle.bf, bundle });
  if (!mode) {
    const scope = taskId ? `${woId}/${taskId}` : woId;
    return { ok: false, error: `phase mismatch: cannot verify ${scope} when bf.md.State = ${bundle.bf.frontmatter.State}` };
  }
  const scopeDir = taskId ? taskDir(baseHome, woId, taskId) : woDir(baseHome, woId);
  const round = findLatestRound(scopeDir);
  if (round === 0) {
    return { ok: false, error: `no review round under ${scopeDir}/runs/reviews/; run start-review first` };
  }
  const roundPath = roundDir(scopeDir, round);
  const parsedResults = [];
  const parseErrors = [];
  for (const f of listResultFiles(roundPath)) {
    try {
      const text = fs.readFileSync(f.file, "utf8");
      parsedResults.push({ ...f, parsed: parseReviewResult(text) });
    } catch (e) {
      parseErrors.push({ file: f.file, message: String(e?.message || e) });
    }
  }
  if (parseErrors.length > 0) {
    return { ok: false, error: "malformed review result(s)", details: parseErrors };
  }

  const ctx = { bundle, scopeDir, round, roundPath, parsedResults, taskId };
  let r;
  if (mode === "A") r = await verifyModeA(ctx);
  else if (mode === "B") r = await verifyModeB(ctx);
  else r = await verifyModeC(ctx);

  const ts = formatTimestamp(now);
  const filePath = verifyResultFile(roundPath);
  writeVerifyResultMd({
    filePath, mode, scope: taskId ? `${woId}/${taskId}` : woId, round, status: r.status,
    timestamp: ts, issues: r.issues || {},
    perAc: r.perAc || null, flipped: r.flipped || [], stateChanges: r.stateChanges || [],
  });
  return { ok: true, status: r.status, path: filePath, mode };
}
