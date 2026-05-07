---
name: blueprintflow-issue-triage
description: "Part of the Blueprintflow methodology. Use on cron tick or when new untriaged GitHub issues arrive - Teamlead routes each to Architect/PM/QA, who set the issue's native type field + apply status/triaged labels as the entry gate to blueprint iteration."
---

# Issue Triage

GitHub issues are the backlog SSOT (see `blueprintflow-blueprint-iteration`), but new issues don't classify themselves. This skill defines the gate where cron scans for issues, the Teamlead decides routing, and roles classify them.

It runs in parallel to and doesn't overlap with `blueprintflow-teamlead-fast-cron-checkin` (PR dimension) or `blueprintflow-teamlead-slow-cron-checkin` (blueprint-drift audit dimension) — issue-triage is the **issue dimension**.

## Use the GitHub native issue type field, not labels

GitHub repositories have a built-in **issue type** field (Bug / Feature / Task, plus any custom types defined at the org level). This skill uses the **native type field**, not `type:*` labels.

- Set type via GraphQL `updateIssueIssueType` mutation (`gh api graphql -f query='mutation { updateIssueIssueType(input: {issueId: "ID", issueTypeId: "TID"}) { issue { number } } }'`)
- Tech-debt issues → use **Task** (the native "specific piece of work" type fits this category)
- Unclear issues (need user clarification) → **don't set a type**, only apply the `triaged` label. The user periodically reviews "triaged but no native type" issues to decide
- The native type renders in the issue header (with an icon) and is queryable via GraphQL filters; labels are not the right tool for this taxonomy

Reading the type:
```bash
gh api /repos/<o>/<r>/issues/<n> --jq '.type.name'
```

Listing the type IDs available in your repo:
```bash
gh api graphql -f query='query { repository(owner: "<o>", name: "<r>") { issueTypes(first: 20) { nodes { id name } } } }'
```

Listing "triaged but no native type" issues (the user's review queue — see "User review queue" below for cadence):

`gh issue list --json type` is **not** supported (the CLI only exposes a fixed set of fields and `type` is not one of them). Use GraphQL instead:

```bash
gh api graphql -f query='query($owner:String!, $repo:String!) { repository(owner:$owner, name:$repo) { issues(first:100, states:OPEN, filterBy:{labels:["triaged"]}) { nodes { number title issueType { name } } } } }' -f owner=<o> -f repo=<r> \
  | jq '[.data.repository.issues.nodes[] | select(.issueType == null)]'
```

If the repo has not enabled native issue types, ask the user / org admin to enable them before running triage. Don't fall back to `type:*` labels.

## User review queue ("triaged but no native type")

When a triager can't classify an issue (genuinely unclear whether Bug / Feature / Task), the rule is: **apply `triaged` only, don't set a type, don't set a status**. These accumulate into a queue that the user reviews manually.

To prevent this queue from growing unchecked:

- The **slow-cron audit** (`blueprintflow-teamlead-slow-cron-checkin`) includes a check for the size of this queue. If it exceeds a project-defined threshold (default 5), the cron flags it in the report so the user knows to review.
- The user's expected cadence is **whenever the slow-cron flags it, or weekly review at minimum** — projects can override via `AGENTS.md`:
  ```yaml
  issue-triage:
    triaged-no-type-threshold: 5      # flag in slow-cron when queue exceeds this
    triaged-no-type-review: weekly    # expected user review cadence
  ```
- When the user reviews, they either set the native type (which moves the issue into the regular routing flow) or close it as `wont-fix` if it's not actionable.

## Responsibility

Scan all open GitHub issues, find the untriaged ones (those without the `triaged` label), and have the Teamlead look first to decide routing:

| Issue character | Routed to | What they look at |
|---|---|---|
| Code improvement / tech-debt | Architect | Architect decides if it's a bug / stance reversal / add to backlog |
| New feature | PM | Product stance review / user value / blueprint coverage |
| Bug | QA | Reproduction / trigger conditions / blast radius |
| Unclear | Apply `triaged` only (no native type) — user reviews these periodically | — |

After the three roles finish triaging:
- Set the **native issue type** (Bug / Feature / Task)
- Apply a **status** label (`backlog` / `current-iteration` / `next-iteration` / `wont-fix` / `archived`)
- Apply a **priority** label if the project uses them (`p0-blocker` / `p1-high` / `p2-normal` / `p3-low`)
- Apply the `triaged` label to mark it processed

## Cron config

**Default frequency**: 3h (consistent with the system — fast-cron 15m / slow-cron 2-4h. Issue inflow is slower than PR flow, so 3h is enough)

**AGENTS.md can override**:

```yaml
issue-triage:
  cron: 3h           # default 3 hours, project can change
  scope: open-only   # only scan open issues
```

## Scan scope

- All open issues
- **Skip ones already labeled `triaged`** (avoid wasted re-triage). This includes "triaged but no native type" — those are in the user's manual review queue, the cron should not touch them again
- Skip ones closed with `wont-fix` / `archived` (already settled)

GitHub CLI example:

```bash
gh issue list --state open --json number,title,labels,body --limit 1000 \
  | jq '[.[] | select((.labels | map(.name) | index("triaged")) | not)]'
```

## Introducing the `triaged` label

This is an **ops label**, on a different dimension than status / priority.

- Meaning: this issue has been seen and classified by Teamlead + Architect/PM/QA, no need to triage it again
- When to apply: after the three roles finish triaging, alongside setting the native type + status + priority
- When to remove: usually never. If an issue genuinely needs to be re-triaged (e.g. a user follow-up changed the request), remove `triaged` so the next cron picks it up

**Anti-constraint**: after triage finishes, `triaged` must be applied; otherwise the next cron rescans the same issue and wastes context.

## Triage flow example

```
[T+0] User opens issue: "login page logo is 5px off-center"
       native type: (none), labels: (none)

[T+1h] Cron triggers, Teamlead scans open issues
       → Sees this issue, no triaged label, in untriaged list
       → Teamlead decides: this is a UI bug → routed to QA

[T+1h05] QA reproduces + assesses blast radius
       → sets native type: Bug
       → applies labels: current-iteration, p2-normal, triaged
       → dispatches a patch milestone (issue link in PR via Closes gh#NNN)

[T+1h] Another issue: "I want collaborative real-time multi-device sync"
       → Teamlead decides: large feature → routed to PM

[T+1h10] PM reviews the product stance
       → Current blueprint version doesn't have this module; high value but needs stance discussion
       → sets native type: Feature
       → applies labels: backlog, p1-high, triaged
       → body addendum: "why this lands here: new module, defer to next-version discussion"
```

## Report format (consistent with fast/slow cron)

Short-line style:

- Has untriaged: `[issue-triage cron] N open issues, M untriaged routed: X→Architect / Y→PM / Z→QA, no hard blocker`
- All triaged: `[issue-triage cron] N open issues, all triaged, no hard blocker`
- Stuck: `[issue-triage cron] N open issues, M untriaged, K of them ≥24h unrouted → dispatch Teamlead to handle`

## State transitions (refer to blueprint-iteration)

After triage, the flow continues per `blueprintflow-blueprint-iteration`'s state machine:

- Native type **Bug** + covered by current blueprint → `current-iteration` + dispatch a patch / bugfix milestone (link the issue via `Closes gh#NNN`)
- Native type **Feature** or **Task** (tech-debt) → `backlog`, wait for next-version discussion
- Unclear → apply `triaged` only (no native type, no status). The user reviews these periodically and decides type + routing manually

issue-triage owns the **entry gate (Teamlead routing + role classification)**; blueprint-iteration owns the **downstream state machine (transitions / picking into the next version / freeze)**.

## Boundaries with other cron skills

| skill | Dimension | Frequency | What it does |
|---|---|---|---|
| `teamlead-fast-cron-checkin` | PR | 15m | Dispatch idle roles + scan for PR blockers |
| `teamlead-slow-cron-checkin` | Blueprint drift / doc consistency | 2-4h | Drift audit + correcting late status flips |
| `issue-triage` (this skill) | issue | 3h | Scan untriaged + Teamlead routing + role classification |

Three independent, no overlap.

## Anti-patterns

- ❌ Teamlead triaging themselves instead of routing (the user's call: Teamlead routes, doesn't classify — consistent with the team-roles "coordinate, don't do" stance)
- ❌ Architect / PM / QA stepping into someone else's lane (code improvement to PM / new feature to QA / bug to Architect)
- ❌ Forgetting the `triaged` label after triage (cron will rescan the same issue and waste context)
- ❌ Using `type:bug` / `type:feature` / `type:tech-debt` / `type:question` labels instead of the native type field (deprecated — labels duplicate the native taxonomy and don't get the rendering / filtering support GitHub provides)
- ❌ Closing the issue during triage without a reason (apply `wont-fix` or `archived` and put a one-liner in the body for "why we won't do it")
- ❌ Triage finishes but no milestone dispatched / no `Closes gh#NNN` linked (current-iteration issue disconnected from PR)
- ❌ Cron fires and dumps every untriaged issue onto a single role (route by character — don't slice it all one way)
- ❌ A current-iteration issue triaged but no milestone dispatched after the triage cron — current-iteration means "execute now", not "park" (the next fast-cron should pick it up; if it doesn't, Teamlead unblocks it)

## How to invoke

Cron prompt body (kept short — Teamlead reads this skill, not an inline copy):

```
[issue-triage · 3 h] You are Teamlead. Coordinate, don't classify yourself. Read blueprintflow-issue-triage, dispatch a general-purpose subagent (run_in_background: true) to scan untriaged GitHub issues. Subagent returns the routing list (which issue → Architect / PM / QA); you SendMessage the routing decisions to those roles.
```

Inline trigger when a new issue arrives (outside cron):

```
new issue gh#NNN arrived
follow skill blueprintflow-issue-triage
Teamlead decides → route → role classifies → set native type + apply triaged
```

**Why short + subagent**: same reasoning as fast-cron — the scan (`gh issue list` + filter untriaged) is read-only inspection that fits a `run_in_background: true` subagent. Teamlead's job is **routing the result**, not running the scan in the main context. The self-reminder "coordinate, don't classify yourself" guards against the most common drift: Teamlead seeing one untriaged issue and reflexively classifying it instead of routing to the right role.
