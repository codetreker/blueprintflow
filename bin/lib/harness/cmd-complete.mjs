import fs from "node:fs";
import { taskDir, roundDir, verifyResultFile } from "./wo-paths.mjs";
import { findLatestRound } from "./verify-round.mjs";
import { parseFrontmatter } from "../shared/parse-frontmatter.mjs";
import { writeState, writeUpdated, formatTimestamp } from "./write-mutations.mjs";
import { loadWo } from "./load-wo.mjs";
import { VERIFY_MODES } from "./cmd-verify.mjs";
import { checkGitHubPrMergedGate } from "./github-pr-gate.mjs";

function latestSuccessfulVerify(scopeDir, { mode, scope }) {
  const round = findLatestRound(scopeDir);
  if (round === 0) return null;
  const file = verifyResultFile(roundDir(scopeDir, round));
  if (!fs.existsSync(file)) return null;
  try {
    const { frontmatter } = parseFrontmatter(fs.readFileSync(file, "utf8"));
    if (frontmatter.Result !== "SUCCESS") return null;
    if (frontmatter.Mode !== mode) return null;
    if (frontmatter.Scope !== scope) return null;
    return { round, file, mtimeMs: fs.statSync(file).mtimeMs };
  } catch {
    return null;
  }
}

function taskSpecChangedAfterVerify(task, verify) {
  const stat = fs.statSync(task.specPath);
  return stat.mtimeMs > verify.mtimeMs ? [task.specPath] : [];
}

function fail(error, details = []) {
  return { ok: false, error, details };
}

async function completeTask({ baseHome, woId, taskId, installDir, now }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return fail("load failed", bundle.errors);
  if (!["Accepted", "Implementing"].includes(bundle.bf.frontmatter.State)) {
    return fail(`phase mismatch: cannot complete ${woId}/${taskId} when bf.md.State = ${bundle.bf.frontmatter.State}`);
  }
  const task = bundle.tasks.find((t) => t.id === taskId);
  if (!task || !task.spec) return fail(`task spec not found: ${taskId}`);
  if (task.spec.frontmatter.State !== "Tasking") {
    return fail(`complete requires task State: Tasking, got ${task.spec.frontmatter.State}`);
  }
  const unchecked = task.spec.acceptanceCriteria.filter((ac) => !ac.checked).map((ac) => ac.id);
  if (unchecked.length > 0) return fail(`unchecked AC: ${unchecked.join(", ")}`);
  const scope = `${woId}/${taskId}`;
  const verify = latestSuccessfulVerify(taskDir(baseHome, woId, taskId), {
    mode: VERIFY_MODES.TASK_VERIFICATION,
    scope,
  });
  if (!verify) return fail("no latest Task Verification SUCCESS; run start-review + review + verify first");
  const changed = taskSpecChangedAfterVerify(task, verify);
  if (changed.length > 0) {
    return fail("task changed after latest Task Verification SUCCESS; run start-review + review + verify again", changed);
  }
  const prGate = checkGitHubPrMergedGate(task);
  if (!prGate.ok) return fail(prGate.error);

  const ts = formatTimestamp(now);
  let specText = fs.readFileSync(task.specPath, "utf8");
  specText = writeState(specText, "Completed", { kind: "taskSpec" });
  specText = writeUpdated(specText, ts);
  fs.writeFileSync(task.specPath, specText);
  return {
    ok: true,
    scope,
    transitioned: { task: { id: taskId, from: "Tasking", to: "Completed" }, timestamp: ts },
  };
}

export async function cmdComplete({ baseHome, woId, taskId = null, installDir, now = new Date() }) {
  if (!taskId) return fail("complete requires <bf-wo>/<task>");
  return completeTask({ baseHome, woId, taskId, installDir, now });
}

export function formatComplete(r) {
  if (!r.ok) return `FAIL\n\n${r.error || "complete failed"}\n`;
  const lines = ["SUCCESS"];
  const t = r.transitioned || {};
  if (t.task) lines.push(`${t.task.id}: ${t.task.from} -> ${t.task.to}`);
  if (t.bf) lines.push(`bf.md: ${t.bf.from} -> ${t.bf.to}`);
  if (t.timestamp) lines.push(`Updated: ${t.timestamp}`);
  return lines.join("\n") + "\n";
}
