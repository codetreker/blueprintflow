---
name: bf-milestone-breakdown
description: "Part of the Blueprintflow methodology. Use when a planned milestone is selected for execution and needs reviewed task skeletons before task work starts."
---

# Milestone Breakdown

Convert one selected user-facing milestone into reviewed task skeleton folders. Preserve milestone dependency order. Stop before task execution.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when all are true:

- The selected milestone exists in `docs/tasks/` and has not been broken into reviewed task contracts.
- Relevant `docs/blueprint/next` anchors are `LOCKED`.
- `phase-plan.md` and milestone-level `milestone.md` exist.
- A first task seed exists in `milestone.md` or `task-seed.md`.
- Dependencies are clear enough to start this milestone.

## Outputs

- `milestone.md`: task index, dependency order, parallelism, first ready task, review summary.
- `task-N-<name>/task.md`: one reviewed contract per skeleton folder.
- `docs/tasks/README.md`: breakdown/task resume state.
- `docs/blueprint/next/README.md`: milestone-level `Work` only.
- Boundary: no implementation, four-piece, design, or progress files.

## Steps

1. Prepare the breakdown location: PR-governed projects use the governed change workspace and create `task-0-breakdown-<milestone>`; non-PR-governed projects work in place.
2. In that location, set next ledger `Work` to `IMPLEMENTING`; keep `Milestone path` at the milestone folder. Do not publish yet.
3. Use [references/state-and-files.md](references/state-and-files.md) for planning task files and state meanings.
4. Use [references/task-contract.md](references/task-contract.md) to read inputs and write each `task.md`.
5. Update `milestone.md`: task index, dependency order, parallelism, first ready task, review table.
6. Run [references/review-checklist.md](references/review-checklist.md).
7. Complete the gate: PR-governed projects publish one change set containing task skeletons, review table, `milestone.md` first-ready update, and next-ledger `IMPLEMENTING` update; non-PR-governed projects record equivalent evidence in `milestone.md`.
8. Handoff: name the first ready task in `milestone.md`, then route to `bf-task-execute`. Do not start that task here.

## State Transition

```text
docs/tasks milestone state: PLANNED -> BREAKING_DOWN -> TASK_SET_READY
docs/blueprint/next Work during breakdown: PENDING -> IMPLEMENTING
```

## Required Review

- Run [references/review-checklist.md](references/review-checklist.md).
- Base reviewers: Architect, PM, QA, Dev.
- Add Security when the checklist marks any breakdown task sensitive. Code-task Security review remains mandatory under `bf-team-roles`.
- If review, publication, or evidence is incomplete: keep `BREAKING_DOWN`, fix `task.md` or `milestone.md`, and re-run review.
- Publish the reviewed task set only with the breakdown change set.

## Anti-patterns

- Creating implementation, four-piece, design, or task progress files during breakdown.
- Creating `progress.md` for `task-0-breakdown-*`; use `breakdown.md`.
- Treating skeleton folders as task worktrees or implementation PRs.
- Leaving task scope only in `milestone.md`; task details belong in each `task.md`.
- Skipping review because the first task seed looked obvious.
- Creating a task too large for one PR, or splitting by technical layer when value-slice tasks are possible.

## How to invoke

```
follow skill bf-milestone-breakdown
```
