#!/usr/bin/env node
const [, , subcmd] = process.argv;

const USAGE = `Usage: bf-harness <list|lint|start-review|accept|next|verify|discard> [args...]`;

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
    case "list":
    case "lint":
    case "start-review":
    case "accept":
    case "next":
    case "verify":
    case "discard":
      fail(`subcommand "${subcmd}" not implemented yet`, 3);
    default:
      fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
  }
}

main().catch((e) => fail(String(e?.stack || e), 1));
