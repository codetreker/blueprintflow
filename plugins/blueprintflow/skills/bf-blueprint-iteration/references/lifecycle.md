# Iteration Lifecycle

## Mainline

```
accepted current
-> user opens next selection
-> scan backlog once
-> write/resume docs/blueprint/next + ledger
-> lock selected anchors
-> write source-issues.md
-> plan Phase -> Milestone
-> review selected milestone readiness
-> execute tasks through docs/tasks
-> accept milestone/wave/Phase gates
-> promote accepted scope to current
-> tag blueprint-vN.M and mark next rows COMPLETED
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

| Anchor | Topic | Decision | Work | Milestone path | Next action |
|---|---|---|---|---|---|
| RA-1 | Web-triggered configure | LOCKED | PENDING | docs/tasks/phase-6-remote-agent/milestone-2-web-config | run or resume from milestone.md |
| RA-2 | Helper sandbox stance | OPEN | PENDING | - | resolve stance |
| RA-3 | Helper boot/crash | LOCKED | IMPLEMENTING | docs/tasks/phase-6-remote-agent/milestone-3-helper-service | see docs/tasks for readiness/task state |
| RA-4 | Status and logs UI | LOCKED | IMPLEMENTING | docs/tasks/phase-6-remote-agent/milestone-4-operator-status | see docs/tasks for active task |
| RA-5 | Configure job API | LOCKED | COMPLETED | docs/tasks/phase-6-remote-agent/milestone-2-web-config | promote to current or confirm current sync |
| RA-6 | Enrollment status | LOCKED | COMPLETED | docs/tasks/phase-5-enrollment/milestone-1-status | none |
```

Decision values: `OPEN`, `LOCKED`, `REOPENED`.

Work values: `PENDING`, `IMPLEMENTING`, `COMPLETED`.

Rules:
- `Milestone path` stops at the milestone folder.
- `Next action` names only the next coarse handoff. If work is active, point readers to `docs/tasks/README.md` or `milestone.md` instead of duplicating task state.

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
- Require milestones, dependency boundaries, acceptance direction, and exit-gate direction.
- Do not create task seeds or require task decomposition at lock time.
- Do not promote to current.

When a milestone is selected for execution:
- Run milestone readiness review.
- Keep `milestone.md` as readiness evidence: scope boundary, acceptance direction, real dependency/conflict constraints, sensitivity/risk notes, blockers, and handoff direction.
- Publish the readiness review before task execution starts.
- In governed-change projects, include the `IMPLEMENTING` next-ledger update in the same readiness change when execution is actively being prepared; leave the row `PENDING` when the milestone is planned but idle.
- Do not create task folders, `task.md` contracts, task dependency order, parallelism plans, or concrete task work in readiness review.

Task work starts when `bf-task-execute` creates or resumes a concrete task from the current milestone context.

## Promotion to current

Promote only accepted work. Required:
- All relevant task PRs are merged.
- Acceptance templates are ✅ and verifiable.
- Milestone, wave, or Phase gates required by `docs/tasks` have passed.
- `docs/current` is synced when the project uses that convention.
- User/PM acceptance for user-perceivable behavior is recorded.

Then:
- Update `docs/blueprint/current/`.
- Tag `blueprint-vN.M`.
- Mark corresponding next ledger rows `COMPLETED`.

Use [promotion-checklist.md](promotion-checklist.md) for the promotion procedure.

## Stuck-task safety net

Stuck signal:
- Missed explicit checkpoint in `progress.md` / `Active Task Resume`.
- No state change across the project-defined stuck threshold.
- LLM default: two fast check-ins with no owner output, no blocker update, and no artifact change.

When stuck:
- Architect + PM choose one: split task, reopen next anchor, or move remainder to future backlog.
- Update `docs/tasks/README.md` and the coarse next ledger if scope changes.
- Do not drag the whole milestone or Phase indefinitely.
