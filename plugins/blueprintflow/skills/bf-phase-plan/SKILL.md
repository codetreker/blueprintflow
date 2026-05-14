---
name: bf-phase-plan
description: "Part of the Blueprintflow methodology. Use when locked next-blueprint anchors need Phase/Milestone planning, value-loop gates, or first task seed before milestone breakdown."
---

# Phase Plan

Use this skill only after `docs/blueprint/next/` has `LOCKED` anchors. Architect leads. Create dependency-ordered Phases, user-facing Milestones, and the first-milestone task seed. Do not decompose all tasks here; route task contracts to `bf-milestone-breakdown`. Anchor each Phase to a user value loop, not to a technical layer.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Preflight check

Before using this skill, read `references/preflight.md` to confirm it applies. The decision graph checks: single-file change? mechanical PR type? blueprint missing? If any skip condition applies, skip this planning flow.

Before planning, require recorded `bf-blueprint-iteration` Next lock integrity gate evidence in `docs/blueprint/_meta/<target-version>/next-lock-integrity.md`. Treat evidence as stale if selected anchors, README rows, detail anchors, blockers/open anchors, source issue/note trace, milestone paths, `phase-plan.md`, or `milestone.md` changed after the recorded gate result. If evidence is missing, stale, or failed, STOP and route back to `bf-blueprint-iteration`. Do not create or continue a Phase plan from README ledger status alone.

## Phase / Milestone / Task

| Level | Meaning | PR ownership |
|---|---|---|
| Phase | Plan a dependency-ordered stage inside one major iteration. Anchor it to one value loop and exit gates. | Not a PR by itself |
| Milestone | Plan a user-facing deliverable inside a Phase. Record acceptance boundary, dependency order, and first-ready task selection. | Groups tasks; not a PR by itself |
| Task | Execute one milestone acceptance slice. | **One task = one worktree + one branch + one PR** |

`docs/tasks/` is the execution path from locked `next` anchors to accepted `current` behavior. At freeze/lock time it records Phase/Milestone planning; `bf-milestone-breakdown` later creates reviewed task skeleton folders; each concrete task gains four-piece/design files only when that task starts. It does not replace the product-shape source of truth in `docs/blueprint/next/`.

Use the default size: <=3 Phases per major iteration and <=3 milestones per Phase. If scope exceeds that, record the exception in `phase-plan.md`: dependency reason, extra Phase/milestone count, and why a milestone wave would not fit.

## Phase vs wave

Before adding a Phase, read `references/phase-vs-wave.md`. Ask: did locked next scope introduce a new value loop? Yes -> create a Phase. No -> create a milestone wave inside the existing Phase. Ad-hoc issue -> create a task or task set under the relevant milestone.

## How to split Phases

Split by **value loop**, not by technical layer:

- ❌ Wrong: Phase 1 schema / Phase 2 server / Phase 3 client (technical layers, no value)
- ✅ Right: Phase 1 identity loop / Phase 2 collaboration loop / Phase 3 second-dimension product / Phase 4+ remaining (each Phase independently demonstrable)

> **Large-roadmap exception (Borgee):** Phase 0 foundation -> Phase 1 identity loop -> Phase 2 collaboration loop -> Phase 3 second dimension -> Phase 4+ remaining. Do not use this as the default shape for one major iteration.

Preserve dependency order. Phase N+1 should not start until Phase N exit gates pass, unless `phase-plan.md` records a carry-over gate or waiver. Milestones should likewise stay ordered unless `milestone.md` records safe parallelism.

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
- **phase-N-<name>/phase-plan.md** — value loop, milestone list, exit gates
- **phase-N-<name>/<milestone>/milestone.md** — capability goal, acceptance boundary, dependencies, task-split trigger, and first task seed when this is the first executable milestone
- **phase-N-<name>/<milestone>/<task>/task.md** — created later by `bf-milestone-breakdown`, not by freeze/lock planning
- **phase-N-<name>/<milestone>/<task>/{spec,stance,acceptance,design,progress}.md** — created when that task starts

Freeze/lock example:

```text
docs/tasks/
├── README.md
└── phase-6-remote-agent/
    ├── phase-plan.md
    └── milestone-2-web-configure/
        ├── milestone.md
        └── task-seed.md        # optional file; seed may also be in milestone.md
```

The first-milestone task seed may be a section in `milestone.md` or a small `task-seed.md`. It names the likely first task, cited next-blueprint anchors, prerequisites, expected PR atom, and first acceptance check. It is not a four-piece set and does not start implementation.

PR boundary: in a PR-governed project, freeze/lock planning is a normal planning task such as `task-0-plan-phase-6`: one worktree, one branch, one PR. It has a real planning task folder for PR ownership/progress, for example `docs/tasks/phase-6-remote-agent/milestone-planning/task-0-plan-phase-6/progress.md`. The planning task's substantive deliverables are parent `phase-plan.md`, `milestone.md`, and task seed files; it is not a container PR exception and it does not implement product behavior.

The freeze/lock planning task may stop at `phase-plan.md`, `milestone.md`, and the first-milestone task seed. Do not fabricate task skeleton folders just to make the plan look finished. When the milestone is selected for execution, run `bf-milestone-breakdown` to create reviewed task folders with `task.md`; create four-piece/design/progress files only when each task starts.

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

- ❌ Splitting by technical layer (no value loop)
- ❌ Exit gates without user perception (machine-only)
- ❌ Carry-over not anchored to a PR # (rule 6)
- ❌ Treating a milestone as the PR atom; task is the PR atom
- ❌ Writing task mechanics into `docs/blueprint/current/` or `docs/blueprint/next/`
- ❌ PROGRESS not updated promptly

## How to invoke

```
follow skill bf-phase-plan
```
