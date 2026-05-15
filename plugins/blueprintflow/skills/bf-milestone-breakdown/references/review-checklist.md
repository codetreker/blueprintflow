# Readiness Review Checklist

## Required Reviewers

| Role | Check |
|---|---|
| Architect | Phase/Milestone boundary, blueprint anchors, real dependencies |
| PM | User-facing milestone value, stance drift, out-of-scope clarity |
| QA | Acceptance direction is testable enough to start task execution |
| Dev | Execution can begin without hidden prerequisite or ownership conflict |
| Security | Required for auth, privacy, credentials, dangerous commands, remote agents, admin paths, or project-defined sensitive areas |

## Review Steps

1. Read `phase-plan.md`, `milestone.md`, and cited next-blueprint anchors.
2. Check that the Milestone has scope, out-of-scope, acceptance direction, anchors, known dependencies, and known sensitive areas.
3. Independently classify sensitivity from milestone scope, blueprint anchors, dependencies, APIs, files, and commands; do not rely only on the author's risk notes.
4. If any scope is sensitive, add Security to the review table and require Security LGTM before handoff.
5. Check that no task list, likely first task, dependency order, parallelism plan, task folder, or `task.md` contract was invented during readiness review.
6. Check that `bf-task-execute` can create concrete task work from the current milestone context without hidden prerequisites.
7. Record reviewer decision, blockers, and handoff direction in `milestone.md`.

Sensitive triggers: auth, privacy, credentials, dangerous commands, remote agents, admin paths, and project-defined sensitive areas.

## Decisions

| Decision | Meaning |
|---|---|
| `LGTM` | No open issue for this role lens |
| `NOT_LGTM` | Must fix before handoff to task execution |

No conditional LGTM. If a reviewer finds an issue, record the blocker owner in `milestone.md`, fix the readiness review, and re-review.
