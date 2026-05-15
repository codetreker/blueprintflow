# Files and Ledgers

## State Placement

| State | File | Required content |
|---|---|---|
| Blueprint decision | `docs/blueprint/next/README.md` | Anchor, decision status, coarse work status, milestone path |
| Phase resume | `docs/tasks/README.md` | Phase, status, exit condition, current milestone |
| Active task resume | `docs/tasks/README.md` | Scope, execution, active task, owner, worktree/branch, PR, blocker, progress path |
| Milestone resume | `docs/tasks/<phase>/<milestone>/milestone.md` | Readiness review before task execution; task index, real blockers/dependencies, and closure state after tasks start |
| Task contract | `docs/tasks/<phase>/<milestone>/<task>/task.md` | Scope, anchors, out-of-scope, acceptance slice, dependencies, sensitive paths created or confirmed by `bf-task-execute` |
| Task progress | `docs/tasks/<phase>/<milestone>/<task>/progress.md` | Worktree/branch, PR, checkpoints, blockers, acceptance evidence, current sync |

## `docs/blueprint/next/README.md`

Keep this ledger at milestone level.

```markdown
| Anchor | Decision | Work | Milestone path | Notes |
|---|---|---|---|---|
| remote-agent §2 | LOCKED | IMPLEMENTING | docs/tasks/phase-6-remote-agent/milestone-2-web-config | see docs/tasks for active state |
```

Allowed `Work` values: `PENDING`, `IMPLEMENTING`, `COMPLETED`.

## `docs/tasks/README.md`

Use two tables.

```markdown
## Phase Index

| Phase | Status | Exit condition | Current milestone |
|---|---|---|---|
| phase-6-remote-agent | IMPLEMENTING | G6 strict + PM signoff | milestone-2-web-config |

## Active Task Resume

| Scope | Execution | Active task | Owner | Worktree/branch | PR | Blocker | Progress |
|---|---|---|---|---|---|---|---|
| phase-6/milestone-2 | IMPLEMENTING | task-1-configure-job-api | Dev | .worktrees/task-1-configure-job-api / feat/task-1-configure-job-api | #820 | none | docs/tasks/phase-6/milestone-2/task-1-configure-job-api/progress.md |
```

Remove Active Task Resume rows only after `bf-milestone-progress` reconciles accepted-task state. Keep closed state in the task folder and milestone summary.

## `milestone.md`

Required sections:

```markdown
# <Milestone Name>

## Goal

## Readiness Review

| Role | Decision | Notes |
|---|---|---|

Blockers: <none or owner + required action>
Handoff: <bf-task-execute direction>

## Task Index

| Task | Status | Depends on | PR | Notes |
|---|---|---|---|---|

## Blockers

## Closure Summary
```

Statuses: `PLANNED`, `READY`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, `ACCEPTING`, `ACCEPTED`, `DEFERRED`, `BLOCKED`.

## `task.md`

Required sections:

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

Parallelism / conflicts:
- <can run with / blocks / blocked by / unknown until execution>

Sensitive paths:
- <auth/privacy/credentials/dangerous-commands/remote-agent/admin/project-sensitive/none>

## Task Contract Review

| Role | Decision | Notes |
|---|---|---|
| Architect | pending | - |
| PM | pending | - |
| QA | pending | - |
| Dev | pending | - |
| Security | N/A or pending | required when sensitive paths are present |
```

## `progress.md`

Create when a task starts.

```markdown
# Progress

## Resume

| Field | Value |
|---|---|
| Worktree | .worktrees/<task> |
| Branch | feat/<task> |
| PR | #N or pending |
| Owner | <role/name> |
| State | TASKING / READY_FOR_IMPL / IMPLEMENTING / ACCEPTING / ACCEPTED |
| Blocker | none or concrete blocker |

## Checkpoints

- [ ] Worktree created
- [ ] Four-piece baseline complete
- [ ] Implementation design reviewed
- [ ] Implementation complete
- [ ] docs/current sync checked or N/A recorded
- [ ] Acceptance evidence recorded through `bf-verification`
- [ ] PR merged

## Acceptance Evidence

| Check | Evidence | Result |
|---|---|---|
| <acceptance item> | <command/test/screenshot/log/PR anchor> | PASS / HOLD / BLOCK |

Verifier: <role/name>
Date: YYYY-MM-DD
Scope: <UI/API/data/CLI/background/security/current-doc>
Fixtures: <fixture/user/tenant/resource, secrets redacted, or N/A>
Out-of-scope findings: <issue links or N/A>
Decision: LGTM / HOLD / BLOCK
```

## Consistency Rules

- `PENDING` in next ledger means no active execution is happening for that anchor, even if Phase/Milestone planning exists.
- `IMPLEMENTING` in next ledger means active planning, breakdown, task execution, review, acceptance, or Phase gate work is happening in `docs/tasks`.
- `COMPLETED` in next ledger requires accepted scope ready for current promotion or already reflected in current; required milestone, wave, or Phase gates must be recorded.
- Readiness review does not require a task folder or first ready task.
- `TASKING` requires an Active Task Resume row and a task folder.
- `READY_FOR_IMPL` requires four-piece baseline and reviewed `design.md` for code tasks.
- `IMPLEMENTING` requires worktree/branch state in Active Task Resume or `progress.md`.
- `ACCEPTED` requires merged task PR, `bf-verification` acceptance evidence, and milestone update.
- Use `docs/tasks/README.md`, `milestone.md`, and task `progress.md` for fine-grained task state.
