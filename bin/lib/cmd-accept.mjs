import fs from "node:fs";
import { roundDir, runsReviewsDir, verifyResultFile } from "./wo-paths.mjs";
import { writeState } from "./write-state.mjs";
import { writeUpdated, formatTimestamp } from "./write-updated.mjs";
import { parseFrontmatter } from "./parse-frontmatter.mjs";
import { loadWo } from "./load-wo.mjs";
import { validateWo } from "./validate-wo.mjs";

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

function hasModeASuccess(woPath) {
  const n = latestRound(woPath);
  if (n === 0) return false;
  const file = verifyResultFile(roundDir(woPath, n));
  if (!fs.existsSync(file)) return false;
  try {
    const { frontmatter } = parseFrontmatter(fs.readFileSync(file, "utf8"));
    return frontmatter.Result === "SUCCESS" && frontmatter.Mode === "A";
  } catch { return false; }
}

export async function cmdAccept({ baseHome, projectSlug, woId, repoRoot, now = new Date() }) {
  const bundle = await loadWo({ baseHome, projectSlug, woId, repoRoot });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  if (bundle.bf.frontmatter.State !== "Draft") {
    return { ok: false, error: `already accepted (State=${bundle.bf.frontmatter.State})` };
  }
  const validation = validateWo(bundle);
  if (!validation.ok) return { ok: false, error: "lint failed", details: validation.errors };
  if (!hasModeASuccess(bundle.woPath)) {
    return { ok: false, error: "no Mode A SUCCESS in latest round; run start-review + spec review + verify first" };
  }

  const ts = formatTimestamp(now);
  let bfText = fs.readFileSync(bundle.bfPath, "utf8");
  bfText = writeState(bfText, "Accepted", { kind: "bf" });
  bfText = writeUpdated(bfText, ts);
  fs.writeFileSync(bundle.bfPath, bfText);

  const transitions = {};
  for (const t of bundle.tasks) {
    let text = fs.readFileSync(t.specPath, "utf8");
    text = writeState(text, "Ready", { kind: "taskSpec" });
    text = writeUpdated(text, ts);
    fs.writeFileSync(t.specPath, text);
    transitions[t.id] = "Draft->Ready";
  }
  return {
    ok: true,
    transitioned: { bf: "Draft->Accepted", tasks: transitions, timestamp: ts },
  };
}
