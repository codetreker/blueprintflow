// Tiny deterministic mapping for the obvious cases. LLM-driven transcription
// happens at the surrounding skill layer (the `bf` Claude Code skill calls
// out to the host LLM when this returns {verb: null}).
//
// v0.2: keep this small. Stage 5 demo will populate more patterns
// as we see real user input.

const KNOWN_VERBS = new Set([
  "execute", "create", "brainstorm", "breakdown", "loop", "close",
  "show", "tree", "list", "discard",
  "skip", "pass", "stop", "goto", "resume",
  "pack", "flow", "help",
]);

export function transcribeDeterministic(argv) {
  if (argv.length === 0) return { verb: "help", args: [], flags: {} };
  const first = argv[0].toLowerCase();
  if (KNOWN_VERBS.has(first)) {
    // Not actually NL — caller should use verb-first parser
    return { verb: first, args: argv.slice(1), flags: {}, source: "verb-match" };
  }
  // No other deterministic patterns in v0.2; signal LLM-needed
  return { verb: null, args: argv, flags: {}, source: "needs-llm" };
}

// Stage 5 will add: async function transcribeViaLlm(argv) {...} — invokes the
// surrounding Claude skill / API for free-form parsing.
