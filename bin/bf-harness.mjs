#!/usr/bin/env node
// To add a subcommand: create `cmd-foo.mjs` (pure, returns `{ok, ...}`) and
// export a matching `formatFoo` from the same file (pure, takes the cmd
// result, returns the printable text). Wire it into the switch below.
// Stream / exit-code routing belongs in this dispatcher — formatters return
// strings only.
import path from "node:path";
import { fileURLToPath } from "node:url";
import { cmdList, formatList } from "./lib/harness/cmd-list.mjs";
import { cmdLint, formatLint } from "./lib/harness/cmd-lint.mjs";
import { cmdStartReview, formatStartReview } from "./lib/harness/cmd-start-review.mjs";
import { cmdAccept, formatAccept } from "./lib/harness/cmd-accept.mjs";
import { cmdNext, formatNext } from "./lib/harness/cmd-next.mjs";
import { cmdVerify, formatVerifyResult, formatVerifySetupError } from "./lib/harness/cmd-verify.mjs";
import { cmdDiscard, formatDiscard } from "./lib/harness/cmd-discard.mjs";

const USAGE = `Usage:
  bf-harness list
  bf-harness lint <bf-wo>
  bf-harness start-review <bf-wo>[/<task>]
  bf-harness accept <bf-wo>
  bf-harness next <bf-wo>
  bf-harness verify <bf-wo>[/<task>]
  bf-harness discard <bf-wo>

State directory: $BF_HOME (default: <cwd>/.bf).`;

function write(text) { process.stdout.write(text.endsWith("\n") ? text : text + "\n"); }
function fail(msg, code = 2) { process.stderr.write(msg + "\n"); process.exit(code); }

function isSafeSegment(seg) {
  if (!seg || seg === "." || seg === "..") return false;
  if (/[/\\]/.test(seg)) return false;
  if (seg.includes("\0")) return false;
  return true;
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

function resolveInstallDir() {
  if (process.env.BF_INSTALL_DIR) return process.env.BF_INSTALL_DIR;
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
}

async function main() {
  const args = process.argv.slice(2);
  const [subcmd, target] = args;

  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    return;
  }

  const baseHome = process.env.BF_HOME || path.join(process.cwd(), ".bf");
  const installDir = resolveInstallDir();
  const t = parseTarget(target);
  if (!t) fail(`invalid target argument\n${USAGE}`, 2);
  const arityErr = validateArity(subcmd, t);
  if (arityErr) fail(`${arityErr}\n${USAGE}`, 2);

  if (subcmd === "verify") {
    const r = await cmdVerify({ baseHome, woId: t.woId, taskId: t.taskId, installDir });
    if (!r.ok) {
      process.stderr.write(formatVerifySetupError(r));
      process.exit(1);
    }
    process.stdout.write(formatVerifyResult(r));
    process.exit(r.status === "SUCCESS" ? 0 : 1);
  }

  let r, text;
  switch (subcmd) {
    case "list":
      r = await cmdList({ baseHome });
      text = formatList(r); break;
    case "lint":
      r = await cmdLint({ baseHome, woId: t.woId, installDir });
      text = formatLint(r); break;
    case "start-review":
      r = await cmdStartReview({ baseHome, woId: t.woId, taskId: t.taskId });
      text = formatStartReview(r); break;
    case "accept":
      r = await cmdAccept({ baseHome, woId: t.woId, installDir });
      text = formatAccept(r); break;
    case "next":
      r = await cmdNext({ baseHome, woId: t.woId, installDir });
      text = formatNext(r); break;
    case "discard":
      r = await cmdDiscard({ baseHome, woId: t.woId });
      text = formatDiscard(r); break;
    default:
      fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
  }
  write(text);
  process.exit(r.ok ? 0 : 1);
}

main().catch((e) => fail(String(e?.stack || e), 1));
