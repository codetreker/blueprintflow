#!/usr/bin/env node
import { parseArgs } from "./lib/dispatcher/arg-parser.mjs";

const { verb, args, flags, knownVerb } = parseArgs(process.argv.slice(2));

if (verb === "help" || !knownVerb) {
  const helpMod = await import("./lib/verbs/help.mjs").catch(() => null);
  if (helpMod) { await helpMod.help({ args, flags }); process.exit(0); }
  console.log(`bf — Blueprintflow (alpha)\nVerb '${verb}' not yet wired. Try: bf execute|create|show|help`);
  process.exit(verb === "help" ? 0 : 2);
}

const mod = await import(`./lib/verbs/${verb}.mjs`);
await mod[verb]({ args, flags });
