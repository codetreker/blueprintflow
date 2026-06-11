import fs from "node:fs";
import { woDir, taskDir, roundDir, verifyResultFile } from "./wo-paths.mjs";
import { findLatestRound, listResultFiles, collectFindings } from "./verify-round.mjs";
import { parseReviewResult } from "./parse-review-result.mjs";
import { writeVerifyResultMd } from "./write-verify-result.mjs";
import { flipCheckbox, writeUpdated, formatTimestamp } from "./write-mutations.mjs";
import { computeAcSignoff } from "./compute-ac-signoff.mjs";
import { loadWo } from "./load-wo.mjs";

export const VERIFY_MODES = {
  SPEC_REVIEW: "Spec Review",
  TASK_VERIFICATION: "Task Verification",
  FINAL_ACCEPTANCE: "Final Acceptance",
};

function decideMode({ taskId, bf, bundle }) {
  const state = bf.frontmatter.State;
  if (!taskId && state === "Draft") return VERIFY_MODES.SPEC_REVIEW;
  if (taskId && ["Accepted", "Implementing"].includes(state)) return VERIFY_MODES.TASK_VERIFICATION;
  if (!taskId && state === "Implementing") {
    const allCompleted = bundle.tasks.every(t => t.spec?.frontmatter.State === "Completed");
    return allCompleted ? VERIFY_MODES.FINAL_ACCEPTANCE : null;
  }
  return null;
}

// Spec Review: 任一 reviewer 报 Blocker/High → FAIL；全 clean → SUCCESS。不动 state / checkbox。
async function verifyModeA({ parsedResults }) {
  if (parsedResults.length === 0) {
    return { status: "FAIL", issues: { blocker: ["no result files in round"], high: [] } };
  }
  const issues = collectFindings(parsedResults);
  const status = (issues.blocker.length === 0 && issues.high.length === 0) ? "SUCCESS" : "FAIL";
  return { status, issues };
}

// Task Verification. OR semantics — ≥1 provider signed each AC → signed.
async function verifyModeB({ bundle, parsedResults, taskId }) {
  const issues = collectFindings(parsedResults);
  if (issues.blocker.length > 0 || issues.high.length > 0) {
    return { status: "FAIL", issues };
  }
  const task = bundle.tasks.find(t => t.id === taskId);
  if (!task || !task.spec) {
    return { status: "FAIL", issues: { blocker: [`task spec not found: ${taskId}`], high: [] } };
  }
  const signoff = computeAcSignoff({
    acList: task.spec.acceptanceCriteria,
    reviewResults: parsedResults,
    roleReg: bundle.roleReg,
  });
  if (signoff.missing.length > 0) {
    return { status: "FAIL", issues: { blocker: [], high: [] }, perAc: signoff.perAc };
  }

  let specText = fs.readFileSync(task.specPath, "utf8");
  for (const id of signoff.flipped) specText = flipCheckbox(specText, id);
  specText = writeUpdated(specText, formatTimestamp());
  fs.writeFileSync(task.specPath, specText);

  return {
    status: "SUCCESS",
    perAc: signoff.perAc,
    flipped: signoff.flipped,
    stateChanges: [],
  };
}

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
  if (latestCompletedMs > 0 && earliestMtimeMs < latestCompletedMs) {
    return ["stale round: round files predate latest task completion; run start-review for bf-level review"];
  }
  return [];
}

async function verifyModeC({ bundle, parsedResults }) {
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
  bfText = writeUpdated(bfText, formatTimestamp());
  fs.writeFileSync(bundle.bfPath, bfText);
  return {
    status: "SUCCESS",
    perAc: signoff.perAc,
    flipped: signoff.flipped,
    stateChanges: [],
  };
}

export async function cmdVerify({ baseHome, woId, taskId = null, installDir, now = new Date() }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  const mode = decideMode({ taskId, bf: bundle.bf, bundle });
  if (!mode) {
    const scope = taskId ? `${woId}/${taskId}` : woId;
    return { ok: false, error: `phase mismatch: cannot verify ${scope} when bf.md.State = ${bundle.bf.frontmatter.State}` };
  }
  if (mode === VERIFY_MODES.TASK_VERIFICATION) {
    const task = bundle.tasks.find(t => t.id === taskId);
    const taskState = task?.spec?.frontmatter.State || "missing";
    if (taskState !== "Tasking") {
      return { ok: false, error: `phase mismatch: cannot verify ${woId}/${taskId} when task spec State = ${taskState}` };
    }
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
  if (mode === VERIFY_MODES.SPEC_REVIEW) r = await verifyModeA(ctx);
  else if (mode === VERIFY_MODES.TASK_VERIFICATION) r = await verifyModeB(ctx);
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

/**
 * Format the result of cmdVerify.
 * Three distinct outcomes — all rendered as plain strings; the dispatcher in
 * bf-harness.mjs decides which stream and which exit code:
 *   1. verification ran, status SUCCESS   -> stdout: "SUCCESS <abs-path>" (exit 0)
 *   2. verification ran, status FAIL      -> stdout: "FAIL <abs-path>"    (exit 1)
 *   3. command-level setup failure        -> stderr: "bf-harness verify: <error>" (exit 1)
 *
 * Load failures route to stderr so the same `FAIL` prefix on stdout always means
 * "verification ran and produced a FAIL result", not "the command couldn't start".
 */
export function formatVerifyResult(r) {
  return `${r.status} ${r.path}\n`;
}

export function formatVerifySetupError(r) {
  return `bf-harness verify: ${r.error || "verify failed"}\n`;
}
