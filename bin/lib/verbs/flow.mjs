import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { discoverPacks } from "../dispatcher/pack-discovery.mjs";

const HARNESS = path.resolve(fileURLToPath(import.meta.url), "../../../bf-harness.mjs");

export async function flow({ args, flags }) {
  const sub = args[0];
  const packs = await discoverPacks();
  if (!sub || sub === "list") {
    const packFilter = args[1];
    for (const p of packs) {
      if (packFilter && p.id !== packFilter) continue;
      const flows = p.manifest.flows ?? [];
      for (const f of flows) {
        const id = path.basename(f, ".json");
        console.log(`${p.id}\t${id}`);
      }
    }
    return;
  }
  if (sub === "viz") {
    const flowId = args[1];
    if (!flowId) { console.log(JSON.stringify({ error: "flow viz requires <flow-id>" })); process.exit(2); }
    // Find the flow file across packs
    let flowFile = null;
    for (const p of packs) {
      for (const f of (p.manifest.flows ?? [])) {
        const id = path.basename(f, ".json");
        if (id === flowId) {
          flowFile = path.resolve(p.path, f);
          break;
        }
      }
      if (flowFile) break;
    }
    if (!flowFile) { console.log(JSON.stringify({ error: "flow not found", flow: flowId })); process.exit(2); }
    const r = spawnSync("node", [HARNESS, "viz", "--flow-file", flowFile], { encoding: "utf8" });
    if (r.stdout) process.stdout.write(r.stdout);
    if (r.stderr) process.stderr.write(r.stderr);
    if (r.status && r.status !== 0) process.exit(r.status);
    return;
  }
  console.log(JSON.stringify({ error: `unknown flow sub-verb: ${sub}` }));
  process.exit(2);
}
