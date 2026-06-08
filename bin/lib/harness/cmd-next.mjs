import fs from "node:fs";
import { taskDir } from "./wo-paths.mjs";
import { writeState, writeUpdated, formatTimestamp, writeTaskExecutionMetadata } from "./write-mutations.mjs";
import { loadWo } from "./load-wo.mjs";
import { buildPipelineRegistry, findPipeline } from "../shared/pipeline-registry.mjs";
import { prepareTaskWorktree } from "./managed-git.mjs";

export async function cmdNext({ baseHome, woId, installDir, now = new Date(), cwd = process.cwd() }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
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
  if (eligible.length === 0) return { ok: false, error: "no eligible task" };

  const chosen = eligible.find((t) => t.spec.frontmatter.State === "Ready") || eligible[0];
  const pipeline = chosen.spec.frontmatter.Pipeline;
  const pipelineReg = buildPipelineRegistry({
    packReg: bundle.packReg,
    pack: bundle.bf.frontmatter.Pack,
    localPipelinesDir: bundle.localPipelinesDir,
  });
  const pipelineEntry = findPipeline(pipelineReg, bundle.bf.frontmatter.Pack, pipeline);
  if (!pipelineEntry) return { ok: false, error: `pipeline not found: ${pipeline}` };
  const ts = formatTimestamp(now);
  let executionMetadata = chosen.spec.executionMetadata || {};

  if (chosen.spec.frontmatter.State === "Ready") {
    if (chosen.spec.requiresWorktree) {
      const setup = prepareTaskWorktree({ baseHome, cwd, woId, taskId: chosen.id });
      if (!setup.ok) return { ok: false, error: setup.error };
      executionMetadata = {
        branch: setup.branch,
        worktree: setup.worktree,
        pullRequest: null,
      };
    }
    let text = fs.readFileSync(chosen.specPath, "utf8");
    text = writeState(text, "Tasking", { kind: "taskSpec" });
    if (chosen.spec.requiresWorktree) {
      text = writeTaskExecutionMetadata(text, executionMetadata);
    }
    text = writeUpdated(text, ts);
    fs.writeFileSync(chosen.specPath, text);

    if (bfState === "Accepted") {
      let bfText = fs.readFileSync(bundle.bfPath, "utf8");
      bfText = writeState(bfText, "Implementing", { kind: "bf" });
      bfText = writeUpdated(bfText, ts);
      fs.writeFileSync(bundle.bfPath, bfText);
    }
  }

  const task = {
    taskId: chosen.id,
    taskDir: taskDir(baseHome, woId, chosen.id),
    specPath: chosen.specPath,
    desc: chosen.spec.frontmatter.Desc,
    pipeline,
    pipelinePath: pipelineEntry.file,
    pack: bundle.bf.frontmatter.Pack,
  };
  if (executionMetadata.branch) task.branch = executionMetadata.branch;
  if (executionMetadata.worktree) task.worktree = executionMetadata.worktree;
  if (executionMetadata.pullRequest) task.pullRequest = executionMetadata.pullRequest;
  return {
    ok: true,
    task,
  };
}

/**
 * Format the result of cmdNext as labeled key:value lines.
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
 * Required fields (`taskId`, `pipeline`, `pipelinePath`, `pack`, `specPath`,
 * `taskDir`) must be present and non-empty on `ok: true` — a missing one
 * signals a cmd-layer bug, so this formatter throws rather than masking the
 * regression with a sentinel.
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
  const t = r.task || {};
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
  return lines.join("\n") + "\n";
}
