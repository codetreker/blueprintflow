import { resolveWo } from "../dispatcher/wo-resolver.mjs";
import { discoverPacks } from "../dispatcher/pack-discovery.mjs";
import { selectFlow } from "../dispatcher/flow-selector.mjs";
import { runFlowToCompletion } from "../dispatcher/flow-runner.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";

export async function runSingleFlowVerb(expectedCoreType, { args, flags }) {
  const woId = args[0];
  if (!woId) { console.log(JSON.stringify({ error: "wo id required" })); process.exit(2); }

  const wo = await resolveWo(woId);
  if (!wo.exists) { console.log(JSON.stringify({ error: `WO not found: ${woId}`, reason: wo.reason })); process.exit(2); }

  const packs = await discoverPacks();
  const pack = packs.find(p => p.id === wo.pack);
  if (!pack) { console.log(JSON.stringify({ error: `Pack '${wo.pack}' not installed` })); process.exit(2); }

  const flowId = selectFlow(pack.manifest, wo);
  if (!flowId) { console.log(JSON.stringify({ error: `no flow for ${wo.schema},${wo.current_state}` })); process.exit(2); }

  const flowFile = path.join(pack.path, "flows", `${flowId}.json`);
  const flow = JSON.parse(await readFile(flowFile, "utf8"));
  if (flow.core_type !== expectedCoreType) {
    console.log(JSON.stringify({ error: `wrong core_type: expected ${expectedCoreType}, flow ${flowId} has ${flow.core_type}` }));
    process.exit(2);
  }

  if (expectedCoreType === "loop") {
    console.log(JSON.stringify({ deferred: true, reason: "loop core_type requires child-WO dispatch — Stage 5", flow: flowId }));
    process.exit(0);
  }

  const r = await runFlowToCompletion({ wo, pack, flowId });
  console.log(JSON.stringify({ ...r, wo: woId }));
  if (r.error) process.exit(2);
}
