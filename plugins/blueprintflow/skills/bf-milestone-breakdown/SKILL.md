---
name: bf-milestone-breakdown
description: "Part of the Blueprintflow methodology. Use when a planned milestone is selected for execution and needs readiness review before concrete task work starts."
---

# Milestone Breakdown

Review one selected Milestone for execution readiness. Stop before creating task folders, task skeletons, task contracts, or likely-first-task guesses.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when all are true:

- The selected milestone exists in `docs/tasks/` and has not passed readiness review for execution.
- Relevant `docs/blueprint/next` anchors are `LOCKED`.
- `phase-plan.md` and milestone-level `milestone.md` exist.
- The milestone needs readiness review before concrete task execution starts.

## Outputs

- `milestone.md`: readiness review, blocker owner when not ready, known dependency/conflict constraints, sensitivity/risk notes, and handoff direction.
- `docs/tasks/README.md`: milestone resume pointer when the project uses one.
- `docs/blueprint/next/README.md`: milestone-level `Work` only.
- Boundary: no task folders, task contracts, implementation, four-piece, design, or progress files.

## Steps

1. Prepare the readiness location: PR-governed projects use the governed change workspace; non-PR-governed projects work in place. Do not create a product task folder for readiness review.
2. If the milestone is actively entering execution, set next ledger `Work` to `IMPLEMENTING`; keep `Milestone path` at the milestone folder. Leave idle planned milestones as `PENDING`.
3. Use [references/state-and-files.md](references/state-and-files.md) for readiness files and ledger boundaries.
4. Read `phase-plan.md`, milestone-level `milestone.md`, and cited next-blueprint anchors.
5. Update `milestone.md` with readiness review: scope boundary, acceptance direction, real dependency/conflict constraints, sensitivity/risk notes, blockers, and handoff direction.
6. Run [references/review-checklist.md](references/review-checklist.md).
7. Complete the gate: readiness passes only when `milestone.md` has reviewer decisions, no unresolved blocker, and a handoff direction for `bf-task-execute`. PR-governed projects publish that readiness artifact in the next governed change; non-PR-governed projects record equivalent evidence in `milestone.md`.
8. Handoff: route to `bf-task-execute` with the milestone path and readiness review. The execution owner creates the concrete task from current context.

## State Boundary

This skill does not add a task-set state. It records a checkable readiness review on the selected Milestone and keeps coarse `docs/blueprint/next` `Work` at `PENDING` or `IMPLEMENTING`.

## Required Review

- Run [references/review-checklist.md](references/review-checklist.md).
- Base reviewers: Architect, PM, QA, Dev.
- Add Security when milestone scope, anchors, APIs, files, commands, or risks are sensitive.
- If review, publication, or evidence is incomplete: record the blocker owner in `milestone.md`, fix the readiness review, and re-run review.
- Publish the readiness review only with the readiness change set.

## Anti-patterns

- Creating task folders, task contracts, implementation, four-piece, design, or task progress files during readiness review.
- Inventing dependency order or parallelism plans before concrete task context exists.
- Naming a likely first task to make the milestone look executable.
- Treating readiness review as task execution.
- Skipping review because the milestone looks obvious.

## How to invoke

```
follow skill bf-milestone-breakdown
```
