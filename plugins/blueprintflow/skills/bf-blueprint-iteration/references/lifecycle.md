# Iteration Lifecycle

## Mainline

```
accepted current
-> user opens next selection
-> scan backlog once
-> write/resume docs/blueprint/next + ledger
-> lock selected anchors
-> write source-issues.md
-> plan Phase -> Milestone + first task seed
-> break down selected milestone into reviewed task.md skeletons
-> execute tasks through docs/tasks
-> accept milestone/phase gates
-> promote accepted scope to current
-> tag blueprint-vN.M and mark next rows CURRENT
```

## State ownership

| Artifact | Owns | Does not own |
|---|---|---|
| `docs/blueprint/current/` | Implemented, accepted product truth | Planned or in-progress work |
| `docs/blueprint/next/` | Locked/open blueprint work not yet accepted into current | Task mechanics or PR status |
| `docs/tasks/` | Execution path from next to current | Product stance source of truth |
| GitHub `backlog` issues | Initial selection intake | Ongoing implementation state |

Rules:
- After backlog selection, stop using GitHub labels as workflow state.
- Preserve selected issue numbers in `source-issues.md` and task/PR references.
- Recover anchor/milestone state from `docs/blueprint/next/README.md`.
- Recover task state from `docs/tasks/README.md`, `milestone.md`, and task folders.

## Next status ledger

Read `docs/blueprint/next/README.md` first after interruption:

```markdown
# Blueprint Next State

Target version: vN.M
Last updated: YYYY-MM-DD
Resume from: <one concrete next action>

| Anchor | Topic | Decision | Execution | Milestone path | Blocker | Next action |
|---|---|---|---|---|---|---|
| RA-1 | Web-triggered configure | LOCKED | MILESTONE_PLANNED | docs/tasks/phase-6-remote-agent/milestone-2-web-config | none | run milestone breakdown |
| RA-2 | Helper sandbox stance | OPEN | NO_PLAN | - | sudo boundary | role discussion |
| RA-3 | Helper boot/crash | LOCKED | BREAKING_DOWN | docs/tasks/phase-6-remote-agent/milestone-3-helper-service | Dev review | finish breakdown review in milestone.md |
| RA-4 | Helper service | LOCKED | TASK_SET_READY | docs/tasks/phase-6-remote-agent/milestone-3-helper-service | none | start first ready task from milestone.md |
| RA-5 | Status and logs UI | LOCKED | IMPLEMENTING | docs/tasks/phase-6-remote-agent/milestone-4-operator-status | none | resume active task from docs/tasks/README.md |
| RA-6 | Revoke behavior | LOCKED | ACCEPTING | docs/tasks/phase-6-remote-agent/milestone-5-revoke | none | resume acceptance from docs/tasks/README.md |
| RA-7 | Configure job API | LOCKED | ACCEPTED | docs/tasks/phase-6-remote-agent/milestone-2-web-config | none | promote to current |
| RA-8 | Legacy helper sandbox | REOPENED | NO_PLAN | - | product/security conflict | resolve stance |
| RA-9 | Enrollment status | LOCKED | CURRENT | docs/tasks/phase-5-enrollment/milestone-1-status | none | none |
```

Decision values: `OPEN`, `LOCKED`, `REOPENED`.

Execution values: `NO_PLAN`, `MILESTONE_PLANNED`, `BREAKING_DOWN`, `TASK_SET_READY`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, `ACCEPTING`, `ACCEPTED`, `CURRENT`.

Rules:
- `Milestone path` stops at the milestone folder. Task paths, task PRs, task owners, task blockers, and checkbox progress live under `docs/tasks/`.
- `Next action` names the next milestone-level handoff. If execution is already inside a task, it points readers to `docs/tasks/README.md`, `milestone.md`, or the active task folder instead of duplicating task state.
- `Blocker` records only blueprint-level or milestone-level blockers. Task-level blockers live under `docs/tasks/`.
- Do not add a PR column here. PRs are task mechanics owned by `docs/tasks/` and GitHub.

## Source Issues

Create `docs/blueprint/_meta/<target-version>/source-issues.md` after picking backlog issues:

```markdown
# Source issues for blueprint vN.M

Picked issues grouped by topic:

## Module X
- gh#123 — title, one sentence on what this version intends to deliver
- gh#125 — title, one sentence on what this version intends to deliver
```

Rules:
- List picked issues only.
- Use this file for traceability only.
- Do not treat selected issues as current behavior.

## After Lock

When one or more next anchors are `LOCKED`:
- Run Phase/Milestone planning under `docs/tasks/`.
- Require milestones, dependencies, acceptance boundaries, and first-milestone task seed.
- Do not require complete task decomposition at lock time.
- Do not promote to current.

When a milestone is selected for execution:
- Run milestone breakdown.
- Create one task skeleton folder per task.
- Create one `task.md` per task skeleton.
- Keep `milestone.md` as index, dependency order, review summary, and first-ready pointer.
- Publish the breakdown gate before `TASK_SET_READY`.
- In governed-change projects, include the `TASK_SET_READY` ledger update in the same breakdown change before publication.
- Do not start concrete task work in breakdown.

Task work starts after `TASK_SET_READY`.

## Promotion to current

Promote only accepted work. Required:
- All relevant task PRs are merged.
- Acceptance templates are ✅ and verifiable.
- Phase or milestone gates required by `docs/tasks` have passed.
- `docs/current` is synced when the project uses that convention.
- User/PM acceptance for user-perceivable behavior is recorded.

Then:
- Update `docs/blueprint/current/`.
- Tag `blueprint-vN.M`.
- Mark corresponding next ledger rows `CURRENT`.

## Stuck-task safety net

Stuck signal:
- Missed explicit checkpoint in `progress.md` / `Active Task Resume`.
- No state change across the project-defined stuck threshold.
- LLM default: two fast check-ins with no owner output, no blocker update, and no artifact change.

When stuck:
- Architect + PM choose one: split task, reopen next anchor, or move remainder to future backlog.
- Update `docs/tasks/README.md` and the next ledger if scope changes.
- Do not drag the whole milestone or Phase indefinitely.
