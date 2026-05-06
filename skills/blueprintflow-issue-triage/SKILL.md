---
name: blueprintflow-issue-triage
description: "A scheduled scan over GitHub issues. Teamlead first decides where each one goes — to Architect / PM / QA — and those roles do the triage (apply type / status labels + assign a milestone). This is the entry gate of the blueprint-iteration state machine. Use this skill whenever a cron interval triggers, a new issue arrives unclassified, or a user request lands as an issue. Don't use on issues that already have the `triaged` label, on closed issues (wont-fix / archived), on `type:question` issues waiting on the user, or for PR-level blockers (use fast-cron / slow-cron)."
version: 1.0.0
---

# Issue Triage

GitHub issues are the backlog SSOT (see `blueprintflow-blueprint-iteration`), but new issues don't classify themselves. This skill defines the gate where cron scans for issues, the Teamlead decides routing, and roles classify them.

It runs in parallel to and doesn't overlap with `blueprintflow-teamlead-fast-cron-checkin` (PR dimension) or `blueprintflow-teamlead-slow-cron-checkin` (blueprint-drift audit dimension) — issue-triage is the **issue dimension**.

## Responsibility

Scan all open GitHub issues, find the untriaged ones (those without the `triaged` label), and have the Teamlead look first to decide routing:

| Issue character | Routed to | What they look at |
|---|---|---|
| Code improvement / tech-debt | Architect | Architect decides if it's a bug / stance reversal / add to backlog |
| New feature | PM | Product stance review / user value / blueprint coverage |
| Bug | QA | Reproduction / trigger conditions / blast radius |
| Unclear | Escalate to user + label `type:question` | — |

After the three roles finish triaging:
- Apply `type:*` (bug / feature / question / tech-debt)
- Apply a **status** label (`backlog` / `current-iteration` / `next-iteration` / `wont-fix` / `archived`)
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
- **Skip ones already labeled `triaged`** (avoid wasted re-triage)
- Skip ones closed with `wont-fix` / `archived` (already settled)
- Skip `type:question` ones waiting on user reply (avoid scanning over and over until the user replies)

GitHub CLI example:

```bash
gh issue list --state open --json number,title,labels,body --limit 1000 \
  | jq '[.[] | select((.labels | map(.name) | index("triaged")) | not)
                    | select((.labels | map(.name) | index("type:question")) | not)]'
```

## Introducing the `triaged` label

This is a new **ops label**, on a different dimension than `type:*` / status / priority.

- Meaning: this issue has been seen and classified by Teamlead + Architect/PM/QA, no need to triage it again
- When to apply: after the three roles finish triaging, alongside the type + status labels
- When to remove: usually never. If an issue genuinely needs to be re-triaged (e.g. a user follow-up changed the request), remove `triaged` so the next cron picks it up

**Anti-constraint**: after triage finishes, `triaged` must be applied; otherwise the next cron rescans the same issue and wastes context.

## Triage flow example

```
[T+0] User opens issue: "login page logo is 5px off-center"
       label: (none)

[T+1h] Cron triggers, Teamlead scans open issues
       → Sees this issue, no triaged label, in untriaged list
       → Teamlead decides: this is a UI bug → routed to QA

[T+1h05] QA reproduces + assesses blast radius
       → applies labels: type:bug, current-iteration, p2-normal, triaged
       → dispatches a patch milestone (issue link in PR via Closes gh#NNN)

[T+1h] Another issue: "I want collaborative real-time multi-device sync"
       → Teamlead decides: large feature → routed to PM

[T+1h10] PM reviews the product stance
       → Current blueprint version doesn't have this module; high value but needs stance discussion
       → applies labels: type:feature, backlog, p1-high, triaged
       → body addendum: "why this lands here: new module, defer to next-version discussion"
```

## Report format (consistent with fast/slow cron)

Short-line style:

- Has untriaged: `[issue-triage cron] N open issues, M untriaged routed: X→Architect / Y→PM / Z→QA, no hard blocker`
- All triaged: `[issue-triage cron] N open issues, all triaged, no hard blocker`
- Stuck: `[issue-triage cron] N open issues, M untriaged, K of them ≥24h unrouted → dispatch Teamlead to handle`

## State transitions (refer to blueprint-iteration)

After triage, the flow continues per `blueprintflow-blueprint-iteration`'s state machine:

- `type:bug` + covered by current blueprint → `current-iteration` + dispatch a patch / bugfix milestone (link the issue via `Closes gh#NNN`)
- `type:feature` / `type:tech-debt` → `backlog`, wait for next-version discussion
- Unclear → label `type:question`, escalate to Teamlead + user decision

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
- ❌ Closing the issue during triage without a reason (apply `wont-fix` or `archived` and put a one-liner in the body for "why we won't do it")
- ❌ Triage finishes but no milestone dispatched / no `Closes gh#NNN` linked (current-iteration issue disconnected from PR)
- ❌ Cron fires and dumps every untriaged issue onto a single role (route by character — don't slice it all one way)

## How to invoke

Cron prompt:

```
[issue triage · 3h]
follow skill blueprintflow-issue-triage
```

Inline trigger when a new issue arrives (outside cron):

```
new issue gh#NNN arrived
follow skill blueprintflow-issue-triage
Teamlead decides → route → role classifies → apply triaged
```
