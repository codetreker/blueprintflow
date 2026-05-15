# State and Files

## Milestone Readiness Meanings

| State | Checkable meaning |
|---|---|
| `PLANNED` | `phase-plan.md` and `milestone.md` exist; `milestone.md` records `Readiness State: PLANNED` |
| `READINESS_REVIEW` | Readiness review, evidence, or publication is incomplete; `milestone.md` records `Readiness State: READINESS_REVIEW` |
| `READY_FOR_EXECUTION` | Readiness gate passed and published; `milestone.md` records `Readiness State: READY_FOR_EXECUTION`, boundary, acceptance direction, coarse dependencies, review result, and handoff direction |
| `TASKING` | A concrete task has entered execution; task-level planning, progress, or implementation work is active |

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
└── milestone.md
```

Do not create a planning task folder solely for readiness review. In PR-governed projects, the readiness PR itself owns the publication record.

`milestone.md` contains:

- readiness change owner
- `Readiness State`
- milestone boundary and acceptance direction
- coarse dependencies and known blockers
- review status summary
- handoff direction for execution

Do not create `progress.md`, task folders, or `task.md` files during readiness review.

When one task starts later:

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
- Readiness active: next ledger stays on the milestone folder and `Work` is `IMPLEMENTING`.
- Ready for execution: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; `milestone.md` records the readiness review and evidence.
- Tasking: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; task-level recovery lives in `docs/tasks/README.md`, `milestone.md`, and the active task folder.
