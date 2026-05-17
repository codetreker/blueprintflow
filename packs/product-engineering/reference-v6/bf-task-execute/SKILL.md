---
name: bf-task-execute
description: "Part of the Blueprintflow methodology. Use when a reviewed task.md is ready to start or resume, or task work must advance toward acceptance."
---

# Task Execute

Orchestrate one reviewed task from start to accepted task closure. Keep the task as one worktree, one branch, and one PR.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when either path applies:

| Path | Required state |
|---|---|
| Start a new task | `milestone.md` records `TASK_SET_READY` with LGTM breakdown review, marks the task `READY`, `docs/tasks/<phase>/<milestone>/<task>/task.md` exists, and no active task exists |
| Resume an existing concrete task | `docs/tasks/<phase>/<milestone>/<task>/task.md` exists; `milestone.md` marks the task `READY`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, or `ACCEPTING`; the task is unblocked by dependency order |

Concrete task work or resume must be needed.

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
2. Read `milestone.md`, `docs/tasks/README.md`, and the cited next-blueprint anchors.
3. Verify `milestone.md` records `TASK_SET_READY`, LGTM breakdown review, and Security LGTM when any task is sensitive. Stop and return to `bf-milestone-breakdown` if the reviewed-boundary gate is missing or NOT_LGTM.
4. Select exactly one `READY`, unblocked, dependency-valid task. If the user or Teamlead named a task, verify that same task is `READY`, unblocked, and dependency-valid; otherwise stop and return to `bf-milestone-progress` or the blocker owner.
5. Read the selected task's existing `task.md`. Stop if it is missing, stale, blocked, or too large for one PR; return to `bf-milestone-breakdown` or `bf-milestone-progress` to repair task boundaries.
6. Start or resume the worktree using `bf-git-workflow`.
7. Set the milestone-level next ledger `Work` to `IMPLEMENTING`; keep `Milestone path` pointed at the milestone folder. Put active task recovery only in `docs/tasks/README.md`, `milestone.md`, and the task folder.
8. Create or repair task baseline docs using `bf-task-fourpiece`.
9. For code tasks, run `bf-implementation-design` and require four-role design review before coding; record `READY_FOR_IMPL` only in `docs/tasks`.
10. Dispatch implementation work through the owning role coordinator using [references/implementation-loop.md](references/implementation-loop.md); Teamlead does not implement. Record task implementation state only in `docs/tasks`.
11. Check `docs/current` impact with `bf-current-doc-standard` when the project uses current docs.
12. Run `bf-verification` for the task surfaces. Required acceptance evidence must be complete before PR open; review may re-run or add evidence, not fill missing required evidence.
13. Open the task PR through `bf-git-workflow`; review and merge-gate it through `bf-pr-review-flow`. When the task enters review/acceptance, record `ACCEPTING` only in `docs/tasks`.
14. After merge and acceptance evidence, hand off to `bf-milestone-progress` for accepted-task recording, Active Task Resume cleanup, next task selection, milestone closure, or Phase exit readiness.

Do not mark the task `ACCEPTED`, set next ledger `Work` to `COMPLETED`, remove Active Task Resume, or promote current in this skill. Those are milestone-level follow-up decisions owned by `bf-milestone-progress` and `bf-blueprint-iteration`.

## State Transitions

```text
READY -> TASKING -> READY_FOR_IMPL -> IMPLEMENTING -> ACCEPTING -> ACCEPTED
```

Skip `READY_FOR_IMPL` only for non-code tasks with an explicit N/A in `progress.md`.

## Checks

- Task selection uses an existing reviewed `task.md`.
- Milestone breakdown status is `TASK_SET_READY` with required LGTM review before task execution starts.
- Do not create or rewrite task boundaries during task execution.
- Task scope does not exceed `task.md`.
- Every implementation change maps to `spec.md` and `acceptance.md`.
- Code tasks have reviewed `design.md` before coding.
- PR body acceptance and test plan have no unchecked items before merge.
- Security review is present for code or sensitive tasks.
- Acceptance evidence follows `bf-verification` output for every changed surface.
- `docs/blueprint/current/` is updated only after acceptance, not during planning.

## Anti-patterns

- Starting implementation directly from `READY` without four-piece baseline.
- Creating `task.md` during task execution instead of returning to `bf-milestone-breakdown` for boundary repair.
- Treating `bf-git-workflow` as the whole task execution flow.
- Opening separate PRs for spec, design, implementation, or closure.
- Leaving Active Task Resume stale after `bf-milestone-progress` reconciles accepted-task state.
- Starting the next task before `bf-milestone-progress` records the decision.

## How to invoke

```
follow skill bf-task-execute
```
