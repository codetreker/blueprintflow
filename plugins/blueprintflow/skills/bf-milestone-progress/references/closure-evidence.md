# Milestone / Wave Closure Evidence

Use when all required tasks in a milestone or wave are accepted and `bf-milestone-progress` is deciding closure or `COMPLETED` readiness.

## Closure Summary Template

```markdown
## Closure Summary

State: OPEN / CLOSING / CLOSED
Closed on: YYYY-MM-DD or pending

Completed tasks:
- <task> -> PR #N, commit <sha>, acceptance evidence <link>

Deferred tasks:
- <task or anchor> -> future task path or placeholder PR #, reason

Blocked tasks:
- <task> -> owner, blocker, unblock action

Gate evidence:
| Gate | Evidence | Result |
|---|---|---|
| <milestone/wave/Phase gate> | <PR/test/demo/signoff link> | SIGNED / PARTIAL / DEFERRED / BLOCKED |

Current promotion readiness:
- Required task PRs merged: yes/no
- Acceptance evidence complete: yes/no
- Milestone/wave gates recorded: yes/no/N/A
- Phase gate recorded: yes/no/N/A
- docs/current sync checked: yes/no/N/A - reason
- Next ledger Work can be COMPLETED: yes/no
```

## Rules

- `CLOSED` requires all required tasks `ACCEPTED` or explicitly deferred with anchors, and every required gate `SIGNED`, `PARTIAL`, or `DEFERRED` with evidence.
- A `BLOCKED` required gate keeps state `CLOSING` or `OPEN`; it cannot be `CLOSED`.
- `PARTIAL` gates require condition, owner, and closure path.
- `DEFERRED` gates require future task path or placeholder PR number.
- `COMPLETED` in `docs/blueprint/next/README.md` requires accepted scope ready for current promotion.
- Do not duplicate task evidence; link to task `acceptance.md` or `progress.md`.

## Anti-patterns

- Closing with vague "later" carry-over.
- Setting `COMPLETED` while milestone/wave/Phase gates are pending.
- Keeping accepted tasks in Active Task Resume.
- Creating a closure-only follow-up PR when closure belongs in the task/milestone progress update.
