---
name: bf-task-execute
description: "Part of the Blueprintflow methodology. Use when a concrete task is ready to start or resume, or when task work must advance toward acceptance."
---

# Task Execute

Orchestrate one concrete task from current milestone context to accepted task closure. Keep the task as one worktree, one branch, and one PR.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when either entry is true:

- Existing task entry: `docs/tasks/<phase>/<milestone>/<task>/task.md` exists, `milestone.md` marks the task `READY`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, or `ACCEPTING`, the task is unblocked, and concrete task work or resume is needed.
- New task entry: `bf-milestone-breakdown` passed readiness review, `milestone.md` has a readiness summary, and current context is sufficient to create exactly one concrete task for immediate execution.

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

## Task Creation Contract

When creating a new task, the Architect owns the `task.md` scope and must stop before four-piece setup unless every field is present:

| Field | Required content |
|---|---|
| Purpose | One concrete capability slice for this PR |
| Scope | Included behavior, files, APIs, or data slice |
| Out of scope | Nearby behavior intentionally excluded |
| Depends on | Accepted task, explicit waiver, or `none` |
| Blueprint anchors | Locked next-blueprint anchors or sections |
| Acceptance slice | Checkable outcomes for this task |
| Sensitive paths | auth/privacy/credentials/dangerous-commands/remote-agent/admin/project-sensitive/none |

If the task scope is unclear, too large for one PR, lacks anchors, lacks acceptance, or needs a prerequisite decision, stop and route to the owning role to repair `milestone.md` or the new `task.md`. Do not run `bf-task-fourpiece` until the task creation contract is complete.

## Steps

1. Run `bf-task-state-standard` if resume state is missing or inconsistent.
2. Read `milestone.md`, `docs/tasks/README.md`, and the cited next-blueprint anchors.
3. If a current `task.md` exists, read it and start or resume the worktree using `bf-git-workflow`.
4. If no current `task.md` exists, define exactly one task id and scope from the readiness summary and current execution context, start the one-task worktree using `bf-git-workflow`, then create that task folder and `task.md` inside the task worktree. Do not create future task folders, dependency order guesses, parallelism plans, or first-task lists.
5. Read the created or resumed `task.md` before continuing.
6. Set the milestone-level next ledger `Work` to `IMPLEMENTING`; keep `Milestone path` pointed at the milestone folder. Put active task recovery only in `docs/tasks/README.md`, `milestone.md`, and the task folder.
7. Create or repair task baseline docs using `bf-task-fourpiece`.
8. For code tasks, run `bf-implementation-design` and require four-role design review before coding; record `READY_FOR_IMPL` only in `docs/tasks`.
9. Dispatch implementation work through the owning role coordinator using [references/implementation-loop.md](references/implementation-loop.md); Teamlead does not implement. Record task implementation state only in `docs/tasks`.
10. Check `docs/current` impact with `bf-current-doc-standard` when the project uses current docs.
11. Run `bf-verification` for the task surfaces. Required acceptance evidence must be complete before PR open; review may re-run or add evidence, not fill missing required evidence.
12. Open the task PR through `bf-git-workflow`; review and merge-gate it through `bf-pr-review-flow`. When the task enters review/acceptance, record `ACCEPTING` only in `docs/tasks`.
13. After merge and acceptance evidence, hand off to `bf-milestone-progress` for accepted-task recording, Active Task Resume cleanup, next task selection, milestone closure, or Phase exit readiness.

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
