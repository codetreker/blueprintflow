# Breakdown Review Checklist

## Required Reviewers

| Role | Check |
|---|---|
| Architect | Task boundaries, blueprint anchors, dependency graph |
| PM | User value slices, stance drift, out-of-scope clarity |
| QA | Acceptance slices are testable and scoped |
| Dev | Each task is implementable in one PR; dependency order is executable |
| Security | Required for auth, privacy, credentials, dangerous commands, remote agents, admin paths, or project-defined sensitive areas |

## Review Steps

1. Read `milestone.md` and every `task.md`.
2. Check that each task has purpose, scope, out-of-scope, dependencies, anchors, acceptance slice, parallelism, and sensitive paths.
3. Independently classify sensitivity from task scope, blueprint anchors, dependencies, APIs, files, and commands; do not rely only on the author's `Sensitive paths` value.
4. If any task is sensitive, add Security to the review table and require Security LGTM before `TASK_SET_READY`.
5. Check that no task requires more than one PR.
6. Check that the first ready task can start without hidden prerequisites.
7. Record reviewer decision in `milestone.md`.

Sensitive triggers: auth, privacy, credentials, dangerous commands, remote agents, admin paths, and project-defined sensitive areas.

## Decisions

| Decision | Meaning |
|---|---|
| `LGTM` | No open issue for this role lens |
| `NOT_LGTM` | Must fix before `TASK_SET_READY` |

No conditional LGTM. If a reviewer finds an issue, keep the milestone in `BREAKING_DOWN`, fix the task contracts, and re-review.
