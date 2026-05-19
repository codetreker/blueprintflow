#!/usr/bin/env node
import { cmdListRoles } from "./lib/cmd-list-roles.mjs";
import { cmdListPacks } from "./lib/cmd-list-packs.mjs";

const [, , subcmd, ...rest] = process.argv;
const USAGE = `Usage:
  bf list-roles [--pack <pack-id>]
  bf list-packs`;

function out(obj) {
  process.stdout.write(JSON.stringify(obj) + "\n");
}
function fail(msg, code = 2) {
  process.stderr.write(msg + "\n");
  process.exit(code);
}

async function main() {
  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    return;
  }
  const cwd = process.cwd();
  if (subcmd === "list-roles") {
    let pack = null;
    for (let i = 0; i < rest.length; i++) {
      if (rest[i] === "--pack" && rest[i + 1]) { pack = rest[++i]; }
    }
    const r = await cmdListRoles({ cwd, pack });
    out(r);
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "list-packs") {
    const r = await cmdListPacks({ cwd });
    out(r);
    process.exit(r.ok ? 0 : 1);
  }
  fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
}

main().catch((e) => fail(String(e?.stack || e), 1));
