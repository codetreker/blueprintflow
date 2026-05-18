# Migrating from v6 plugin to v1 BF

If you used the `blueprintflow` plugin (v6.x) in Claude Code, this is
the path forward.

## TL;DR

- The v6 plugin (`plugins/blueprintflow/`) still works side-by-side
  with v1. You can uninstall it when you're confident in v1.
- v1 BF is an npm package: `npm install -g @codetreker/bf` (publish
  pending — see Status in `README.md`).
- The 21 v6 skills become either Pack content (protocols, schemas,
  roles) under `packs/product-engineering/` or are retired.
- A Stage 5 real-agent demo drove a fresh task WO `new → done`
  end-to-end on v1; see
  `docs/specs/2026-05-18-stage-5-demo-trace.md`.

## Skill-by-skill mapping

Lifted from `docs/specs/2026-05-16-bf-fork-design/bf-skill-migration.md`.
`pack/` is shorthand for `packs/product-engineering/`.

| v6 skill | Target | v1 destination | Status |
|---|---|---|---|
| `bf-brainstorm` | → Brainstorm protocol | `pack/protocols/brainstorm-blueprint.md` | Pack content (v1.x bulk migration) |
| `bf-blueprint-write` | → Brainstorm protocol | `pack/protocols/write-blueprint.md` | Pack content (v1.x) |
| `bf-blueprint-iteration` | → Brainstorm protocol | `pack/protocols/iterate-blueprint.md` | Pack content (v1.x) |
| `bf-task-fourpiece` | → Brainstorm protocol | `pack/protocols/brainstorm-task.md` | **Landed** in v1 (Stage 3) |
| `bf-phase-plan` | → Breakdown protocol | `pack/protocols/breakdown-blueprint-to-phase.md` | Pack content (v1.x) |
| `bf-milestone-breakdown` | → Breakdown protocol | `pack/protocols/breakdown-phase-to-milestone.md` | Pack content (v1.x) |
| `bf-implementation-design` | → Breakdown protocol | `pack/protocols/breakdown-milestone-to-task.md` | **Landed** in v1 (Stage 3) |
| `bf-milestone-progress` | → Loop protocol | `pack/protocols/loop-milestone.md` | **Landed** in v1 (Stage 3); `loop` verb itself deferred to v1.x |
| `bf-task-execute` | → Close protocol | `pack/protocols/close-leaf-task.md` | **Landed** in v1 (Stage 3) |
| `bf-pr-review-flow` | → Close protocol section | inside `close-leaf-task.md` | **Landed** in v1 |
| `bf-verification` | → Close protocol section | inside `close-leaf-task.md` | **Landed** in v1 |
| `bf-phase-exit-gate` | → Close protocol (non-leaf) | `pack/protocols/close-nonleaf-phase.md` | Pack content (v1.x) |
| `bf-issue-triage` | → Defer to v2 | (would be `intake` Core verb) | Deferred |
| `bf-task-state-standard` | → Schema | `pack/schemas/task.json` | **Landed** in v1 (Stage 3) |
| `bf-current-doc-standard` | → Schema | `pack/schemas/blueprint.json` (and similar) | Pack content (v1.x) |
| `bf-team-roles` | → Roles | `pack/roles/*.md` | **Landed** in v1 (Stage 3) |
| `bf-git-workflow` | → Loop/Close protocol section | referenced from `loop-*.md` and `close-leaf-task.md` | Pack content (v1.x) |
| `bf-runtime-adapter` | → **Retire** | — | **Retired** in v1 (Stage 6.3); subsumed by `bf` runtime |
| `bf-teamlead-role-reminder` | → **Retire** | — | **Retired** in v1 (Stage 6.3); role lives in Pack `roles/` |
| `bf-teamlead-slow-cron-checkin` | → **Retire** (re-enter v2) | — | **Retired** in v1 (Stage 6.3); cron behavior deferred to v2 `sweep` verb |
| `using-plueprint` | → Pack skill | `pack/skills/using-bf/` | Renamed (typo fix); migration pending v1.x |

The historical copies of the 3 retired skills are preserved under
`packs/product-engineering/reference-v6/` so the v6 content remains
diffable inside the v1 repo.

## Backwards-compatibility

- The v6 plugin remains marketplace-installable; v1 lives on npm.
- WO directory layout is new in v1 (`~/.bf/wo/<id>/wo.md`); v6 had
  no persistent WO home.
- **State name aliases.** v6 used long state names (`reviewed_task_ready`,
  `accepted_task`, `milestone_planned`, `milestone_done`); v1
  canonical states are `new / shaped / broken_down / doing /
  children_done / done`. The product-engineering Pack's `pack.json`
  carries `state_aliases` mapping the v6 names to v1 canonical so
  existing workflows still resolve.

## When to switch

- **Starting a fresh project:** use v1.
- **Mid-project on v6:** finish that project on v6, then switch.
- **Want both:** install both; they don't conflict. v6 ships as a
  Claude Code plugin; v1 ships as an npm package with a `/bf` skill.

## Retiring the v6 plugin

Once v1 has carried you through a full project end-to-end:

```bash
# Confirm v1 is your sole Blueprintflow
which bf            # → /path/to/global/node_modules/.bin/bf
bf pack list        # → product-engineering

# Remove v6 from your marketplace (procedure depends on how you
# installed the plugin; typically delete from the marketplace config).
```

## Stage 5 demo proof

The Stage 5 demo trace
(`docs/specs/2026-05-18-stage-5-demo-trace.md`) records a real task
WO driven end-to-end through v1 BF, with real Claude subagents at
every node and a real code commit at the end. That's the concrete
confidence anchor for switching.
