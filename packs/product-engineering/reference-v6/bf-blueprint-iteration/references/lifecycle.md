# Iteration Lifecycle

## Mainline

```
accepted current
-> user opens next selection
-> scan backlog once
-> write/resume docs/blueprint/next + ledger
-> lock selected anchors
-> write source-issues.md
-> hand off locked scope to bf-phase-plan
-> downstream execution completes accepted scope
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
- Recover next/current state from `docs/blueprint/next/README.md` and `docs/blueprint/current/`.
- Recover active execution state through `docs/tasks` skills; return here only for scope changes, reopened anchors, or accepted-scope promotion.

## Next status ledger

Read `docs/blueprint/next/README.md` first after interruption:

```markdown
# Blueprint Next State

Target version: vN.M
Last updated: YYYY-MM-DD
Resume from: <one concrete next action>

| Anchor | Topic | Decision | Work | Milestone path | Next action |
|---|---|---|---|---|---|
| RA-1 | Web-triggered configure | LOCKED | PENDING | - | hand off to `bf-phase-plan` |
| RA-2 | Helper sandbox stance | OPEN | PENDING | - | resolve stance |
| RA-3 | Helper boot/crash | LOCKED | IMPLEMENTING | docs/tasks/phase-6-remote-agent/milestone-3-helper-service | see `docs/tasks/README.md` |
| RA-4 | Status and logs UI | LOCKED | IMPLEMENTING | docs/tasks/phase-6-remote-agent/milestone-4-operator-status | see `docs/tasks/README.md` |
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
- Hand off to `bf-phase-plan` for downstream execution planning.
- Do not require complete task decomposition at lock time.
- Do not promote to current.

Return to `bf-blueprint-iteration` only when scope changes, anchors reopen, or accepted downstream scope is ready for current promotion.

## Scope Changes

Use this only after a downstream owner decides execution cannot continue inside the locked scope.

1. Record the downstream decision source: task/milestone/Phase path, PR or evidence link, owner, and reason.
2. If the blueprint stance changed or the locked anchor is no longer valid, mark the affected next row `REOPENED` and reopen the next blueprint section for discussion.
3. If only part of the locked scope should move later, keep the accepted/active anchor locked and create or update a backlog/future-scope trace for the remainder.
4. If the scope split changes execution ownership, update only the coarse next ledger fields this skill owns: anchor rows, `Work`, `Milestone path`, and `Next action`.
5. Hand the revised locked scope back to `bf-phase-plan` or the relevant `docs/tasks` skill. Do not repair task files here.

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
