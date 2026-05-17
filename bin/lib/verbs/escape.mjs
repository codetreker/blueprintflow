import { readdir } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { resolveWo } from "../dispatcher/wo-resolver.mjs";

const HARNESS = path.resolve(fileURLToPath(import.meta.url), "../../../bf-harness.mjs");

async function activeRunDir(woPath) {
  const runs = path.join(woPath, "runs");
  const entries = await readdir(runs).catch(() => []);
  const runDirs = entries.filter(e => e.startsWith("run-")).sort();
  return runDirs.length ? path.join(runs, runDirs[runDirs.length - 1]) : null;
}

export async function skip({ args, flags }) { return forward("skip", args, flags); }
export async function pass({ args, flags }) { return forward("pass", args, flags); }
export async function stop({ args, flags }) { return forward("stop", args, flags); }
export async function goto({ args, flags }) { return forward("goto", args, flags); }
export async function resume({ args, flags }) { return forward("resume", args, flags); }

async function forward(sub, args, flags) {
  const woId = flags.wo ?? args.find(a => !a.startsWith("--")) ?? null;
  if (sub === "resume" && !woId) {
    console.log(JSON.stringify({ error: "resume without wo: not yet implemented (Stage 5)" }));
    process.exit(2);
  }
  if (!woId) { console.log(JSON.stringify({ error: `${sub} requires wo id` })); process.exit(2); }
  const wo = await resolveWo(woId);
  if (!wo.exists) { console.log(JSON.stringify({ error: "wo not found", wo: woId })); process.exit(2); }
  const runDir = await activeRunDir(wo.path);
  if (!runDir) { console.log(JSON.stringify({ error: "no active run for wo", wo: woId })); process.exit(2); }

  // For goto, pass the target node positional arg through; harness expects: goto <nodeId> --dir <p>
  const positional = args.filter(a => a !== woId);
  const harnessArgs = [HARNESS, sub];
  if (sub === "goto") harnessArgs.push(...positional);
  // resume isn't a vendored harness sub-verb; map to a no-op summary for v0.2
  if (sub === "resume") {
    console.log(JSON.stringify({ resumed: true, wo: woId, runDir, note: "v0.2 resume is a no-op marker" }));
    return;
  }
  harnessArgs.push("--dir", runDir);
  const r = spawnSync("node", harnessArgs, { encoding: "utf8" });
  if (r.stdout) process.stdout.write(r.stdout);
  if (r.stderr) process.stderr.write(r.stderr);
  if (r.status && r.status !== 0) process.exit(r.status);
}
