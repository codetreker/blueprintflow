# Task Contract

## Inputs

- `docs/blueprint/next/README.md` ledger rows for the locked anchors
- Cited `docs/blueprint/next/*.md` sections
- `docs/tasks/<phase>/phase-plan.md`
- `docs/tasks/<phase>/<milestone>/milestone.md`

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
## Breakdown

Status: PLANNED | TASK_SET_READY

Publication evidence:
- <PR/comment/commit/equivalent evidence>

## Task Index

| Task | Status | Purpose | Depends on | First ready? |
|---|---|---|---|---|
| task-1-configure-job-api | READY | Web can enqueue configure jobs | none | yes |
| task-2-helper-runner | PLANNED | Host helper runs queued jobs | task-1 | no |

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

Sensitive paths:
- <auth/privacy/credentials/dangerous-commands/remote-agent/admin/project-sensitive/none>
```

## Rules

- One task must fit one PR.
- Every task must cite at least one locked next-blueprint anchor.
- Every task must have a checkable acceptance slice.
- Put task-specific boundary in `task.md`; keep `milestone.md` as index and review summary.
- Mark exactly one unblocked first task `READY` when the milestone reaches `TASK_SET_READY`; other tasks start as `PLANNED`, `BLOCKED`, or `DEFERRED`.
- If no task is unblocked, keep the milestone `PLANNED`, record the blocker owner and next action in `milestone.md`, and route back to the blocker owner or `bf-phase-plan` for replanning.
- Reviewers must independently classify sensitive paths from scope, anchors, dependencies, APIs, files, and commands.
- If any task is sensitive, `milestone.md` must include a Security review row and Security must approve before `TASK_SET_READY`.
- Do not create four-piece, design, implementation, or progress files during breakdown.
