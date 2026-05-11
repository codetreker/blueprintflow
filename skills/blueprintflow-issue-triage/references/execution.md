# Issue triage execution logic

GitHub issues are the backlog SSOT. This skill defines the gate: cron scans → Teamlead routes → roles classify → state machine routing.

Runs in parallel to fast-cron (PR dimension) and slow-cron (drift dimension) — this is the **issue dimension**.

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

"Triaged but no type" issues accumulate. Slow-cron audits queue size (threshold default 5). User cadence: weekly or when flagged.

```yaml
# AGENTS.md override
issue-triage:
  triaged-no-type-threshold: 5
  triaged-no-type-review: weekly
```

## Routing table

| Issue character | Routed to | What they check |
|---|---|---|
| Code improvement / tech-debt | Architect | Bug vs stance reversal vs backlog |
| New feature | PM | Product stance / user value / blueprint coverage |
| Bug | QA | Reproduction / trigger / blast radius |
| Unclear | `triaged` only | User reviews periodically |

After triage, apply: **native type** + **status label** + **priority label** (if used) + **`triaged` label**.

## Status labels

| Label | Meaning |
|---|---|
| `backlog` | Unplanned, waiting for next-version discussion |
| `current-iteration` | Pulled into current iteration (bugfix / patch) |
| `next-iteration` | Pulled into next-version blueprint |
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
  ├── Bug + current blueprint covers it → `current-iteration` + patch milestone
  ├── Feature / Task → `backlog`
  └── no type (only `triaged`) → user review queue
```

When next-version discussion opens, scan all `backlog` issues:
- Pulled in → `backlog` → `next-iteration`
- Rejected → `wont-fix` + close
- Kept → keep `backlog`, update body with "why still kept"

### Backlog issue body requirements

Every backlog issue must contain:
- **Source**: who proposed / which PR # / which discussion
- **Why here**: why not a bug — new stance / module / low priority / unsure
- **Out of scope**: boundary against current iteration

### Backlog constraints

- Every backlog issue explains "why it goes here" — title-only is an anti-pattern
- No automatic cleanup — manual scan every time next-version discussion opens
- Bugfix issues must link `Closes gh#NNN` (bidirectional traceability)

issue-triage owns the **entry gate**; `blueprint-iteration` owns the **downstream lifecycle** (freeze / tag / source-issues.md).

## Triage flow example

| Time | Event | Action |
|---|---|---|
| T+0 | User opens "login logo 5px off-center" | — |
| T+1h | Cron fires, Teamlead scans | UI bug → route to QA |
| T+1h05 | QA reproduces | Type: Bug, labels: `current-iteration` + `p2-normal` + `triaged`. Dispatch patch milestone |
| T+1h | User opens "collaborative multi-device sync" | — |
| T+1h10 | PM reviews | New module, not in blueprint. Type: Feature, labels: `backlog` + `p1-high` + `triaged` |

## Cron config

Default 3h. Override in AGENTS.md:
```yaml
issue-triage:
  cron: 3h
  scope: open-only
```

## Boundaries

| Skill | Dimension | Frequency |
|---|---|---|
| fast-cron | PR | 15m |
| slow-cron | Drift | 2-4h |
| issue-triage | Issue | 3h |

Three independent, no overlap.

## Anti-patterns

- ❌ Teamlead classifying instead of routing
- ❌ Roles stepping into others' lanes
- ❌ Forgetting `triaged` label (cron rescans)
- ❌ Using `type:*` labels instead of native type (deprecated)
- ❌ Closing without reason (use `wont-fix` + one-liner)
- ❌ Triage done but no milestone dispatched / no `Closes gh#NNN`
- ❌ Dumping all issues onto one role
- ❌ `current-iteration` issue with no milestone after triage (means "now", not "park")
- ❌ Backlog in repo docs instead of GitHub issues (anti-fork-friendly, upstream noise follows the fork)
- ❌ Auto-cleaning backlog issues (cleanup happens during human discussion only)
- ❌ Treating "new stance" as "bug" and stuffing it into current iteration (default is backlog, burden of proof on "this is a bug")

## Report format

- Has untriaged: `[issue-triage] N open, M untriaged routed: X→Architect / Y→PM / Z→QA`
- All triaged: `[issue-triage] N open, all triaged`
- Stuck: `[issue-triage] N open, M untriaged ≥24h → dispatch Teamlead`
