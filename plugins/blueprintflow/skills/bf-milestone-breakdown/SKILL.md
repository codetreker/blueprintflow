---
name: bf-milestone-breakdown
description: "Part of the Blueprintflow methodology. Use when a planned milestone is selected for execution and needs reviewed task skeletons before task work starts."
---

# Milestone Breakdown

Turn one selected milestone into reviewed task skeleton folders. Do not start implementation.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when all are true:

- The milestone is `MILESTONE_PLANNED`.
- Relevant `docs/blueprint/next` anchors are `LOCKED`.
- `phase-plan.md` and milestone-level `milestone.md` exist.
- A first task seed exists in `milestone.md` or `task-seed.md`.
- Dependencies are clear enough to start this milestone.

## Outputs

- `milestone.md` updated as the milestone index: task list, dependency order, first ready task, review summary.
- One skeleton folder per task under `docs/tasks/<phase>/<milestone>/task-N-<name>/`.
- One `task.md` contract in every task skeleton folder.
- `docs/tasks/README.md` and `docs/blueprint/next/README.md` updated with the new resume state.

Do not create `spec.md`, `stance.md`, `acceptance.md`, `design.md`, or `progress.md`. Those start in `bf-milestone-fourpiece` after a concrete task enters `bf-git-workflow`.

## Steps

1. Start the breakdown in the right workspace.

| Project mode | Action |
|---|---|
| PR-governed | Create a real planning task folder such as `task-0-breakdown-<milestone>` plus its worktree and branch for breakdown ownership; do not open the PR yet. In that worktree, mark the selected milestone `BREAKING_DOWN` in the next ledger. |
| Non-PR-governed | Mark the selected milestone `BREAKING_DOWN` in the next ledger in place. |

2. See [references/state-and-files.md](references/state-and-files.md) for the planning task file shape.
3. Read the milestone inputs listed in [references/task-contract.md](references/task-contract.md).
4. Create task skeleton folders and `task.md` contracts using [references/task-contract.md](references/task-contract.md).
5. Update `milestone.md` with the task index, dependency order, parallelism notes, first ready task, and review table.
6. Run the breakdown review gate using [references/review-checklist.md](references/review-checklist.md).
7. Complete the breakdown gate. In PR-governed projects, commit the task skeletons, review table, and final ledger update to `TASK_SET_READY`; then open the breakdown PR, collect required reviews, pass CI, and merge it. In non-PR-governed projects, record equivalent review evidence in `milestone.md` and mark `TASK_SET_READY` in the same update.
8. After `TASK_SET_READY` is published, dispatch the first ready task to `bf-git-workflow` + `bf-milestone-fourpiece`.

## State Transition

```text
MILESTONE_PLANNED -> BREAKING_DOWN -> TASK_SET_READY -> TASKING
```

See [references/state-and-files.md](references/state-and-files.md) for status meanings and file examples.

## Required Review

Architect, PM, QA, and Dev must approve every breakdown. They must classify sensitive paths from task scope, anchors, dependencies, APIs, files, and commands; do not rely only on the task author's `Sensitive paths` value. Security is required when any task touches auth, privacy, credentials, dangerous commands, remote agents, admin paths, or project-defined sensitive areas.

Any rejection, red CI, unmerged required breakdown PR, or missing non-PR review evidence keeps the milestone in `BREAKING_DOWN`. Fix `task.md` or `milestone.md`, then re-review. Do not use a follow-up PR or direct commit to publish `TASK_SET_READY`; it belongs in the breakdown PR before merge.

## Anti-patterns

- Creating four-piece files during breakdown.
- Creating `progress.md` for `task-0-breakdown-*`; use `breakdown.md` for the planning task record.
- Treating skeleton task folders as task worktrees or open implementation PRs.
- Leaving task scope only in `milestone.md`; task details belong in each `task.md`.
- Skipping review because the first task seed looked obvious.
- Creating a task too large for one PR.
- Splitting by technical layer when value-slice tasks are possible.

## How to invoke

```
follow skill bf-milestone-breakdown
```
