const VERB_DOCS = {
  execute: {
    syntax: "bf execute <wo-id> [--pack <id>]",
    summary: "Drive a work order from its current_state toward its desired_state by selecting and running a flow.",
  },
  create: {
    syntax: "bf create <wo-id> --pack <id> --schema <schema>",
    summary: "Scaffold a new work order under $BF_WO_HOME/<wo-id>/wo.md with current_state=new and desired_state inferred.",
  },
  brainstorm: {
    syntax: "bf brainstorm <wo-id>",
    summary: "Run the brainstorm flow to shape a new task (new → shaped).",
  },
  breakdown: {
    syntax: "bf breakdown <wo-id>",
    summary: "Break a milestone down into child task work orders (shaped → broken_down).",
  },
  loop: {
    syntax: "bf loop <wo-id>",
    summary: "Iterate a milestone over its child tasks (broken_down → done). Deferred to Stage 5.",
  },
  close: {
    syntax: "bf close <wo-id>",
    summary: "Close a leaf task work order (doing → done).",
  },
  show: {
    syntax: "bf show <wo-id>",
    summary: "Print a work order's frontmatter, body, and recent run dirs.",
  },
  tree: {
    syntax: "bf tree [--all]",
    summary: "Render the WO home as an indented tree. By default hides terminal-state WOs; pass --all to include them.",
  },
  list: {
    syntax: "bf list [--pack <id>] [--state <s>] [--schema <s>]",
    summary: "Flat list of work orders with optional filters.",
  },
  discard: {
    syntax: "bf discard <wo-id> --force",
    summary: "Remove a work order directory. Requires --force (non-interactive).",
  },
  skip: {
    syntax: "bf skip <wo-id>",
    summary: "Escape: skip the current node in the active flow run.",
  },
  pass: {
    syntax: "bf pass <wo-id>",
    summary: "Escape: force-pass the current gate.",
  },
  stop: {
    syntax: "bf stop <wo-id>",
    summary: "Escape: terminate the active flow, preserving state.",
  },
  goto: {
    syntax: "bf goto <node-id> --wo <wo-id>",
    summary: "Escape: jump to a specific node (cycle limits still enforced).",
  },
  resume: {
    syntax: "bf resume <wo-id>",
    summary: "Escape: resume an interrupted run. (Stage 5)",
  },
  pack: {
    syntax: "bf pack <list|info> [<pack-id>]",
    summary: "Inspect discovered packs.",
  },
  flow: {
    syntax: "bf flow <list|viz> [<pack-id>|<flow-id>]",
    summary: "List flows by pack or visualize a flow graph.",
  },
  help: {
    syntax: "bf help [<verb>]",
    summary: "Show the verb catalog or details for a single verb.",
  },
  version: {
    syntax: "bf version",
    summary: "Print the bf package version (from package.json) to stdout.",
  },
};

export async function help({ args }) {
  const target = args[0];
  if (!target) {
    console.log("bf — Blueprintflow dispatcher\n");
    console.log("Verbs:");
    for (const [v, d] of Object.entries(VERB_DOCS)) {
      console.log(`  ${v.padEnd(11)}  ${d.summary}`);
    }
    console.log("\nRun 'bf help <verb>' for usage.");
    return;
  }
  const d = VERB_DOCS[target];
  if (!d) { console.log(`Unknown verb: ${target}`); process.exit(2); }
  console.log(`${d.syntax}\n\n${d.summary}`);
  if (target === "execute") {
    console.log("\nSemantics: bf drives current_state toward desired_state by selecting a flow whose accepts/produces match the work order.");
  }
}
