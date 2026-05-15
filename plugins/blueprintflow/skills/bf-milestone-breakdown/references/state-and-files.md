# State and Files

## Breakdown Status Meanings

| State | Checkable meaning |
|---|---|
| `PLANNED` | `phase-plan.md` and `milestone.md` exist; reviewed task boundaries are not published yet |
| `TASK_SET_READY` | Reviewed task folders and boundary-level `task.md` files are published; one unblocked task is marked `READY` |

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
├── milestone.md
├── task-1-<name>/
│   └── task.md
└── task-2-<name>/
    └── task.md
```

`milestone.md` contains the task index, dependency order, first ready task, review summary, and publication evidence. Do not create `task-0-breakdown-*` or a seed planning task.

Each `task.md` contains boundary-level scope only:

- purpose
- scope and out-of-scope
- dependencies
- blueprint anchors
- acceptance slice
- sensitive paths

Do not create four-piece, `design.md`, implementation files, or `progress.md` during breakdown.

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
- Breakdown active: next ledger stays on the milestone folder and `Work` is `IMPLEMENTING`; the published milestone state remains `PLANNED` until the reviewed task set is complete.
- Task set ready: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; `milestone.md` records `TASK_SET_READY`, task index, review evidence, and the first ready task.
- Tasking: next ledger stays on the milestone folder and `Work` remains `IMPLEMENTING`; task-level recovery lives in `docs/tasks/README.md`, `milestone.md`, and the active task folder.
