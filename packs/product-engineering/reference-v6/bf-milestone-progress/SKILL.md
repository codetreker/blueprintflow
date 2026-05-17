---
name: bf-milestone-progress
description: "Part of the Blueprintflow methodology. Use when a task is accepted, the next task must be selected, a milestone may close, or Phase exit readiness must be checked."
---

# Milestone Progress

Advance a milestone after task acceptance. Do not create task folders, implement code, or merge PRs in this skill.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when any are true:

- A task PR merged and acceptance evidence exists.
- `milestone.md` needs the next ready task selected.
- A milestone may be complete, blocked, or ready for closure.
- A Phase may be ready for `bf-phase-exit-gate`.

## Outputs

| Output | File |
|---|---|
| Accepted task status and PR/commit anchor | `milestone.md`, task `progress.md` |
| Next ready task or blocker | `milestone.md`, `docs/tasks/README.md` |
| Next-blueprint coarse work state update | `docs/blueprint/next/README.md` |
| Milestone closure summary | `milestone.md` |
| Milestone/wave closure evidence | [references/closure-evidence.md](references/closure-evidence.md) |
| Phase-exit handoff | `docs/tasks/README.md` and Teamlead notebook |

## Steps

1. Run `bf-task-state-standard` if task or milestone state is inconsistent.
2. Read `milestone.md`, the completed task `progress.md`, `docs/tasks/README.md`, and `docs/blueprint/next/README.md`.
3. Confirm the task is actually accepted: PR merged, acceptance evidence recorded, required reviews/CI passed, current-doc sync done or N/A.
4. Mark the task `ACCEPTED` in `milestone.md` with PR and commit anchors.
5. Remove closed rows from Active Task Resume.
6. Pick the next task by dependency order, blocker severity, and milestone priority.
7. If a next task is ready, mark it `READY`, keep the next ledger `Work` as `IMPLEMENTING` with `Milestone path` still pointed at the milestone folder, and hand off to `bf-task-execute`.
8. If tasks remain blocked, record the blocker and dispatch the owning role.
9. If all required tasks are accepted, write the milestone closure summary using [references/closure-evidence.md](references/closure-evidence.md).
10. If required milestone or wave gates still need review, keep the next ledger `Work` as `IMPLEMENTING` and finish them in this skill.
11. If Phase-level exit is needed after milestone or wave closure, keep the next ledger `Work` as `IMPLEMENTING` and hand off to `bf-phase-exit-gate`.
12. Update the next ledger `Work` to `COMPLETED` only after required milestone, wave, or Phase gates pass and the accepted scope is ready for current promotion.

Keep Phase and milestone dependency order. Do not jump to a later milestone or Phase while an earlier dependency is open unless the relevant `phase-plan.md` or `milestone.md` records safe parallelism, carry-over, or a waiver.

## Checks

- No task is marked `ACCEPTED` without merged PR and acceptance evidence.
- The next selected task has all dependencies accepted or explicitly waived.
- Blocked tasks name a concrete owner and unblock action.
- Milestone closure lists completed tasks, deferred tasks, carry-over anchors, and acceptance evidence.
- Milestone/wave closure evidence follows [references/closure-evidence.md](references/closure-evidence.md).
- Phase exit is not started until milestone closure is recorded.
- `COMPLETED` is not set while required milestone, wave, or Phase gates are still pending.
- Later milestone or Phase work is not selected without accepted dependencies or a recorded waiver.

## Anti-patterns

- Starting the next task because chat says the previous one is done.
- Closing a milestone with blocked or unaccepted required tasks.
- Moving scope to `current` from milestone progress without acceptance promotion.
- Leaving Active Task Resume rows after accepted-task reconciliation.
- Selecting parallel tasks without checking dependency order.

## How to invoke

```
follow skill bf-milestone-progress
```
