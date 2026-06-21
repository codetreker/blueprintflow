import fs from "node:fs";
import { taskDir } from "./wo-paths.mjs";
import { writeState, writeUpdated, formatTimestamp, writeTaskExecutionMetadata } from "./write-mutations.mjs";
import { loadWo } from "./load-wo.mjs";
import { buildPipelineRegistry, findPipeline } from "../shared/pipeline-registry.mjs";
import { prepareTaskWorktree, validateTaskWorktree } from "./managed-git.mjs";
import { integrationError } from "./validate-wo.mjs";

const MAX_NEXT_TASKS = 5;

export async function cmdNext({ baseHome, woId, installDir, now = new Date(), cwd = process.cwd() }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  // Fail closed on a post-accept Integration flip / invalid mode (accept-lock).
  // cmd-next reads/acts on the mode, so it enforces the lock directly — validateWo
  // (lint/accept) is not on this command's path.
  const integ = integrationError(bundle.bf);
  if (integ) return { ok: false, error: `${integ.code}: ${integ.message}` };
  const bfState = bundle.bf.frontmatter.State;
  if (!["Accepted", "Implementing"].includes(bfState)) {
    return { ok: false, error: `wrong state: ${bfState}` };
  }
  if (bundle.tasks.some((t) => !t.spec)) {
    return { ok: false, error: "task spec missing", details: bundle.errors };
  }
  const stateOf = (id) => bundle.tasks.find((t) => t.id === id)?.spec.frontmatter.State;

  const eligible = bundle.tasks.filter((t) => {
    if (!["Ready", "Tasking"].includes(t.spec.frontmatter.State)) return false;
    return t.deps.every((d) => stateOf(d) === "Completed");
  });
  const batch = [];
  for (const task of eligible) {
    if (batch.length >= MAX_NEXT_TASKS) break;
    const conflicts = batch.some((selected) => (
      task.deps.includes(selected.id) || selected.deps.includes(task.id)
    ));
    if (conflicts) continue;
    batch.push(task);
  }
  if (batch.length === 0) return { ok: false, error: "no eligible task" };

  const pipelineReg = buildPipelineRegistry({
    packReg: bundle.packReg,
    pack: bundle.bf.frontmatter.Pack,
    localPipelinesDir: bundle.localPipelinesDir,
  });

  const plans = [];
  for (const task of batch) {
    const pipeline = task.spec.frontmatter.Pipeline;
    const pipelineEntry = findPipeline(pipelineReg, bundle.bf.frontmatter.Pack, pipeline);
    if (!pipelineEntry) return { ok: false, error: `pipeline not found: ${pipeline}` };
    plans.push({
      task,
      pipeline,
      pipelineEntry,
      claim: task.spec.frontmatter.State === "Ready",
      executionMetadata: task.spec.executionMetadata || {},
    });
  }

  const ts = formatTimestamp(now);

  for (const plan of plans) {
    const { task } = plan;
    let executionMetadata = plan.executionMetadata;

    if (plan.claim && task.spec.requiresWorktree) {
      const setup = prepareTaskWorktree({
        baseHome, cwd, woId, taskId: task.id, metadata: executionMetadata,
      });
      if (!setup.ok) return { ok: false, error: setup.error };
      executionMetadata = {
        branch: setup.branch,
        worktree: setup.worktree,
        pullRequest: null,
      };
    } else if (!plan.claim && task.spec.requiresWorktree) {
      const setup = validateTaskWorktree({
        baseHome, cwd, woId, taskId: task.id, metadata: executionMetadata,
      });
      if (!setup.ok) return { ok: false, error: setup.error };
      executionMetadata = {
        ...executionMetadata,
        branch: setup.branch,
        worktree: setup.worktree,
      };
    }

    plan.executionMetadata = executionMetadata;
  }

  for (const plan of plans) {
    if (!plan.claim) continue;
    let text = fs.readFileSync(plan.task.specPath, "utf8");
    text = writeState(text, "Tasking", { kind: "taskSpec" });
    if (plan.task.spec.requiresWorktree) {
      text = writeTaskExecutionMetadata(text, plan.executionMetadata);
    }
    text = writeUpdated(text, ts);
    fs.writeFileSync(plan.task.specPath, text);
  }

  if (bfState === "Accepted" && plans.some((plan) => plan.claim)) {
    let bfText = fs.readFileSync(bundle.bfPath, "utf8");
    bfText = writeState(bfText, "Implementing", { kind: "bf" });
    bfText = writeUpdated(bfText, ts);
    fs.writeFileSync(bundle.bfPath, bfText);
  }

  const tasks = plans.map((plan) => {
    const executionMetadata = plan.executionMetadata;
    const result = {
      taskId: plan.task.id,
      taskDir: taskDir(baseHome, woId, plan.task.id),
      specPath: plan.task.specPath,
      desc: plan.task.spec.frontmatter.Desc,
      pipeline: plan.pipeline,
      pipelinePath: plan.pipelineEntry.file,
      pack: bundle.bf.frontmatter.Pack,
    };
    if (executionMetadata.branch) result.branch = executionMetadata.branch;
    if (executionMetadata.worktree) result.worktree = executionMetadata.worktree;
    if (executionMetadata.pullRequest) result.pullRequest = executionMetadata.pullRequest;
    return result;
  });

  return {
    ok: true,
    tasks,
  };
}

/**
 * Format the result of cmdNext as labeled key:value task blocks.
 * Success:
 *   Task: <id>
 *   Pipeline: <pipeline>
 *   Pipeline path: <abs-path>
 *   Pack: <pack>
 *   Spec: <abs-spec-path>
 *   Dir: <abs-task-dir>
 * Failure:
 *   <error message>
 *
 * Multiple task blocks are separated by a line containing only `---`.
 *
 * Required fields (`taskId`, `pipeline`, `pipelinePath`, `pack`, `specPath`,
 * `taskDir`) must be present and non-empty on every `ok: true` task — a
 * missing one signals a cmd-layer bug, so this formatter throws rather than
 * masking the regression with a sentinel.
 */
const REQUIRED = ["taskId", "pipeline", "pipelinePath", "pack", "specPath", "taskDir"];

function requireField(t, name) {
  const v = t?.[name];
  if (v === undefined || v === null || v === "") {
    throw new Error(`formatNext: missing required task field '${name}' (cmd-next contract violation)`);
  }
  return v;
}

export function formatNext(r) {
  if (!r.ok) return `${r.error || "next failed"}\n`;
  const tasks = r.tasks || [];
  if (!Array.isArray(tasks) || tasks.length === 0) {
    throw new Error("formatNext: missing tasks array (cmd-next contract violation)");
  }
  const blocks = tasks.map((t) => {
    for (const name of REQUIRED) requireField(t, name);
    const lines = [
      `Task: ${t.taskId}`,
      `Pipeline: ${t.pipeline}`,
      `Pipeline path: ${t.pipelinePath}`,
      `Pack: ${t.pack}`,
      `Spec: ${t.specPath}`,
      `Dir: ${t.taskDir}`,
    ];
    if (t.branch) lines.push(`Branch: ${t.branch}`);
    if (t.worktree) lines.push(`Worktree: ${t.worktree}`);
    if (t.pullRequest) lines.push(`Pull-Request: ${t.pullRequest}`);
    return lines.join("\n");
  });
  return blocks.join("\n---\n") + "\n";
}
