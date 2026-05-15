---
name: bf-phase-plan
description: "Part of the Blueprintflow methodology. Use when locked next-blueprint anchors need Phase/Milestone planning and Phase exit gates before milestone breakdown."
---

# Phase Plan

Once `docs/blueprint/next/` has `LOCKED` anchors, the Architect leads. Break the selected next work into dependency-ordered Phases and user-facing Milestones. Complete task decomposition waits for `bf-milestone-breakdown`. Create multiple Phases only when a later stage cannot start or be accepted until an earlier Phase exit gate passes; a Phase still closes on demonstrable user value, not technical layers.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Preflight check

Before using this skill, read `references/preflight.md` to confirm it applies. The decision graph checks: single-file change? mechanical PR type? blueprint missing? If any skip condition applies, skip this planning flow.

## Phase / Milestone / Task

| Level | Meaning | PR ownership |
|---|---|---|
| Phase | Dependency-ordered stage inside a major iteration; exists when later work depends on earlier Phase exit gates | Not a PR by itself |
| Milestone | User-facing capability or deliverable group inside a Phase | Groups tasks; not a PR by itself |
| Task | Work needed inside a Milestone to complete that Milestone | **One task = one worktree + one branch + one PR** |

Default sizing:

- Major iteration: at most 3 Phases. More than 3 is a stop-and-question signal; resume only after the Architect records the accepted exception rationale in `phase-plan.md`.
- Phase: at most 3 user-facing Milestones. More than 3 is a stop-and-question signal; resume only after the Architect records the accepted exception rationale in `phase-plan.md`.
- Task count is not capped during Phase/Milestone planning. Do not pre-split tasks to satisfy a count.

`docs/tasks/` is the execution path from locked `next` anchors to accepted `current` behavior. At freeze/lock time it records Phase/Milestone planning; `bf-milestone-breakdown` later creates reviewed task skeleton folders; each concrete task gains four-piece/design files only when that task starts. It does not replace the product-shape source of truth in `docs/blueprint/next/`.

## Phase vs wave

Create a new Phase only when later work cannot start or be accepted until an earlier Phase exit gate passes.

Keep work inside the current Phase when it adds user-facing capability but does not create that dependency. Use a Milestone or milestone wave inside the existing Phase; route ad-hoc issues to a task or task set under the relevant milestone.

Read `references/phase-vs-wave.md` for the detailed decision table.

## How to split Phases

Split by **prerequisite sequence and acceptance dependency**, not by technical layer:

- ❌ Wrong: Phase 1 schema / Phase 2 server / Phase 3 client (technical layers, no value)
- ✅ Right: Phase 1 single-user workspace (exit: one user completes the workflow) / Phase 2 shared workspace (exit: two users complete the workflow together) / Phase 3 organization rollout (exit: admin-managed workspace passes acceptance)

Stop before publishing when the plan needs a fourth Phase. Ask: why so many Phases, is the split dimension correct, can Phases merge, or should some work be a Milestone/wave inside an existing Phase? Resume only after `phase-plan.md` records the accepted exception rationale, merge/split decision, and owner.

Stop before publishing when one Phase needs a fourth Milestone. Ask: why split this way, is the Milestone dimension correct, can Milestones merge, or is task-level detail being misclassified as Milestone scope? Resume only after `phase-plan.md` records the accepted exception rationale, merge/split decision, and owner.

## Exit gate design

Every Phase needs **machine-checkable** + **user-perceivable** exit conditions:

| Gate type | What it checks | Example |
|---|---|---|
| **Strict** (machine) | Automated assertions | Cookie crosstalk test, throttle unit test, lint pass |
| **User-perceivable** (signoff) | Demo + PM ✅ + screenshot | Flagship milestone demo, real human can use it |
| **Carry-over** (partial OK) | Anchored to a future task path or placeholder PR # | Deferred work with a real recovery anchor (rule 6) |

## Four drift-prevention gates

Every task must have these attached before implementation:

| Gate | Owner | What it checks |
|---|---|---|
| 1. Template self-check | Architect | Spec brief uses the template correctly |
| 2. grep §X.Y anchor | Architect | Every task cites a blueprint section |
| 3. Reverse-check table | PM + Architect | Stances writable in one sentence; no drift |
| 4. Flagship signoff | PM | Demo + screenshot (AI teams skip video) |

Gates 1+2 in the task spec brief, gate 3 in stance + acceptance, gate 4 at demo signoff.

## Deliverables

**Path**: `docs/tasks/`

- **README.md** — cross-Phase index + resume view (updated on every task PR merge)
- **phase-N-<name>/phase-plan.md** — dependency stage, milestone list, exit gates
- **phase-N-<name>/<milestone>/milestone.md** — capability goal, acceptance boundary, and dependencies
- **phase-N-<name>/<milestone>/<task>/task.md** — created later by `bf-milestone-breakdown`, not by freeze/lock planning
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

PR boundary: in a PR-governed project, freeze/lock planning is a normal planning task such as `task-0-plan-phase-6`: one worktree, one branch, one PR. It has a real planning task folder for PR ownership/progress, for example `docs/tasks/phase-6-remote-agent/milestone-planning/task-0-plan-phase-6/progress.md`. The planning task's substantive deliverables are parent `phase-plan.md` and `milestone.md` files; it is not a container PR exception and it does not implement product behavior.

The freeze/lock planning task stops at `phase-plan.md` and `milestone.md`. Do not fabricate task skeleton folders just to make the plan look finished. When the milestone is selected for execution, run `bf-milestone-breakdown` to create reviewed task folders with `task.md`; create four-piece/design/progress files only when each task starts.

After `bf-milestone-breakdown`:

```text
docs/tasks/phase-6-remote-agent/milestone-2-web-configure/
├── milestone.md          # index, dependencies, breakdown review
├── task-1-configure-job-api/
│   └── task.md           # task contract only
└── task-2-helper-runner/
    └── task.md
```

Task start adds the four-piece/design/progress files to that task folder.

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

- ❌ Splitting by technical layer (no user-perceivable value)
- ❌ Exit gates without user perception (machine-only)
- ❌ Carry-over not anchored to a PR # (rule 6)
- ❌ Treating a milestone as the PR atom; task is the PR atom
- ❌ Writing task mechanics into `docs/blueprint/current/` or `docs/blueprint/next/`
- ❌ PROGRESS not updated promptly

## How to invoke

```
follow skill bf-phase-plan
```
