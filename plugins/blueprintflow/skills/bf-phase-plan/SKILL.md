---
name: bf-phase-plan
description: "Part of the Blueprintflow methodology. Use when locked next-blueprint anchors need Phase/Milestone planning, dependency boundaries, and exit gates before execution readiness."
---

# Phase Plan

Once `docs/blueprint/next/` has `LOCKED` anchors, the Architect leads. Break the selected next work into only the Phases and Milestones needed to express staged progress, prerequisite dependencies, and later integration boundaries. Stop at Phase/Milestone planning; concrete tasks are created later from current execution context.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Preflight check

Before using this skill, read `references/preflight.md` to confirm it applies. The decision graph checks: single-file change? mechanical PR type? blueprint missing? If any skip condition applies, skip this planning flow.

## Phase / Milestone / Task

| Level | Meaning | PR ownership |
|---|---|---|
| Phase | Dependency-ordered stage inside a major iteration, with an integration boundary and exit gates | Not a PR by itself |
| Milestone | User-facing capability or deliverable group inside a Phase | Execution target; not a PR by itself |
| Task | Smallest executable unit | **One task = one worktree + one branch + one PR** |

`docs/tasks/` is the execution path from locked `next` anchors to accepted `current` behavior. At freeze/lock time it records Phase/Milestone planning only. It does not replace the product-shape source of truth in `docs/blueprint/next/`.

## Phase vs wave

Not every batch of work is a new Phase. Read `references/phase-vs-wave.md` for the rule: **does this scope need a dependency-ordered stage or later integration boundary?** Yes → new Phase. No → milestone wave inside an existing Phase. Ad-hoc issue → single task or task set under the relevant milestone.

## How to split Phases

Split by **dependency/progression boundary**, not by technical layer or quota:

- ❌ Wrong: Phase 1 schema / Phase 2 server / Phase 3 client (technical layers, no value)
- ✅ Right: Phase 1 identity prerequisites / Phase 2 collaboration loop / Phase 3 second-dimension integration (each Phase has a real progression boundary)

Do not create multiple Phases unless the dependency or integration boundary is real.

## Default Limits

| Limit | Stop-and-question rule |
|---|---|
| Major iteration has more than 3 Phases | Stop. Ask why there are so many Phases, whether the split dimension is correct, whether Phases can merge, or whether some work is only a Milestone/wave inside an existing Phase. |
| Phase has more than 3 Milestones | Stop. Ask why the work is split this way, whether the Milestone dimension is correct, whether Milestones can merge, or whether task-level detail is being misclassified as Milestone scope. |

These are defaults, not quotas. A major iteration may have fewer than 3 Phases, and a Phase may have fewer than 3 Milestones when the boundary is clear.

## Exit gate design

Every Phase needs **machine-checkable** + **user-perceivable** exit conditions:

| Gate type | What it checks | Example |
|---|---|---|
| **Strict** (machine) | Automated assertions | Cookie crosstalk test, throttle unit test, lint pass |
| **User-perceivable** (signoff) | Demo + PM ✅ + screenshot | Flagship milestone demo, real human can use it |
| **Carry-over** (partial OK) | Anchored to a future task path or placeholder PR # | Deferred work with a real recovery anchor (rule 6) |

## Four drift-prevention gates

Every Milestone should point toward these checks so later task execution can attach them before implementation:

| Gate | Owner | What it checks |
|---|---|---|
| 1. Template self-check | Architect | Spec brief uses the template correctly |
| 2. grep §X.Y anchor | Architect | Every task cites a blueprint section |
| 3. Reverse-check table | PM + Architect | Stances writable in one sentence; no drift |
| 4. Flagship signoff | PM | Demo + screenshot (AI teams skip video) |

Record only the milestone-level direction here. Task-level gates are attached when concrete tasks are created during execution.

## Deliverables

**Path**: `docs/tasks/`

- **README.md** — cross-Phase index + resume view (updated on every task PR merge)
- **phase-N-<name>/phase-plan.md** — staged progress boundary, milestone list, exit gates
- **phase-N-<name>/<milestone>/milestone.md** — `Readiness State: PLANNED`, capability goal, acceptance boundary, coarse dependencies, and readiness direction
- **phase-N-<name>/<milestone>/<task>/task.md** — not created by Phase/Milestone planning
- **phase-N-<name>/<milestone>/<task>/{spec,stance,acceptance,design,progress}.md** — created when that task starts

Freeze/lock example:

```text
docs/tasks/
├── README.md
└── phase-6-remote-agent/
    ├── phase-plan.md
    └── milestone-2-web-configure/
        └── milestone.md
```

PR boundary: in a PR-governed project, Phase/Milestone planning is a normal planning change with one worktree, one branch, and one PR when feasible. Its substantive deliverables are `phase-plan.md`, `milestone.md`, and `docs/tasks/README.md` index updates. It does not implement product behavior and does not create task folders.

## docs/tasks/README.md template

```markdown
# Tasks State

## Phase Index

| Phase | Status | Exit condition | Current milestone |
|-------|--------|----------------|-------------------|
| Phase 0 foundation | ARCHIVED | G0.x accepted | archived |
| Phase 6 remote agent | IMPLEMENTING | G6.x strict + PM signoff | milestone-2-web-config |
| Phase 7 next loop | PLANNED | G7.x defined after lock | waiting |
```

This Phase index records only Phase, Status, Exit condition, and Current milestone. A milestone closes only when all required tasks are accepted. A Phase closes only when its milestone gates pass.

## Anti-patterns

- ❌ Splitting by technical layer (no value loop)
- ❌ Exit gates without user perception (machine-only)
- ❌ Carry-over not anchored to a PR # (rule 6)
- ❌ Treating a milestone as the PR atom; task is the PR atom
- ❌ Creating task seeds, likely first tasks, task folders, task skeletons, or task contracts during Phase/Milestone planning
- ❌ Writing task mechanics into `docs/blueprint/current/` or `docs/blueprint/next/`
- ❌ Planning state not updated promptly

## How to invoke

```
follow skill bf-phase-plan
```
