---
name: bf-milestone-breakdown
description: "Part of the Blueprintflow methodology. Use when a planned milestone is selected for execution and needs readiness review before concrete task work starts."
---

# Milestone Breakdown

Review one selected milestone for execution readiness. Stop before task decomposition and task execution.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when all are true:

- The selected milestone exists in `docs/tasks/` and has not passed readiness review.
- Relevant `docs/blueprint/next` anchors are `LOCKED`.
- `phase-plan.md` and milestone-level `milestone.md` exist.
- Dependencies are clear enough to start this milestone.

## Outputs

- `milestone.md`: readiness state, readiness summary, boundary checks, coarse dependencies, review table, and handoff direction.
- `docs/tasks/README.md`: milestone-level resume state when the project uses it.
- `docs/blueprint/next/README.md`: milestone-level `Work` only.
- Boundary: no task folders, task skeletons, task contracts, implementation, four-piece, design, or task progress files.

## Steps

1. Prepare the readiness location: PR-governed projects use one governed change workspace for the milestone readiness update; non-PR-governed projects work in place.
2. In that location, set next ledger `Work` to `IMPLEMENTING` only if readiness work is active; keep `Milestone path` at the milestone folder. Do not publish yet.
3. Use [references/state-and-files.md](references/state-and-files.md) for readiness files and ledger meanings.
4. Update `milestone.md`: set `Readiness State`, capability boundary, acceptance direction, coarse dependencies, known blockers, review table, and handoff direction.
5. Run [references/review-checklist.md](references/review-checklist.md).
6. Complete the gate: PR-governed projects publish one change set containing the readiness summary, review table, and any next-ledger `IMPLEMENTING` update; non-PR-governed projects record equivalent evidence in `milestone.md`.
7. Handoff: route to `bf-task-execute` with the milestone path and readiness summary. Do not guess the first task here.

## State Transition

```text
docs/tasks milestone readiness in milestone.md: PLANNED -> READINESS_REVIEW -> READY_FOR_EXECUTION
docs/blueprint/next Work during readiness review: PENDING -> IMPLEMENTING
```

## Required Review

- Run [references/review-checklist.md](references/review-checklist.md).
- Base reviewers: Architect, PM, QA, Dev.
- Add Security when the milestone touches auth, privacy, credentials, dangerous commands, remote agents, admin paths, or project-defined sensitive areas.
- If review, publication, or evidence is incomplete: keep readiness in review, fix `milestone.md`, and re-run review.
- Publish the readiness result only with the readiness change set.

## Anti-patterns

- Creating task folders, `task-N/task.md`, a full task index, dependency order, parallelism plan, first ready task, or first task guess during readiness review.
- Creating implementation, four-piece, design, or task progress files during breakdown.
- Treating milestone readiness as task execution.
- Blocking on wording nits or implementation-level details that belong in task execution and Dev design.
- Serializing future tasks by habit before real task context exists.
- Treating a Milestone as a PR atom; task PRs are still created during execution.

## How to invoke

```
follow skill bf-milestone-breakdown
```
