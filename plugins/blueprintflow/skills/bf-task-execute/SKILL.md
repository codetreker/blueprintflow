---
name: bf-task-execute
description: "Part of the Blueprintflow methodology. Use when a reviewed task is ready to start or resume, or when task work must advance toward acceptance."
---

# Task Execute

Orchestrate one concrete task from ready task contract to accepted task closure. Keep the task as one worktree, one branch, and one PR.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when all are true:

- `docs/tasks/<phase>/<milestone>/<task>/task.md` exists.
- `milestone.md` marks the task `READY`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, or `ACCEPTING`.
- The task is unblocked by dependency order.
- Concrete task work or resume is needed.

## Outputs

| Output | Owner skill |
|---|---|
| Worktree, branch, PR lifecycle, Active Task Resume creation/update | `bf-git-workflow` |
| `spec.md`, `stance.md`, `acceptance.md`, optional `content-lock.md` | `bf-task-fourpiece` |
| `design.md` and four-role design review for code tasks | `bf-implementation-design` |
| Code/docs changes, tests, current-doc sync | Assigned role coordinators and helpers |
| Implementation loop and local test evidence | [references/implementation-loop.md](references/implementation-loop.md) |
| PR review and merge gate | `bf-pr-review-flow` |
| Coarse active work state in the milestone-level next ledger | `bf-task-execute` |
| Accepted-task cleanup, Active Task Resume removal, milestone next-task, closure, and next-ledger decision | `bf-milestone-progress` |

## Steps

1. Run `bf-task-state-standard` if resume state is missing or inconsistent.
2. Read `task.md`, `milestone.md`, `docs/tasks/README.md`, and the cited next-blueprint anchors.
3. Start or resume the worktree using `bf-git-workflow`.
4. Set the milestone-level next ledger `Work` to `IMPLEMENTING`; keep `Milestone path` pointed at the milestone folder. Put active task recovery only in `docs/tasks/README.md`, `milestone.md`, and the task folder.
5. Create or repair task baseline docs using `bf-task-fourpiece`.
6. For code tasks, run `bf-implementation-design` and require four-role design review before coding; record `READY_FOR_IMPL` only in `docs/tasks`.
7. Dispatch implementation work through the owning role coordinator using [references/implementation-loop.md](references/implementation-loop.md); Teamlead does not implement. Record task implementation state only in `docs/tasks`.
8. Check `docs/current` impact with `bf-current-doc-standard` when the project uses current docs.
9. Run `bf-verification` for the task surfaces. Required acceptance evidence must be complete before PR open; review may re-run or add evidence, not fill missing required evidence.
10. Open the task PR through `bf-git-workflow`; review and merge-gate it through `bf-pr-review-flow`. When the task enters review/acceptance, record `ACCEPTING` only in `docs/tasks`.
11. After merge and acceptance evidence, hand off to `bf-milestone-progress` for accepted-task recording, Active Task Resume cleanup, next task selection, milestone closure, or Phase exit readiness.

Do not mark the task `ACCEPTED`, set next ledger `Work` to `COMPLETED`, remove Active Task Resume, or promote current in this skill. Those are milestone-level follow-up decisions owned by `bf-milestone-progress` and `bf-blueprint-iteration`.

## State Transitions

```text
READY -> TASKING -> READY_FOR_IMPL -> IMPLEMENTING -> ACCEPTING -> ACCEPTED
```

Skip `READY_FOR_IMPL` only for non-code tasks with an explicit N/A in `progress.md`.

## Checks

- Task scope does not exceed `task.md`.
- Every implementation change maps to `spec.md` and `acceptance.md`.
- Code tasks have reviewed `design.md` before coding.
- PR body acceptance and test plan have no unchecked items before merge.
- Security review is present for code or sensitive tasks.
- Acceptance evidence follows `bf-verification` output for every changed surface.
- `docs/blueprint/current/` is updated only after acceptance, not during planning.

## Anti-patterns

- Starting implementation directly from `READY` without four-piece baseline.
- Treating `bf-git-workflow` as the whole task execution flow.
- Opening separate PRs for spec, design, implementation, or closure.
- Leaving Active Task Resume stale after `bf-milestone-progress` reconciles accepted-task state.
- Starting the next task before `bf-milestone-progress` records the decision.

## How to invoke

```
follow skill bf-task-execute
```
