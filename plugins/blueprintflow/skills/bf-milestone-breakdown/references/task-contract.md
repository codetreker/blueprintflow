# Task Contract

## Inputs

- `docs/blueprint/next/README.md` ledger rows for the locked anchors
- Cited `docs/blueprint/next/*.md` sections
- `docs/tasks/<phase>/phase-plan.md`
- `docs/tasks/<phase>/<milestone>/milestone.md`
- First task seed from `milestone.md` or `task-seed.md`

## Folder Shape

```text
docs/tasks/<phase>/<milestone>/
├── milestone.md
├── task-1-<name>/
│   └── task.md
└── task-2-<name>/
    └── task.md
```

## milestone.md Sections

```markdown
## Task Index

| Task | Purpose | Depends on | Parallel? | First ready? |
|---|---|---|---|---|
| task-1-configure-job-api | Web can enqueue configure jobs | none | yes | yes |
| task-2-helper-runner | Host helper runs queued jobs | task-1 | no | no |

## Breakdown Review

| Role | Decision | Notes |
|---|---|---|
| Architect | pending | - |
| PM | pending | - |
| QA | pending | - |
| Dev | pending | - |
| Security | N/A or pending | required if any task is sensitive |
```

## task.md Template

```markdown
# task-N-short-name

Purpose:
- <one user/value or system capability slice>

Scope:
- <included behavior/file/API/data slice>

Out of scope:
- <nearby behavior intentionally excluded>

Depends on:
- <task id or none>

Blueprint anchors:
- <anchor id / section>

Acceptance slice:
- <one or more checkable outcomes>

Parallelism:
- <can run with / blocks / blocked by>

Sensitive paths:
- <auth/privacy/credentials/dangerous-commands/remote-agent/admin/project-sensitive/none>
```

## Rules

- One task must fit one PR.
- Every task must cite at least one locked next-blueprint anchor.
- Every task must have a checkable acceptance slice.
- Put task-specific scope in `task.md`; keep `milestone.md` as index and review summary.
- Reviewers must independently classify sensitive paths from scope, anchors, dependencies, APIs, files, and commands.
- If any task is sensitive, `milestone.md` must include a Security review row and Security must approve before `TASK_SET_READY`.
- Do not create four-piece files during breakdown.
