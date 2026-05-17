# BF Skill Migration Plan

Companion to [../2026-05-16-bf-fork-design.md](../2026-05-16-bf-fork-design.md).

For each existing skill in `plugins/blueprintflow/skills/`, the target form in the new layout. Migration is structured around BF Core's **four flow types** (`brainstorm` / `breakdown` / `loop` / `close`).

Buckets:

- **→ Brainstorm protocol** — content for the `brainstorm` flow's nodes (typically `discuss` / `write-criteria`)
- **→ Breakdown protocol** — content for the `breakdown` flow's nodes (typically `plan-children` / `write-children` / `review-breakdown`)
- **→ Loop protocol** — content for the `loop` flow's nodes (parallel/sequential child dispatch)
- **→ Close protocol** — content for the `close` flow's nodes (review-overall / exit-gate) and (for leaves) the implementation sequence inside close (implement → review → verify → gate)
- **→ Schema** — `schemas/<name>.json` (Work Object schema)
- **→ Role** — `roles/<name>.md`
- **→ Skill (kept)** — remains a user-invocable skill in either BF Core or Pack
- **→ Retire** — superseded by BF Core / runtime; archived in commit history

In the migration table below, `pack/` is shorthand for `plugins/bf/packs/product-engineering/`.

## Migration table

| Current skill | Target | Location | Notes |
|---|---|---|---|
| **bf-brainstorm** | → Brainstorm protocol | `pack/protocols/brainstorm-blueprint.md` | Used by the brainstorm flow when shaping a top-level WO (blueprint level) |
| **bf-blueprint-write** | → Brainstorm protocol | `pack/protocols/write-blueprint.md` | Used by the brainstorm flow's `write-criteria` node at blueprint level |
| **bf-blueprint-iteration** | → Brainstorm protocol | `pack/protocols/iterate-blueprint.md` | Brainstorm protocol variant for re-shaping a blueprint after first pass |
| **bf-task-fourpiece** | → Brainstorm protocol | `pack/protocols/brainstorm-task.md` | Brainstorm protocol at task level (the "four-piece" content goes into the wo.md sections) |
| **bf-phase-plan** | → Breakdown protocol | `pack/protocols/breakdown-blueprint-to-phase.md` | Breakdown protocol at blueprint level — produces phase child WOs |
| **bf-milestone-breakdown** | → Breakdown protocol | `pack/protocols/breakdown-phase-to-milestone.md` | Breakdown protocol at phase level — produces milestone child WOs |
| **bf-implementation-design** | → Breakdown protocol | `pack/protocols/breakdown-milestone-to-task.md` | Breakdown protocol at milestone level — produces task child WOs |
| **bf-milestone-progress** | → Loop protocol | `pack/protocols/loop-milestone.md` | Loop protocol guiding parallel/sequential dispatch of task children |
| **bf-task-execute** | → Close protocol (leaf implementation) | `pack/protocols/close-leaf-task.md` | Close protocol for leaf WOs — drives implement → review → verify → gate sequence |
| **bf-pr-review-flow** | → Close protocol section | (inside `close-leaf-task.md`) | The "code-review" node's behavior inside leaf close |
| **bf-verification** | → Close protocol section | (inside `close-leaf-task.md`) | The "verify" node's behavior inside leaf close |
| **bf-phase-exit-gate** | → Close protocol (non-leaf) | `pack/protocols/close-nonleaf-phase.md` | Close protocol for phase-level WOs — review cross-milestone integrative criteria |
| **bf-issue-triage** | → Defer to v2 | (would be `intake` Core verb's Pack protocol) | Cron-triggered intake from GitHub; deferred |
| **bf-task-state-standard** | → Schema | `pack/schemas/task.json` | Defines task WO state enum and `wo.md` content conventions |
| **bf-current-doc-standard** | → Schema | `pack/schemas/blueprint.json` (and similar) | Defines blueprint-level WO schema; "current doc" was previously a separate artifact, now folded into blueprint WO state |
| **bf-team-roles** | → Roles | `pack/roles/*.md` | One file per Pack role: PM / Architect / Dev / QA / Teamlead |
| **bf-git-workflow** | → Loop protocol section | (inside `loop-*.md` and `close-leaf-task.md`) | Git/PR conventions referenced from loop and close protocols |
| **bf-runtime-adapter** | → Retire | — | Subsumed by `bf-run` + runtime |
| **bf-teamlead-role-reminder** | → Retire | — | Teamlead behavior moves into the Teamlead role definition + execute orchestration |
| **bf-teamlead-slow-cron-checkin** | → Retire (re-enter via v2 cron) | — | Cron behavior deferred to v2's `sweep` Core verb |
| **using-plueprint** | → Skill (kept) | `pack/skills/using-bf/` | User-invocable Pack entry; renamed to fix typo + align with BF brand |

## Skills in BF Core

Only **one** user-invocable skill lives in `plugins/bf/`:

- `bf-run` — public entry. Routes raw input, selects Pack, dispatches flow via runtime. Written from scratch.

All other Core content is documentation / contracts in `plugins/bf/core/` plus runtime in `plugins/bf/runtime/`. Roles in `plugins/bf/roles/` are loaded by flows, not invoked directly.

## Migration order

Stage 3 (probe, just enough to stress-test Core):

1. Move `plugins/blueprintflow/` content into `plugins/bf/packs/product-engineering/`
2. Write `pack.json` with `state_aliases` for existing v6 state names
3. Migrate four protocols — one per Core flow type:
   - `brainstorm-task.md` (from `bf-task-fourpiece`)
   - `breakdown-milestone-to-task.md` (from `bf-implementation-design`)
   - `loop-milestone.md` (from `bf-milestone-progress`)
   - `close-leaf-task.md` (from `bf-task-execute` + `bf-pr-review-flow` + `bf-verification`)
4. Write `schemas/task.json` and `schemas/milestone.json`
5. Write minimum roles: PM, Architect, Dev, QA, Teamlead

Stage 6 (the rest):

1. Remaining schemas: `phase.json`, `blueprint.json`
2. Remaining brainstorm/breakdown/close protocols for non-task levels
3. Promotion of `using-plueprint` → `using-bf`
4. Retirements: `bf-runtime-adapter`, `bf-teamlead-*` — delete with commit message documenting subsumption

## Open

- Hybrid skills (content spans multiple flow types): the table assigns a primary, but some content may need to be referenced from multiple protocols (e.g. git workflow notes from both loop and close). Allow per-skill adjustment in Stage 6.
- `bf-current-doc-standard` semantically overlaps with both a blueprint schema and a Pack-level convention about "what 'current' means in product engineering". Stage 3 to clarify.
- v2 deferral of `bf-issue-triage` and `bf-teamlead-*` cron behaviors — keep their content as reference notes (commit not deleted), not just retired. Becomes input when `intake` / `sweep` Core verbs are designed.
