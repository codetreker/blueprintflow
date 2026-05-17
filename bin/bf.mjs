#!/usr/bin/env node

// bf — Blueprintflow dispatcher (Stage 4 placeholder)
//
// The full bf dispatcher (task inference, flow selection, role dispatch)
// lives in the bf-run Claude Code skill, which lands in Stage 4. Until
// then, this binary tells the user where to look.

const HARNESS_PATH = "bin/bf-harness.mjs";

console.log(`bf — Blueprintflow (alpha)
=============================

The 'bf' dispatcher will be implemented as the bf-run skill in Stage 4.
For now:

  • Use bf-harness for runtime CLI operations:
      bf-harness --help
      bf-harness init --flow <template> ...
      bf-harness transition --from <n> --to <n> --verdict <V> ...

  • Read the design and contracts:
      ~/.claude/skills/bf/SKILL.md                 (skill entry)
      ~/.claude/skills/bf/references/*.md          (5 Core contracts)
      ~/.claude/skills/bf/docs/specs/2026-05-16-bf-fork-design.md  (full design)

  • From inside Claude Code, you'll invoke '/bf <task>' once Stage 4 lands.

Status: v0.1.0-alpha (Stage 1+2 of the fork plan complete).
`);
process.exit(0);
