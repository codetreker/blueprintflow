# Files and Ledgers

## State Placement

| State | File | Required content |
|---|---|---|
| Blueprint decision | `docs/blueprint/next/README.md` | Anchor, decision status, execution status, milestone path |
| Phase resume | `docs/tasks/README.md` | Phase, status, exit condition, current milestone |
| Active task resume | `docs/tasks/README.md` | Scope, execution, active task, owner, worktree/branch, PR, blocker, progress path |
| Milestone resume | `docs/tasks/<phase>/<milestone>/milestone.md` | Task index, dependency order, first ready task, blocked tasks, closure state |
| Task contract | `docs/tasks/<phase>/<milestone>/<task>/task.md` | Scope, anchors, out-of-scope, acceptance slice, dependencies, sensitive paths |
| Task progress | `docs/tasks/<phase>/<milestone>/<task>/progress.md` | Worktree/branch, PR, checkpoints, blockers, acceptance, current sync |

## `docs/blueprint/next/README.md`

Keep this ledger at milestone level.

```markdown
| Anchor | Decision | Execution | Milestone path | Notes |
|---|---|---|---|---|
| remote-agent §2 | LOCKED | TASK_SET_READY | docs/tasks/phase-6-remote-agent/milestone-2-web-config | first task named in milestone.md |
```

Do not add task paths, task owners, worktrees, branches, PRs, blockers, or checkbox progress.

## `docs/tasks/README.md`

Use two tables.

```markdown
## Phase Index

| Phase | Status | Exit condition | Current milestone |
|---|---|---|---|
| phase-6-remote-agent | IMPLEMENTING | G6 strict + PM signoff | milestone-2-web-config |

## Active Task Resume

| Scope | Execution | Active task | Owner | Worktree/branch | PR | Blocker | Progress |
|---|---|---|---|---|---|---|---|
| phase-6/milestone-2 | IMPLEMENTING | task-1-configure-job-api | Dev | .worktrees/task-1-configure-job-api / feat/task-1-configure-job-api | #820 | none | docs/tasks/phase-6/milestone-2/task-1-configure-job-api/progress.md |
```

Remove Active Task Resume rows only after `bf-milestone-progress` reconciles accepted-task state. Keep closed state in the task folder and milestone summary.

## `milestone.md`

Required sections:

```markdown
# <Milestone Name>

## Goal

## Task Index

| Task | Status | Depends on | PR | Notes |
|---|---|---|---|---|

## Dependency Order

## First Ready Task

## Blockers

## Closure Summary
```

Statuses: `PLANNED`, `READY`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, `ACCEPTING`, `ACCEPTED`, `DEFERRED`, `BLOCKED`.

## `progress.md`

Create when a task starts.

```markdown
# Progress

## Resume

| Field | Value |
|---|---|
| Worktree | .worktrees/<task> |
| Branch | feat/<task> |
| PR | #N or pending |
| Owner | <role/name> |
| State | TASKING / READY_FOR_IMPL / IMPLEMENTING / ACCEPTING / ACCEPTED |
| Blocker | none or concrete blocker |

## Checkpoints

- [ ] Worktree created
- [ ] Four-piece baseline complete
- [ ] Implementation design reviewed
- [ ] Implementation complete
- [ ] docs/current sync checked or N/A recorded
- [ ] Acceptance passed
- [ ] PR merged
```

## Consistency Rules

- `TASK_SET_READY` in next ledger requires reviewed `task.md` files and a first ready task in `milestone.md`.
- `TASKING` requires an Active Task Resume row and a task folder.
- `READY_FOR_IMPL` requires four-piece baseline and reviewed `design.md` for code tasks.
- `IMPLEMENTING` requires worktree/branch state in Active Task Resume or `progress.md`.
- `ACCEPTED` requires merged task PR, acceptance evidence, and milestone update.
- `CURRENT` requires accepted scope reflected in `docs/blueprint/current/`.
