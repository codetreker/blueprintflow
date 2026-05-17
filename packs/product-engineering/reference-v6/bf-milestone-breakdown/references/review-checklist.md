# Breakdown Review Checklist

## Required Reviewers

| Role | Check |
|---|---|
| Architect | Task boundaries, dependencies, blueprint anchors |
| PM | User-facing task slices, stance drift, out-of-scope clarity |
| QA | Each acceptance slice is checkable and scoped |
| Dev | Each task fits one PR and can start from current context |
| Security | Required for auth, privacy, credentials, dangerous commands, remote agents, admin paths, or project-defined sensitive areas |

## Review Steps

1. Read `phase-plan.md`, `milestone.md`, every new `task.md`, and the locked next-blueprint anchors cited by the tasks.
2. Check that `milestone.md` has task index, dependency order, one first ready task, review table, and publication evidence.
3. Check that every `task.md` has purpose, scope, out-of-scope, dependency, blueprint anchors, acceptance slice, and sensitive paths.
4. Independently classify sensitivity from task scope, blueprint anchors, dependencies, APIs, files, and commands; do not rely only on the author's sensitivity value.
5. If any task is sensitive, add Security to the review table and require Security LGTM before `TASK_SET_READY`.
6. Check that every task fits one PR and no task contains implementation design, step-by-step build plan, four-piece content, or progress evidence.
7. Check that no `task-0-breakdown-*`, seed task, four-piece, design, implementation, or progress files were created during breakdown.
8. Check that breakdown did not create Active Task Resume rows, task worktree state, task branch/PR state, or `TASKING` task status.
9. Record reviewer decision in `milestone.md`.

Sensitive triggers: auth, privacy, credentials, dangerous commands, remote agents, admin paths, and project-defined sensitive areas.

## Decisions

| Decision | Meaning |
|---|---|
| `LGTM` | No open issue for this role lens |
| `NOT_LGTM` | Must fix before `TASK_SET_READY` |

No conditional LGTM. If a reviewer finds an issue, keep the milestone `PLANNED`, fix `task.md` or `milestone.md`, and re-review.
