import { rm } from "node:fs/promises";
import { resolveWo } from "../dispatcher/wo-resolver.mjs";

export async function discard({ args, flags }) {
  const woId = flags.wo ?? args[0];
  if (!woId) { console.log(JSON.stringify({ error: "discard requires wo id" })); process.exit(2); }
  const wo = await resolveWo(woId);
  if (!wo.exists) { console.log(JSON.stringify({ error: "wo not found", wo: woId })); process.exit(2); }
  if (!flags.force) {
    console.log(JSON.stringify({ error: "discard requires --force (non-interactive)", wo: woId }));
    process.exit(2);
  }
  await rm(wo.path, { recursive: true, force: true });
  console.log(JSON.stringify({ discarded: true, wo: woId }));
}
