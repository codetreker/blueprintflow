#!/usr/bin/env node
const [, , subcmd] = process.argv;

const USAGE = `Usage: bf <list-roles|list-packs> [args...]`;

function fail(msg, code = 2) {
  process.stderr.write(msg + "\n");
  process.exit(code);
}

async function main() {
  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    process.exit(0);
  }
  switch (subcmd) {
    case "list-roles":
    case "list-packs":
      fail(`subcommand "${subcmd}" not implemented yet`, 3);
    default:
      fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
  }
}

main().catch((e) => fail(String(e?.stack || e), 1));
