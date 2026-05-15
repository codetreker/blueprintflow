---
name: bf-phase-plan
description: "Part of the Blueprintflow methodology. Use when locked next-blueprint anchors need Phase/Milestone planning, dependency boundaries, and Phase exit gates before milestone readiness review."
---

# Phase Plan

Once `docs/blueprint/next/` has `LOCKED` anchors, the Architect leads. Plan staged progress inside the major iteration: Phases for real prerequisite or integration boundaries, and Milestones for user-facing deliverables inside each Phase. Stop before task seeds, task folders, task skeletons, or task contracts.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Preflight check

Before using this skill, read `references/preflight.md` to confirm it applies. The decision graph checks: single-file change? mechanical PR type? blueprint missing? If any skip condition applies, skip this planning flow.

## Phase / Milestone / Task

| Level | Meaning | PR ownership |
|---|---|---|
| Phase | Dependency-ordered stage inside a major iteration, with later integration or exit boundary | Not a PR by itself |
| Milestone | User-facing capability or deliverable inside a Phase | Groups tasks; not a PR by itself |
| Task | Smallest executable unit | **One task = one worktree + one branch + one PR** |

`docs/tasks/` is the execution path from locked `next` anchors to accepted `current` behavior. At freeze/lock time it records only Phase/Milestone planning: boundaries, acceptance direction, coarse dependencies, and exit-gate direction. Concrete task creation belongs to execution from current milestone context. It does not replace the product-shape source of truth in `docs/blueprint/next/`.

## Phase vs Milestone

Not every batch of work is a new Phase. Read `references/phase-vs-wave.md` for the rule: **does the work need a separate dependency/integration stage?** Yes -> new Phase. No -> Milestone inside an existing Phase. Ad-hoc issue -> task work under the relevant Milestone.

## How to split Phases

Split by **prerequisite dependency or integration boundary**, not by technical layer or quota:

- ❌ Wrong: Phase 1 schema / Phase 2 server / Phase 3 client (technical layers, no value)
- ✅ Right: Phase 1 foundation needed by later work / Phase 2 collaboration loop / Phase 3 second-dimension integration (each Phase has a real dependency or integration reason)

> **Real example (Borgee):** Phase 0 foundation → Phase 1 identity loop → Phase 2 collaboration loop ⭐ → Phase 3 second dimension → Phase 4+ remaining

Default limits:

- Use no more than 3 Phases for one major iteration unless the user approves a stop-and-question exception.
- Use no more than 3 Milestones inside one Phase unless the user approves a stop-and-question exception.
- If a plan wants more, stop and ask whether the split dimension is wrong, whether Phases or Milestones can merge, or whether task-level detail is being misclassified as Milestone scope.
- Task count is not capped, but this skill must not pre-split task count during Phase/Milestone planning.

## Exit gate design

Every Phase needs **machine-checkable** + **user-perceivable** exit conditions:

| Gate type | What it checks | Example |
|---|---|---|
| **Strict** (machine) | Automated assertions | Cookie crosstalk test, throttle unit test, lint pass |
| **User-perceivable** (signoff) | Demo + PM ✅ + screenshot | Flagship milestone demo, real human can use it |
| **Carry-over** (partial OK) | Anchored to a future task path or placeholder PR # | Deferred work with a real recovery anchor (rule 6) |

## Future Task Drift-Prevention Gates

Record these as future task gates only. Do not create task spec briefs, stance files, acceptance files, or task folders during Phase planning.

Every task must have these attached before implementation:

| Gate | Owner | What it checks |
|---|---|---|
| 1. Template self-check | Architect | Spec brief uses the template correctly |
| 2. grep §X.Y anchor | Architect | Every task cites a blueprint section |
| 3. Reverse-check table | PM + Architect | Stances writable in one sentence; no drift |
| 4. Flagship signoff | PM | Demo + screenshot (AI teams skip video) |

Gates 1+2 are checked when `bf-task-execute` creates the concrete task and `bf-task-fourpiece` creates the task spec brief. Gate 3 belongs in task stance + acceptance. Gate 4 belongs at demo signoff.

## Deliverables

**Path**: `docs/tasks/`

- **README.md** — cross-Phase index + resume view (updated on every task PR merge)
- **phase-N-<name>/phase-plan.md** — dependency/integration boundary, milestone list, exit gates
- **phase-N-<name>/<milestone>/milestone.md** — capability goal, acceptance direction, boundaries, coarse dependencies, known risks, and readiness questions
- **phase-N-<name>/<milestone>/<task>/task.md** — not created by freeze/lock planning
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

PR boundary: in a PR-governed project, freeze/lock planning is a normal planning task such as `task-0-plan-phase-6`: one worktree, one branch, one PR. Its substantive deliverables are parent `phase-plan.md` and Milestone `milestone.md` files. It is not a container PR exception and it does not implement product behavior.

The freeze/lock planning task stops at Phase/Milestone plan files. Do not fabricate task seeds, task skeleton folders, likely first tasks, dependency order, or parallelism plans to make the plan look finished. When the milestone is selected for execution, run `bf-milestone-breakdown` to review milestone readiness before concrete task execution starts.

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

- ❌ Splitting by technical layer instead of dependency/integration boundary
- ❌ Creating extra Phases just to balance scope or satisfy a quota
- ❌ Turning task-level detail into Milestones during Phase planning
- ❌ Writing task seed, likely first task, task folder, task skeleton, or task contract during Phase planning
- ❌ Exit gates without user perception (machine-only)
- ❌ Carry-over not anchored to a PR # (rule 6)
- ❌ Treating a milestone as the PR atom; task is the PR atom
- ❌ Writing task mechanics into `docs/blueprint/current/` or `docs/blueprint/next/`
- ❌ PROGRESS not updated promptly

## How to invoke

```
follow skill bf-phase-plan
```
