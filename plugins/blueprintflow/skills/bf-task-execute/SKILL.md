---
name: bf-task-execute
description: "Part of the Blueprintflow methodology. Use when milestone readiness has passed and concrete task work must start, a reviewed task is ready to resume, or task work must advance toward acceptance."
---

# Task Execute

Orchestrate one concrete task from milestone readiness or an existing task contract to accepted task closure. Keep the task as one worktree, one branch, and one PR.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when either path is true:

- **Start path**: selected `milestone.md` has passed readiness review, no unresolved blocker remains, and concrete task creation is needed.
- **Resume path**: `docs/tasks/<phase>/<milestone>/<task>/task.md` exists, `milestone.md` marks the task `READY`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, or `ACCEPTING`, and concrete task work or resume is needed.

## Outputs

| Output | Owner skill |
|---|---|
| Worktree, branch, PR lifecycle, Active Task Resume creation/update | `bf-git-workflow` |
| Task folder and `task.md` created from milestone readiness context | `bf-task-execute`, inside the task worktree/branch |
| Task contract review/confirmation before four-piece starts | `bf-task-execute` |
| `spec.md`, `stance.md`, `acceptance.md`, optional `content-lock.md` | `bf-task-fourpiece` |
| `design.md` and four-role design review for code tasks | `bf-implementation-design` |
| Code/docs changes, tests, current-doc sync | Assigned role coordinators and helpers |
| Implementation loop and local test evidence | [references/implementation-loop.md](references/implementation-loop.md) |
| PR review and merge gate | `bf-pr-review-flow` |
| Coarse active work state in the milestone-level next ledger | `bf-task-execute` |
| Accepted-task cleanup, Active Task Resume removal, next task handoff, closure, and next-ledger decision | `bf-milestone-progress` |

## Steps

1. Run `bf-task-state-standard` if resume state is missing or inconsistent.
2. Read `milestone.md`, `docs/tasks/README.md`, and the cited next-blueprint anchors. If resuming, also read the existing `task.md`.
3. Start or resume the task worktree and branch using `bf-git-workflow`.
4. If no concrete `task.md` exists yet, create one task folder and `task.md` inside that task worktree/branch from the current milestone context and readiness review. The new `task.md` must include purpose, scope, out-of-scope, dependencies, blueprint anchors, acceptance slice, parallelism/conflict notes, and sensitive paths. Add or update the task row in `milestone.md` as `READY`. Stop and route back to `bf-milestone-breakdown` if readiness evidence is missing or blocked.
5. Confirm the task contract before four-piece starts: Architect, PM, QA, and Dev review `task.md`; add Security when sensitive paths are present. Record reviewer decisions in `task.md` or `milestone.md`. If any reviewer is `NOT_LGTM`, fix `task.md` or route back to `bf-milestone-breakdown` when the issue is milestone-readiness scope.
6. Set the task row to `TASKING`, create or update Active Task Resume, set the milestone-level next ledger `Work` to `IMPLEMENTING`, and keep `Milestone path` pointed at the milestone folder. Put active task recovery only in `docs/tasks/README.md`, `milestone.md`, and the task folder.
7. Create or repair task baseline docs using `bf-task-fourpiece`.
8. For code tasks, run `bf-implementation-design` and require four-role design review before coding; record `READY_FOR_IMPL` only in `docs/tasks`.
9. Dispatch implementation work through the owning role coordinator using [references/implementation-loop.md](references/implementation-loop.md); Teamlead does not implement. Record task implementation state only in `docs/tasks`.
10. Check `docs/current` impact with `bf-current-doc-standard` when the project uses current docs.
11. Run `bf-verification` for the task surfaces. Required acceptance evidence must be complete before PR open; review may re-run or add evidence, not fill missing required evidence.
12. Open the task PR through `bf-git-workflow`; review and merge-gate it through `bf-pr-review-flow`. When the task enters review/acceptance, record `ACCEPTING` only in `docs/tasks`.
13. After merge and acceptance evidence, hand off to `bf-milestone-progress` for accepted-task recording, Active Task Resume cleanup, next task handoff, milestone closure, or Phase exit readiness.

Do not mark the task `ACCEPTED`, set next ledger `Work` to `COMPLETED`, remove Active Task Resume, or promote current in this skill. Those are milestone-level follow-up decisions owned by `bf-milestone-progress` and `bf-blueprint-iteration`.

## State Transitions

```text
READY -> TASKING -> READY_FOR_IMPL -> IMPLEMENTING -> ACCEPTING -> ACCEPTED
```

Skip `READY_FOR_IMPL` only for non-code tasks with an explicit N/A in `progress.md`.

## Checks

- Task scope does not exceed `task.md`.
- `task.md` includes purpose, scope, out-of-scope, dependencies, blueprint anchors, acceptance slice, parallelism/conflict notes, and sensitive paths before four-piece starts.
- `task.md` review/confirmation is recorded before four-piece starts.
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
