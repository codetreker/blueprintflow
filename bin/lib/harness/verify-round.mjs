import fs from "node:fs";
import path from "node:path";
import { runsReviewsDir, roundDir } from "./wo-paths.mjs";

export function findLatestRound(scopeDir) {
  const dir = runsReviewsDir(scopeDir);
  if (!fs.existsSync(dir)) return 0;
  let maxN = 0;
  for (const n of fs.readdirSync(dir)) {
    const m = n.match(/^round_(\d+)$/);
    if (m) maxN = Math.max(maxN, Number(m[1]));
  }
  return maxN;
}

export function listResultFiles(roundPath) {
  if (!fs.existsSync(roundPath)) return [];
  return fs.readdirSync(roundPath)
    .filter(n => /^result_[A-Za-z][\w-]*_\d+\.md$/.test(n))
    .map(n => {
      const m = n.match(/^result_([A-Za-z][\w-]*)_(\d+)\.md$/);
      return { role: m[1], idx: Number(m[2]), file: path.join(roundPath, n) };
    });
}

export function collectFindings(parsedResults) {
  const blocker = [];
  const high = [];
  for (const r of parsedResults) {
    // Fail closed: a review file with accepted criteria but no recognizable
    // Results structure is a blocking parse error, so verify fails on it and
    // its (already dropped) acceptedIds are never honored for signoff.
    if (r.parsed.parseError) {
      blocker.push(`[${r.role}#${r.idx}] unrecognized review Results section (no recognizable Results structure); failing closed`);
    }
    for (const b of r.parsed.severities.blocker) blocker.push(`[${r.role}#${r.idx}] ${b}`);
    for (const h of r.parsed.severities.high) high.push(`[${r.role}#${r.idx}] ${h}`);
  }
  return { blocker, high };
}

export { roundDir };
