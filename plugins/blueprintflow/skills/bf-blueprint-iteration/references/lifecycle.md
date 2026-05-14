# Iteration lifecycle

```
Current implemented blueprint has passed acceptance
   ↓
Teamlead reminds the user "next selection can open"
   ↓
User says go
   ↓
Scan GitHub issues with label `backlog` once (clean up + pick)
   ↓
Write or resume docs/blueprint/next/ with a status ledger
   ↓
Four roles + Teamlead/user discuss until selected anchors are LOCKED
   ↓
Write docs/blueprint/_meta/<target-version>/source-issues.md for picked issues
   ↓
Architect runs bf-phase-plan against LOCKED next anchors
   ↓
docs/tasks/ records Phase -> Milestone plan + first-milestone task seed
   ↓
When a milestone starts, split it into a complete executable Task set
   ↓
Each Task runs one worktree + one branch + one PR
   ↓
Task PRs merge, acceptance flips, milestone/phase exit gates pass
   ↓
Promote accepted scope from docs/blueprint/next/ to docs/blueprint/current/
   ↓
Tag the accepted current version (blueprint-vN.M) and mark next ledger rows CURRENT
```

## State ownership

| Artifact | Owns | Does not own |
|---|---|---|
| `docs/blueprint/current/` | Implemented, accepted product truth | Planned or in-progress work |
| `docs/blueprint/next/` | Locked/open blueprint work not yet accepted into current | Task mechanics or PR status |
| `docs/tasks/` | Execution path from next to current | Product stance source of truth |
| GitHub `backlog` issues | Initial selection intake | Ongoing implementation state |

Once a backlog issue is selected, do not use GitHub status labels as the workflow source of truth. Preserve the issue number in `source-issues.md` and in task/PR references, then drive recovery from `docs/blueprint/next/README.md` and `docs/tasks/`.

## Next status ledger

`docs/blueprint/next/README.md` is the first file to read after an interruption:

```markdown
# Blueprint Next State

Target version: vN.M
Last updated: YYYY-MM-DD
Resume from: <one concrete next action>

| Anchor | Topic | Decision | Execution | Plan/task path | PR | Blocker | Next action |
|---|---|---|---|---|---|---|---|
| RA-1 | Web-triggered configure | LOCKED | MILESTONE_PLANNED | docs/tasks/phase-6-remote-agent/milestone-2-web-config | - | none | split milestone task set and start first task |
| RA-2 | Helper sandbox stance | OPEN | NO_PLAN | - | - | sudo boundary | role discussion |
| RA-3 | Helper boot/crash | LOCKED | READY_FOR_IMPL | docs/tasks/phase-6-remote-agent/milestone-3-helper-service/task-1-boot-crash | - | none | create worktree |
| RA-4 | Status and logs UI | LOCKED | IMPLEMENTING | docs/tasks/phase-6-remote-agent/milestone-4-operator-status/task-2-redacted-logs-ui | #812 | none | finish client tests |
| RA-5 | Revoke behavior | LOCKED | ACCEPTING | docs/tasks/phase-6-remote-agent/milestone-5-revoke/task-1-revoke-helper-auth | #816 | QA review | acceptance signoff |
| RA-6 | Configure job API | LOCKED | ACCEPTED | docs/tasks/phase-6-remote-agent/milestone-2-web-config/task-1-configure-job-api | #820 | none | promote to current |
| RA-7 | Legacy helper sandbox | REOPENED | NO_PLAN | - | - | product/security conflict | resolve stance |
| RA-8 | Enrollment status | LOCKED | CURRENT | docs/tasks/archived/task-1-enrollment-status | #801 | none | none |
```

Decision values: `OPEN`, `LOCKED`, `REOPENED`.

Execution values: `NO_PLAN`, `MILESTONE_PLANNED`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, `ACCEPTING`, `ACCEPTED`, `CURRENT`.

## source-issues.md trail

When backlog issues are picked into the next version, list them in `docs/blueprint/_meta/<target-version>/source-issues.md`:

```markdown
# Source issues for blueprint vN.M

The issues this next blueprint draws from (grouped by topic):

## Module X
- gh#123 — title, one sentence on what this version intends to deliver
- gh#125 — title, one sentence on what this version intends to deliver
```

Effects:
- Fork users can trace where this version came from.
- Issues that were not picked are not listed.
- The file is traceability for the selected next work; it does not mean the work is current.

## After lock: trigger Phase planning

When one or more next anchors are `LOCKED`, the Architect runs `bf-phase-plan` to split them into Phase -> Milestone under `docs/tasks/`. This starts execution planning, not current promotion.

Freeze/lock does not require complete task decomposition. The plan must identify milestones, dependencies, acceptance boundaries, and a first-milestone task seed that proves the plan can start. Full task-set split happens when each milestone starts execution; at that point the milestone names its complete task set, and every resulting task is a normal task PR with four-piece/design/review requirements when it starts.

## Promotion to current

Promote only accepted work:
- All relevant task PRs are merged.
- Acceptance templates are ✅ and verifiable.
- Phase or milestone gates required by `docs/tasks` have passed.
- `docs/current` is synced when the project uses that convention.
- User/PM acceptance for user-perceivable behavior is recorded.

Then update `docs/blueprint/current/`, tag `blueprint-vN.M`, and mark the corresponding next ledger rows `CURRENT`.

## Stuck-task safety net

If a task is stuck for >=2 weeks, Architect + PM evaluate whether to split the task, reopen the next anchor, or move the remainder back to a future backlog item. Do not drag the whole milestone or Phase indefinitely.
