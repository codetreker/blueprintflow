import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { resolveWo } from "../dispatcher/wo-resolver.mjs";

export async function show({ args, flags }) {
  const woId = flags.wo ?? args[0];
  if (!woId) { console.log(JSON.stringify({ error: "show requires wo id" })); process.exit(2); }
  const wo = await resolveWo(woId);
  if (!wo.exists) { console.log(JSON.stringify({ error: "wo not found", wo: woId })); process.exit(2); }
  const md = await readFile(path.join(wo.path, "wo.md"), "utf8");
  process.stdout.write(`# ${woId}\n`);
  process.stdout.write(md);
  if (!md.endsWith("\n")) process.stdout.write("\n");
  // Recent runs
  const runsDir = path.join(wo.path, "runs");
  let runs = [];
  try {
    const entries = await readdir(runsDir);
    runs = entries.filter(e => e.startsWith("run-")).sort();
  } catch {}
  process.stdout.write("\n## Recent runs\n");
  if (runs.length === 0) {
    process.stdout.write("(none)\n");
  } else {
    for (const r of runs.slice(-5)) process.stdout.write(`- ${r}\n`);
  }
}
