# Issue triage execution logic

GitHub issues are the intake SSOT. This skill defines the gate: cron scans → Teamlead routes → roles classify → issue becomes either an immediate task candidate or a backlog candidate.

Runs in parallel to fast-cron (PR dimension) and slow-cron (drift dimension) — this is the **issue dimension**.

Before routing issue work, read the Teamlead notebook at `~/.blueprint/<repo-dir>/teamlead.md` using `using-plueprint/references/teamlead-notebook.md`. After assigning role follow-up, dispatching a patch milestone, or flagging a stuck issue, update the notebook in the same turn.

## Sections

| Section | Use |
|---|---|
| Native issue type field | Read/set Bug, Feature, Task |
| User review queue | Handle triaged issues without a type |
| Labels | Apply intake labels |
| Routing matrix | Assign Architect/PM/QA/Dev follow-up |
| Execution flow | Run the cron triage loop |
| Anti-patterns | Avoid label-only or speculative routing |

## Native issue type field

Use GitHub's built-in issue type (Bug / Feature / Task), not `type:*` labels.

| Action | Command |
|---|---|
| Set type | `gh api graphql -f query='mutation { updateIssueIssueType(input: {issueId: "ID", issueTypeId: "TID"}) { issue { number } } }'` |
| Read type | `gh api /repos/<o>/<r>/issues/<n> --jq '.type.name'` |
| List type IDs | `gh api graphql -f query='query { repository(owner: "<o>", name: "<r>") { issueTypes(first: 20) { nodes { id name } } } }'` |
| List "triaged no type" | GraphQL query filtering `issueType == null` on `triaged` label (see below) |

- Tech-debt → **Task**
- Unclear → don't set type, only `triaged` label. User reviews periodically
- `gh issue list --json type` is NOT supported — use GraphQL

```bash
# "Triaged but no native type" queue
gh api graphql -f query='query($owner:String!, $repo:String!) { repository(owner:$owner, name:$repo) { issues(first:100, states:OPEN, filterBy:{labels:["triaged"]}) { nodes { number title issueType { name } } } } }' -f owner=<o> -f repo=<r> \
  | jq '[.data.repository.issues.nodes[] | select(.issueType == null)]'
```

If native types not enabled → ask user/org admin to enable. Don't fall back to labels.

## User review queue

"Triaged but no type" issues accumulate. Slow-cron audits queue size (threshold default 5). User review cadence is project-defined or when flagged.

```yaml
# AGENTS.md override
issue-triage:
  triaged-no-type-threshold: 5
  triaged-no-type-review: <project cadence>
  untriaged-stuck-threshold: <project threshold>
```

## Routing table

| Issue character | Routed to | What they check |
|---|---|---|
| Code improvement / tech-debt | Architect | Bug vs stance reversal vs backlog |
| New feature | PM | Product stance / user value / blueprint coverage |
| Bug | QA | Reproduction / trigger / blast radius |
| Unclear | `triaged` only | User reviews periodically |

After triage, apply: **native type** + **intake label** + **priority label** (if used) + **`triaged` label**.

## Intake labels

| Label | Meaning |
|---|---|
| `backlog` | Unplanned, waiting for next selection discussion |
| `archived` | Kept for history |
| `wont-fix` | Decided not to do, closed |

**Priority** (project-optional): `p0-blocker` / `p1-high` / `p2-normal` / `p3-low`

## Scan scope

- All open issues without `triaged` label (including "triaged no type" — those are in user queue, cron skips them)
- Skip `wont-fix` / `archived`

```bash
gh issue list --state open --json number,title,labels,body --limit 1000 \
  | jq '[.[] | select((.labels | map(.name) | index("triaged")) | not)]'
```

## The `triaged` label

Ops label (separate dimension from status/priority). Applied after triage finishes. Usually never removed — only if a user follow-up changes the request.

## Post-triage routing

```
issue triaged → routing:
  ├── Bug + current implemented blueprint covers it → immediate task candidate + `Closes gh#NNN`
  ├── Feature / Task → `backlog`
  └── no type (only `triaged`) → user review queue
```

When next selection opens, scan all `backlog` issues once:
- Pulled in → list the issue in `docs/blueprint/_meta/<target-version>/source-issues.md` and create/update `docs/blueprint/next/` anchors
- Rejected → `wont-fix` + close
- Kept → keep `backlog`, update body with "why still kept"

After an issue is selected, do not use GitHub labels as the ongoing lifecycle state. Recovery and execution state live in `docs/blueprint/next/README.md` and `docs/tasks/`.

### Backlog issue body requirements

Every backlog issue must contain:
- **Source**: who proposed / which PR # / which discussion
- **Why here**: why not a bug — new stance / module / low priority / unsure
- **Out of scope**: boundary against current implemented behavior

### Backlog constraints

- Every backlog issue explains "why it goes here" — title-only is an anti-pattern
- No automatic cleanup — manual scan every time next selection opens
- Bugfix issues must link `Closes gh#NNN` (bidirectional traceability)

issue-triage owns the **entry gate**; `bf-blueprint-iteration` owns selection, next status tracking, execution planning, acceptance promotion, tags, and `source-issues.md`.

## Triage flow example

| Time | Event | Action |
|---|---|---|
| T+0 | User opens "login logo 5px off-center" | — |
| next triage tick | Cron fires, Teamlead scans | UI bug → route to QA |
| after QA review | QA reproduces | Type: Bug, labels: `p2-normal` + `triaged`. Dispatch a patch task linked with `Closes gh#NNN` |
| next triage tick | User opens "collaborative multi-device sync" | — |
| after PM review | PM reviews | New module, not in blueprint. Type: Feature, labels: `backlog` + `p1-high` + `triaged` |

## Cron config

Set cadence and thresholds in `AGENTS.md`:
```yaml
issue-triage:
  cron: <project cadence>
  scope: open-only
  untriaged-stuck-threshold: <project threshold>
```

## Boundaries

| Skill | Dimension | Frequency |
|---|---|---|
| fast-cron | PR | project-defined |
| slow-cron | Drift | project-defined |
| issue-triage | Issue | project-defined |

Three independent, no overlap.

## Anti-patterns

- ❌ Teamlead classifying instead of routing
- ❌ Roles stepping into others' lanes
- ❌ Forgetting `triaged` label (cron rescans)
- ❌ Using `type:*` labels instead of native type (deprecated)
- ❌ Closing without reason (use `wont-fix` + one-liner)
- ❌ Triage done for a covered bug but no task dispatched / no `Closes gh#NNN`
- ❌ Dumping all issues onto one role
- ❌ Treating `current-iteration` / `next-iteration` issue labels as the workflow state after selection
- ❌ Backlog in repo docs instead of GitHub issues (anti-fork-friendly, upstream noise follows the fork)
- ❌ Auto-cleaning backlog issues (cleanup happens during human discussion only)
- ❌ Treating "new stance" as "bug" and bypassing next selection (default is backlog, burden of proof on "this is a bug")

## Report format

- Has untriaged: `[issue-triage] N open, M untriaged routed: X→Architect / Y→PM / Z→QA`
- All triaged: `[issue-triage] N open, all triaged`
- Stuck: `[issue-triage] N open, M untriaged past triage threshold → dispatch Teamlead`
- Confirm the notebook was reconciled and updated, or state why no notebook change was needed.
