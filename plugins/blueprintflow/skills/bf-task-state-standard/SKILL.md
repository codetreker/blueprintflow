---
name: bf-task-state-standard
description: "Part of the Blueprintflow methodology. Use when creating, repairing, or reviewing docs/tasks state, resume ledgers, milestone indexes, task folders, or task progress records."
---

# Task State Standard

Own the `docs/tasks/` state contract. Do not plan, break down, implement, review, or merge task work in this skill.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when any are true:

- `docs/tasks/README.md` needs creation, repair, or review.
- `milestone.md`, `task.md`, `progress.md`, or task folder placement is unclear.
- Active task resume state conflicts with `docs/blueprint/next/README.md`.
- An interrupted session needs file-based recovery before dispatch.

## Ownership

| File | Owns | Must not own |
|---|---|---|
| `docs/tasks/README.md` | Phase index, milestone-level resume, active task resume | Full task details, PR review evidence |
| `docs/tasks/<phase>/phase-plan.md` | Dependency stage, milestones, exit gates | Task skeleton details |
| `docs/tasks/<phase>/<milestone>/milestone.md` | Milestone task index, dependency order, first ready task, closure summary | Full four-piece content |
| `docs/tasks/<phase>/<milestone>/<task>/task.md` | Reviewed task contract | Implementation design or progress |
| `docs/tasks/<phase>/<milestone>/<task>/progress.md` | Task checkpoints, blockers, PR, acceptance state | Blueprint product truth |

## Steps

1. Read `docs/blueprint/next/README.md` for the milestone ledger.
2. Read `docs/tasks/README.md` if it exists.
3. Read the relevant `phase-plan.md`, `milestone.md`, `task.md`, and `progress.md` only as needed.
4. Apply [references/files-and-ledgers.md](references/files-and-ledgers.md).
5. Fix the smallest state surface that restores recovery.
6. Report the next owning skill: `bf-phase-plan`, `bf-milestone-breakdown`, `bf-task-execute`, `bf-milestone-progress`, or `bf-phase-exit-gate`.

## Checks

- `docs/blueprint/next/README.md` stops at milestone level and uses only `PENDING`, `IMPLEMENTING`, or `COMPLETED` for work state.
- One active task row maps to one task folder, one worktree, one branch, and one PR.
- Accepted task facts do not move to `docs/blueprint/current/` until acceptance and promotion happen.
- Archived folders are not edited.

## Anti-patterns

- Writing task implementation state into `docs/blueprint/next/README.md`.
- Treating `docs/tasks/README.md` as a duplicate of every task file.
- Keeping closed task rows in Active Task Resume.
- Repairing state by changing archived files.
- Using memory or chat history as the source of truth when task files disagree.

## How to invoke

```
follow skill bf-task-state-standard
```
