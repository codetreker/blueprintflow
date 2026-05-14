# State and Files

## State Meanings

| State | Checkable meaning |
|---|---|
| `MILESTONE_PLANNED` | `phase-plan.md` and `milestone.md` exist; first task seed exists; task skeletons are not reviewed yet |
| `BREAKING_DOWN` | Breakdown worktree/PR is active, unmerged, or task skeletons/review are incomplete |
| `TASK_SET_READY` | Breakdown gate passed and published: for PR-governed projects, the merged breakdown PR contained the final `TASK_SET_READY` ledger update; for non-PR projects, equivalent review evidence was recorded in the same update; every task skeleton folder has `task.md`; `milestone.md` names dependency order and first ready task |
| `TASKING` | A concrete task has entered `bf-git-workflow` / `bf-milestone-fourpiece`; four-piece/design work is active |

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

`task-0-breakdown-<milestone>/` is a planning task folder only when the project requires a PR for breakdown docs changes. It owns the breakdown PR record; it is not a product task and does not receive four-piece files.

`breakdown.md` contains:

- PR/worktree/branch owner
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

- `BREAKING_DOWN`: `Plan/task path` points to `task-0-breakdown-*` when a breakdown PR exists; otherwise it points to the milestone folder.
- `TASK_SET_READY`: `Plan/task path` points to the first ready task folder; the ledger PR column records the merged breakdown PR, or the evidence link/record for non-PR projects, until the task starts. In PR-governed projects, this row change is part of the breakdown PR before merge; no follow-up PR or direct commit is allowed.
- `TASKING`: `Plan/task path` points to the active task folder; PR/worktree may exist.
