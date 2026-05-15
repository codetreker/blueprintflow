---
name: bf-milestone-breakdown
description: "Part of the Blueprintflow methodology. Use when a planned milestone is selected for execution and needs reviewed task.md boundaries before task work starts."
---

# Milestone Breakdown

Turn one selected milestone into reviewed task folders with boundary-level `task.md` files. Stop before task execution, four-piece creation, implementation design, and progress tracking.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when all are true:

- The selected milestone exists in `docs/tasks/` and reviewed task boundaries are not published.
- Relevant `docs/blueprint/next` anchors are `LOCKED`.
- `phase-plan.md` and milestone-level `milestone.md` exist.
- The milestone is selected for execution and task boundaries have not been reviewed.

## Outputs

- `milestone.md`: task index, dependency order, first ready task, review summary, publication evidence.
- `task-N-<name>/task.md`: one reviewed boundary contract per task folder.
- `docs/blueprint/next/README.md`: milestone-level `Work` only.
- Boundary: no `task-0-breakdown-*`, implementation, four-piece, design, or progress files.

## Ownership

- Architect owns task boundary content, `task.md` creation, and `milestone.md` task index updates.
- Reviewers own LGTM/NOT_LGTM decisions for their lenses.
- Teamlead owns governed change publication, next-ledger update, and handoff routing.

## Steps

1. Prepare the breakdown change location: PR-governed projects use the governed change workspace; non-PR-governed projects work in place. Do not create `task-0-breakdown-*` or a seed planning task.
2. In that location, set next ledger `Work` to `IMPLEMENTING`; keep `Milestone path` at the milestone folder. Do not publish yet.
3. Use [references/state-and-files.md](references/state-and-files.md) for breakdown state and file boundaries.
4. Use [references/task-contract.md](references/task-contract.md) to read inputs and write each boundary-level `task.md`.
5. Update `milestone.md`: task index, dependency order, first ready task, review table, publication evidence.
6. Run [references/review-checklist.md](references/review-checklist.md).
7. Stop before publication if no unblocked first task exists; record the blocker owner and action in `milestone.md`, keep the milestone `PLANNED`, and route to the blocker owner or `bf-phase-plan` for replanning.
8. Complete the gate: PR-governed projects publish one change set containing the reviewed task folders, `milestone.md` update, and next-ledger `IMPLEMENTING` update; non-PR-governed projects record equivalent evidence in `milestone.md`.
9. Handoff: name the first ready task in `milestone.md`, then route to `bf-task-execute`. Do not start that task here.

## State Transition

```text
docs/tasks milestone state: PLANNED -> TASK_SET_READY
docs/blueprint/next Work during breakdown: PENDING -> IMPLEMENTING
```

## Required Review

- Run [references/review-checklist.md](references/review-checklist.md).
- Base reviewers: Architect, PM, QA, Dev.
- Add Security when the checklist marks any task sensitive.
- If review, publication, or evidence is incomplete: keep the milestone `PLANNED`, fix `task.md` or `milestone.md`, and re-run review.
- Publish the reviewed task set only with the breakdown change set.

## Anti-patterns

- Creating implementation, four-piece, design, or task progress files during breakdown.
- Creating `task-0-breakdown-*` or a seed task to host planning work.
- Leaving task scope only in `milestone.md`; task boundaries belong in each `task.md`.
- Skipping review because the next task looked obvious.
- Treating boundary-level `task.md` as implementation design.

## How to invoke

```
follow skill bf-milestone-breakdown
```
