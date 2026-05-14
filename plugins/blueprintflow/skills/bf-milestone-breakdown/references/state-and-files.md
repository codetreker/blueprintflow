# State and Files

## `docs/tasks` State Meanings

| State | Checkable meaning |
|---|---|
| `PLANNED` | `phase-plan.md` and `milestone.md` exist; first task seed exists; task skeletons are not reviewed yet |
| `BREAKING_DOWN` | Breakdown change is in progress, or task skeletons, review, evidence, or publication are incomplete |
| `TASK_SET_READY` | Breakdown gate passed and published; every task skeleton folder has `task.md`; `milestone.md` names dependency order, first ready task, review result, and publication evidence |
| `TASKING` | A concrete task has entered `bf-task-execute`; task-level planning, progress, or implementation work is active |

## File Timeline

After `bf-phase-plan`:

```text
docs/tasks/<phase>/
├── phase-plan.md
└── <milestone>/
    ├── milestone.md
    └── task-seed.md
```

After `bf-milestone-breakdown`:

```text
docs/tasks/<phase>/<milestone>/
├── milestone.md
├── task-0-breakdown-<milestone>/
│   └── breakdown.md
├── task-1-<name>/
│   └── task.md
└── task-2-<name>/
    └── task.md
```

`task-0-breakdown-<milestone>/` is a planning task folder only when the project requires governed breakdown docs changes. It owns the breakdown publication record; it is not a product task and does not receive four-piece files.

`breakdown.md` contains:

- breakdown change owner
- links to changed `milestone.md` and task skeleton folders
- review status summary
- handoff to first ready task

Do not create `progress.md` for `task-0-breakdown-*`; use `breakdown.md`.

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
- Breakdown active: next ledger stays on the milestone folder and `Work` is `IMPLEMENTING`; `docs/tasks/README.md` or `milestone.md` points to `task-0-breakdown-*` when a governed breakdown change exists.
- Reviewed task set ready: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; `milestone.md` names the first ready task and records the breakdown review/evidence.
- Tasking: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; task-level recovery lives in `docs/tasks/README.md`, `milestone.md`, and the active task folder.
