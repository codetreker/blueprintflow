// Shared helper for single-flow verbs: init harness → walk nodes via node-runner →
// finalize → update wo.md current_state. Returns { finalized, terminalNode, newState }.
import path from "node:path";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { runNode } from "./node-runner.mjs";

const HARNESS = "node bin/bf-harness.mjs";
const MAX_TICKS = 50;

function sh(cmd) {
  const r = spawnSync("bash", ["-c", cmd], { encoding: "utf8" });
  return { code: r.status, stdout: (r.stdout || "").trim(), stderr: (r.stderr || "").trim() };
}

export async function runFlowToCompletion({ wo, pack, flowId }) {
  const flowFile = path.join(pack.path, "flows", `${flowId}.json`);
  const flow = JSON.parse(await readFile(flowFile, "utf8"));
  const runDir = path.join(wo.path, "runs", `run-${Date.now()}`);
  await mkdir(runDir, { recursive: true });

  const initOut = sh(`${HARNESS} init --flow-file ${flowFile} --entry ${flow.nodes[0]} --dir ${runDir}`);
  if (initOut.code !== 0) return { error: `init failed: ${initOut.stderr || initOut.stdout}` };

  let nodeId = flow.nodes[0];
  for (let i = 0; i < MAX_TICKS; i++) {
    const r = await runNode({
      packPath: pack.path,
      flowFile,
      runDir,
      nodeId,
      transitionToNext: true,
    });
    if (!r.sealed) return { error: r.error };
    if (!r.nextNode) {
      const finOut = sh(`${HARNESS} finalize --flow-file ${flowFile} --dir ${runDir}`);
      if (finOut.code !== 0) return { error: `finalize failed: ${finOut.stderr || finOut.stdout}` };
      const newState = flow.produces?.desired_state;
      if (newState) {
        const woMdPath = path.join(wo.path, "wo.md");
        const md = await readFile(woMdPath, "utf8");
        await writeFile(woMdPath, md.replace(/current_state:\s*\S+/, `current_state: ${newState}`));
      }
      return { finalized: true, terminalNode: nodeId, newState, flowId };
    }
    nodeId = r.nextNode;
  }
  return { error: "max ticks exceeded" };
}
