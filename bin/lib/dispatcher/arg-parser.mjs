const KNOWN_VERBS = new Set([
  "execute", "create", "brainstorm", "breakdown", "loop", "close",
  "show", "tree", "list", "discard",
  "skip", "pass", "stop", "goto", "resume",
  "pack", "flow", "help",
]);

function camel(kebab) {
  return kebab.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

export function parseArgs(argv) {
  if (argv.length === 0 || argv[0] === "--help" || argv[0] === "-h") {
    return { verb: "help", args: [], flags: {} };
  }
  const verb = argv[0];
  const rest = argv.slice(1);
  const args = [];
  const flags = {};
  for (let i = 0; i < rest.length; i++) {
    const t = rest[i];
    if (t.startsWith("--")) {
      const key = camel(t.slice(2));
      const next = rest[i + 1];
      if (next === undefined || next.startsWith("--")) {
        flags[key] = true;
      } else {
        flags[key] = next;
        i++;
      }
    } else {
      args.push(t);
    }
  }
  return { verb, args, flags, knownVerb: KNOWN_VERBS.has(verb) };
}
