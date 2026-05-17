#!/usr/bin/env node
import { parseArgs } from "./lib/dispatcher/arg-parser.mjs";

const { verb, args, flags, knownVerb } = parseArgs(process.argv.slice(2));

if (verb === "help") {
  const helpMod = await import("./lib/verbs/help.mjs").catch(() => null);
  if (helpMod) { await helpMod.help({ args, flags }); process.exit(0); }
  console.log(`bf — Blueprintflow (alpha)\nTry: bf execute|create|show|help`);
  process.exit(0);
}

if (!knownVerb) {
  const nl = await import("./lib/dispatcher/nl-parse.mjs");
  const t = nl.transcribeDeterministic(process.argv.slice(2));
  if (t.verb && t.source !== "needs-llm") {
    console.error(`[bf] transcribed: bf ${t.verb} ${t.args.join(" ")}`);
    const escapeVerbsNL = new Set(["skip", "pass", "stop", "goto", "resume"]);
    const modPathNL = escapeVerbsNL.has(t.verb) ? "./lib/verbs/escape.mjs" : `./lib/verbs/${t.verb}.mjs`;
    const mod = await import(modPathNL);
    await mod[t.verb]({ args: t.args, flags: t.flags });
    process.exit(0);
  }
  console.log(JSON.stringify({
    error: `Unknown verb '${verb}'. Natural-language parsing requires Claude Code skill context; CLI usage requires a verb. Run 'bf help' for the catalog.`,
  }));
  process.exit(2);
}

const escapeVerbs = new Set(["skip", "pass", "stop", "goto", "resume"]);
const modPath = escapeVerbs.has(verb) ? "./lib/verbs/escape.mjs" : `./lib/verbs/${verb}.mjs`;
const mod = await import(modPath);
await mod[verb]({ args, flags });
