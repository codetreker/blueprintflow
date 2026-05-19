#!/usr/bin/env node
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { cmdList } from "./lib/cmd-list.mjs";
import { cmdLint } from "./lib/cmd-lint.mjs";
import { cmdStartReview } from "./lib/cmd-start-review.mjs";
import { cmdAccept } from "./lib/cmd-accept.mjs";
import { cmdNext } from "./lib/cmd-next.mjs";
import { cmdVerify } from "./lib/cmd-verify.mjs";
import { cmdDiscard } from "./lib/cmd-discard.mjs";

const [, , subcmd, target] = process.argv;
const USAGE = `Usage:
  bf-harness list <project-slug>
  bf-harness lint <project-slug>/<bf-wo>
  bf-harness start-review <project-slug>/<bf-wo>[/<task>]
  bf-harness accept <project-slug>/<bf-wo>
  bf-harness next <project-slug>/<bf-wo>
  bf-harness verify <project-slug>/<bf-wo>[/<task>]
  bf-harness discard <project-slug>/<bf-wo>`;

function out(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }
function fail(msg, code = 2) { process.stderr.write(msg + "\n"); process.exit(code); }

function isSafeSegment(seg) {
  if (!seg || seg === "." || seg === "..") return false;
  if (/[/\\]/.test(seg)) return false;
  if (seg.includes("\0")) return false;
  return true;
}

function parseTarget(s) {
  if (!s) return null;
  const parts = s.split("/");
  if (parts.length < 1 || parts.length > 3) return null;
  const [projectSlug, woId, taskId] = parts;
  if (!isSafeSegment(projectSlug)) return null;
  if (woId !== undefined && !isSafeSegment(woId)) return null;
  if (taskId !== undefined && !isSafeSegment(taskId)) return null;
  return { projectSlug, woId: woId || null, taskId: taskId || null };
}

function resolveRepoRoot() {
  if (process.env.BF_REPO_ROOT) return process.env.BF_REPO_ROOT;
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
}

async function main() {
  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    return;
  }
  const baseHome = process.env.BF_HOME || path.join(os.homedir(), ".bf");
  const repoRoot = resolveRepoRoot();
  const t = parseTarget(target);
  if (!t) fail(`invalid or missing target argument\n${USAGE}`, 2);

  if (subcmd === "verify") {
    const r = await cmdVerify({ baseHome, projectSlug: t.projectSlug, woId: t.woId, taskId: t.taskId, repoRoot });
    if (!r.ok) {
      process.stdout.write(`FAIL ${r.error}\n`);
      process.exit(2);
    }
    process.stdout.write(`${r.status} ${r.path}\n`);
    process.exit(r.status === "SUCCESS" ? 0 : 1);
  }

  let r;
  switch (subcmd) {
    case "list":
      r = await cmdList({ baseHome, projectSlug: t.projectSlug }); break;
    case "lint":
      r = await cmdLint({ baseHome, projectSlug: t.projectSlug, woId: t.woId, repoRoot }); break;
    case "start-review":
      r = await cmdStartReview({ baseHome, projectSlug: t.projectSlug, woId: t.woId, taskId: t.taskId }); break;
    case "accept":
      r = await cmdAccept({ baseHome, projectSlug: t.projectSlug, woId: t.woId, repoRoot }); break;
    case "next":
      r = await cmdNext({ baseHome, projectSlug: t.projectSlug, woId: t.woId, repoRoot }); break;
    case "discard":
      r = await cmdDiscard({ baseHome, projectSlug: t.projectSlug, woId: t.woId }); break;
    default:
      fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
  }
  out(r);
  process.exit(r.ok ? 0 : 1);
}

main().catch((e) => fail(String(e?.stack || e), 1));
