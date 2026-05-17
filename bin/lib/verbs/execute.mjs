import { resolveWo } from "../dispatcher/wo-resolver.mjs";
import { discoverPacks } from "../dispatcher/pack-discovery.mjs";
import { selectFlow } from "../dispatcher/flow-selector.mjs";
import { runFlowToCompletion } from "../dispatcher/flow-runner.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";

export async function execute({ args, flags }) {
  const woId = args[0];
  if (!woId) { console.log(JSON.stringify({ error: "wo id required" })); process.exit(2); }
  const packs = await discoverPacks();
  const maxOuterTicks = flags.maxTicks ? Number(flags.maxTicks) : 10;

  for (let outer = 0; outer < maxOuterTicks; outer++) {
    const wo = await resolveWo(woId);
    if (!wo.exists) { console.log(JSON.stringify({ error: `WO not found` })); process.exit(2); }
    const pack = packs.find(p => p.id === wo.pack);
    if (!pack) { console.log(JSON.stringify({ error: `Pack '${wo.pack}' not installed` })); process.exit(2); }

    if (wo.current_state === "done") {
      console.log(JSON.stringify({ done: true, wo: woId, current_state: wo.current_state }));
      return;
    }

    const flowId = selectFlow(pack.manifest, wo);
    if (!flowId) {
      console.log(JSON.stringify({ stuck: true, wo: woId, current_state: wo.current_state, hint: `no flow for ${wo.schema},${wo.current_state} — check pack.json.routing` }));
      return;
    }

    const flowFile = path.join(pack.path, "flows", `${flowId}.json`);
    const flow = JSON.parse(await readFile(flowFile, "utf8"));
    if (flow.core_type === "loop") {
      console.log(JSON.stringify({ deferred: true, reason: "loop core_type — Stage 5", wo: woId, attemptedFlow: flowId }));
      return;
    }

    const r = await runFlowToCompletion({ wo, pack, flowId });
    if (r.status === "agents-needed") { console.log(JSON.stringify(r)); return; }
    if (r.error) { console.log(JSON.stringify({ ...r, wo: woId, attemptedFlow: flowId })); return; }
    if (flags.oneStep) { console.log(JSON.stringify({ ...r, oneStep: true })); return; }
  }
  console.log(JSON.stringify({ error: "max outer ticks exceeded" }));
}
