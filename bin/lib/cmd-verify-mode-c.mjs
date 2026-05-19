import fs from "node:fs";
import { collectFindings } from "./verify-round.mjs";
import { computeAcSignoff } from "./compute-ac-signoff.mjs";
import { flipCheckbox } from "./write-checkbox.mjs";
import { writeState } from "./write-state.mjs";
import { writeUpdated, formatTimestamp } from "./write-updated.mjs";

// "2026-05-19 12:34" → epoch ms; bad parse → NaN
function tsToEpoch(s) {
  if (!s) return NaN;
  const m = String(s).match(/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})$/);
  if (!m) return NaN;
  const [, Y, M, D, h, mn] = m.map(Number);
  return new Date(Y, M - 1, D, h, mn).getTime();
}

function checkRoundFreshness(parsedResults, bundle) {
  if (parsedResults.length === 0) {
    return ["no result files in round"];
  }
  let earliestMtimeMs = Infinity;
  for (const r of parsedResults) {
    const stat = fs.statSync(r.file);
    if (stat.mtimeMs < earliestMtimeMs) earliestMtimeMs = stat.mtimeMs;
  }
  let latestCompletedMs = -Infinity;
  for (const t of bundle.tasks) {
    if (t.spec?.frontmatter.State !== "Completed") continue;
    const epoch = tsToEpoch(t.spec.frontmatter.Updated);
    if (!Number.isNaN(epoch) && epoch > latestCompletedMs) latestCompletedMs = epoch;
  }
  // 余量 60 秒，避免同一秒写入导致的边界
  if (latestCompletedMs > 0 && earliestMtimeMs <= latestCompletedMs + 60_000) {
    return ["stale round: round files predate latest task completion; run start-review for bf-level review"];
  }
  return [];
}

export async function verifyModeC({ bundle, parsedResults }) {
  const issues = collectFindings(parsedResults);
  if (issues.blocker.length > 0 || issues.high.length > 0) {
    return { status: "FAIL", issues };
  }
  const staleness = checkRoundFreshness(parsedResults, bundle);
  if (staleness.length > 0) {
    return { status: "FAIL", issues: { blocker: staleness, high: [] } };
  }
  const signoff = computeAcSignoff({
    acList: bundle.bf.acceptanceCriteria,
    reviewResults: parsedResults,
    roleReg: bundle.roleReg,
  });
  if (signoff.missing.length > 0) {
    return { status: "FAIL", issues: { blocker: [], high: [] }, perAc: signoff.perAc };
  }
  let bfText = fs.readFileSync(bundle.bfPath, "utf8");
  for (const id of signoff.flipped) bfText = flipCheckbox(bfText, id);
  bfText = writeState(bfText, "Completed", { kind: "bf" });
  bfText = writeUpdated(bfText, formatTimestamp());
  fs.writeFileSync(bundle.bfPath, bfText);
  return {
    status: "SUCCESS",
    perAc: signoff.perAc,
    flipped: signoff.flipped,
    stateChanges: ["bf.md: Implementing -> Completed"],
  };
}
