# Breakdown Review Checklist

## Required Reviewers

| Role | Check |
|---|---|
| Architect | Milestone boundary, blueprint anchors, split dimension, and recoverability |
| PM | User-facing milestone value, stance drift, and out-of-scope clarity |
| QA | Acceptance direction is testable at milestone level |
| Dev | Execution can start from current context without premature task guesses |
| Security | Required for auth, privacy, credentials, dangerous commands, remote agents, admin paths, or project-defined sensitive areas |

## Review Steps

1. Read `phase-plan.md`, `milestone.md`, and cited locked blueprint anchors.
2. Check that the milestone has a clear capability boundary, out-of-scope boundary, acceptance direction, coarse dependencies, known blockers, and handoff direction.
3. Independently classify sensitivity from milestone scope, blueprint anchors, dependencies, APIs, files, and commands.
4. If the milestone is sensitive, add Security to the review table and require Security LGTM before `READY_FOR_EXECUTION`.
5. Check that review focuses on direction, boundary, split dimension, and recoverability.
6. Check that `milestone.md` does not name task folders, a task index, dependency order, parallelism plan, first ready task, or first task guess.
7. Record reviewer decision in `milestone.md`.

Sensitive triggers: auth, privacy, credentials, dangerous commands, remote agents, admin paths, and project-defined sensitive areas.

## Decisions

| Decision | Meaning |
|---|---|
| `LGTM` | No open issue for this role lens |
| `NOT_LGTM` | Must fix before `READY_FOR_EXECUTION` |

No conditional LGTM. If a reviewer finds an issue, keep the milestone in readiness review, fix `milestone.md`, and re-review.
