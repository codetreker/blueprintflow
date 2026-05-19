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

const USAGE = `Usage:
  bf-harness [--project <slug>] list
  bf-harness [--project <slug>] lint <bf-wo>
  bf-harness [--project <slug>] start-review <bf-wo>[/<task>]
  bf-harness [--project <slug>] accept <bf-wo>
  bf-harness [--project <slug>] next <bf-wo>
  bf-harness [--project <slug>] verify <bf-wo>[/<task>]
  bf-harness [--project <slug>] discard <bf-wo>

Project slug defaults to current directory basename; override with --project or $BF_PROJECT.`;

function out(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }
function fail(msg, code = 2) { process.stderr.write(msg + "\n"); process.exit(code); }

function isSafeSegment(seg) {
  if (!seg || seg === "." || seg === "..") return false;
  if (/[/\\]/.test(seg)) return false;
  if (seg.includes("\0")) return false;
  return true;
}

// Extract --project / -p <slug> from argv, returning { slug, rest }.
// Returns slug=null if flag not present; throws-style returns { error } on malformed.
function extractProjectFlag(argv) {
  const rest = [];
  let slug = null;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--project" || a === "-p") {
      if (i + 1 >= argv.length) return { error: `${a} requires a value` };
      slug = argv[i + 1];
      i++;
    } else if (a.startsWith("--project=")) {
      slug = a.slice("--project=".length);
    } else {
      rest.push(a);
    }
  }
  return { slug, rest };
}

function parseTarget(s) {
  if (!s) return { woId: null, taskId: null };
  const parts = s.split("/");
  if (parts.length < 1 || parts.length > 2) return null;
  const [woId, taskId] = parts;
  if (!isSafeSegment(woId)) return null;
  if (taskId !== undefined && !isSafeSegment(taskId)) return null;
  return { woId, taskId: taskId || null };
}

const ARITY = {
  list:           { wo: "forbidden", task: "forbidden" },
  lint:           { wo: "required",  task: "forbidden" },
  accept:         { wo: "required",  task: "forbidden" },
  next:           { wo: "required",  task: "forbidden" },
  discard:        { wo: "required",  task: "forbidden" },
  "start-review": { wo: "required",  task: "optional" },
  verify:         { wo: "required",  task: "optional" },
};

function validateArity(subcmd, t) {
  const rule = ARITY[subcmd];
  if (!rule) return null;
  if (rule.wo === "required" && !t.woId) return `${subcmd} requires <bf-wo>`;
  if (rule.wo === "forbidden" && t.woId) return `${subcmd} takes no positional target`;
  if (rule.task === "forbidden" && t.taskId) return `${subcmd} does not accept a task id`;
  return null;
}

function resolveRepoRoot() {
  if (process.env.BF_REPO_ROOT) return process.env.BF_REPO_ROOT;
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
}

async function main() {
  const rawArgs = process.argv.slice(2);
  const flagRes = extractProjectFlag(rawArgs);
  if (flagRes.error) fail(`${flagRes.error}\n${USAGE}`, 2);
  const { slug: flagSlug, rest } = flagRes;
  const [subcmd, target] = rest;

  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    return;
  }

  const projectSlug = flagSlug || process.env.BF_PROJECT || path.basename(process.cwd());
  if (!isSafeSegment(projectSlug)) fail(`invalid project slug: '${projectSlug}'\n${USAGE}`, 2);

  const baseHome = process.env.BF_HOME || path.join(os.homedir(), ".bf");
  const repoRoot = resolveRepoRoot();
  const t = parseTarget(target);
  if (!t) fail(`invalid target argument\n${USAGE}`, 2);
  const arityErr = validateArity(subcmd, t);
  if (arityErr) fail(`${arityErr}\n${USAGE}`, 2);

  if (subcmd === "verify") {
    const r = await cmdVerify({ baseHome, projectSlug, woId: t.woId, taskId: t.taskId, repoRoot });
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
      r = await cmdList({ baseHome, projectSlug }); break;
    case "lint":
      r = await cmdLint({ baseHome, projectSlug, woId: t.woId, repoRoot }); break;
    case "start-review":
      r = await cmdStartReview({ baseHome, projectSlug, woId: t.woId, taskId: t.taskId }); break;
    case "accept":
      r = await cmdAccept({ baseHome, projectSlug, woId: t.woId, repoRoot }); break;
    case "next":
      r = await cmdNext({ baseHome, projectSlug, woId: t.woId, repoRoot }); break;
    case "discard":
      r = await cmdDiscard({ baseHome, projectSlug, woId: t.woId }); break;
    default:
      fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
  }
  out(r);
  process.exit(r.ok ? 0 : 1);
}

main().catch((e) => fail(String(e?.stack || e), 1));
