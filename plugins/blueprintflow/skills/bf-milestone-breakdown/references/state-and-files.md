# State and Files

## Ledger Boundary

Milestone readiness review uses existing ledgers only:

- `docs/blueprint/next/README.md` keeps `Milestone path` at the milestone folder.
- `docs/blueprint/next/README.md` `Work` is `PENDING` when the milestone is planned but idle, or `IMPLEMENTING` when execution is actively being prepared or run.
- `milestone.md` records readiness review evidence, blocker owner, and handoff direction.
- Concrete task state begins only when `bf-task-execute` creates or resumes a task from current milestone context.

Do not add milestone breakdown states such as `BREAKING_DOWN`, `TASK_SET_READY`, or `TASKING` for readiness review.

## File Timeline

After `bf-phase-plan`:

```text
docs/tasks/<phase>/
├── phase-plan.md
└── <milestone>/
    └── milestone.md
```

After `bf-milestone-breakdown`:

```text
docs/tasks/<phase>/<milestone>/
└── milestone.md          # includes readiness review
```

Readiness review does not create `task-0-breakdown-*`, `task-N-*`, `task.md`, `breakdown.md`, or `progress.md` files.

`milestone.md` readiness review contains:

- readiness reviewer decisions
- scope boundary and acceptance direction
- real dependency or conflict constraints known now
- sensitive areas and risk notes
- blockers with owner and required action
- review status summary
- handoff direction for `bf-task-execute`

Readiness passes only when reviewer decisions are recorded, no unresolved blocker remains, and the handoff direction tells `bf-task-execute` where to create or resume concrete task work. It does not name a first ready task.

After one task starts:

```text
docs/tasks/<phase>/<milestone>/task-1-<name>/
├── task.md
├── spec.md
├── stance.md
├── acceptance.md
├── design.md
└── progress.md
```

## Ledger Update

- `docs/blueprint/next/README.md`: `Milestone path` points to the milestone folder only. `Work` is only `PENDING`, `IMPLEMENTING`, or `COMPLETED`.
- Readiness active: next ledger stays on the milestone folder and `Work` is `IMPLEMENTING`; `milestone.md` records review evidence and blockers.
- Readiness passed: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; `milestone.md` records handoff direction, not a first ready task.
- Task execution: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; task-level recovery lives in `docs/tasks/README.md`, `milestone.md`, and the active task folder after `bf-task-execute` creates or resumes the task.
