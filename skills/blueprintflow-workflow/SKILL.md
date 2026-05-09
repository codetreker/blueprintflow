---
name: blueprintflow-workflow
description: "Part of the Blueprintflow methodology. Use when starting a new product, onboarding a team, or unsure which skill applies - navigates the concept-to-blueprint-to-Phase-to-milestone-to-PR-to-gate lifecycle."
---

# Blueprintflow Workflow

A multi-agent collaboration workflow for **building products**: from a fuzzy concept to shippable software, driven by 6 roles + a Teamlead.

## Mental model: city engineering

This skill set is designed for **large requirements / long-duration projects** — the same shape as how large-scale city engineering works:

| City engineering | Blueprintflow role |
|---|---|
| Chief engineer | Architect — produces blueprints + spec briefs |
| Client | PM — owns stances + constraints |
| Construction crew | Dev — builds to spec, doesn't redraw blueprints |
| Inspector | QA — runs acceptance |
| Designer / safety | Designer / Security (interior / fire safety) |
| General contractor | Teamlead — coordinates, doesn't lay bricks |

Engineering practices map across:
- **Freeze the blueprint before construction starts** — you can't redraw while building; blueprint changes go through PR + 4-role review (= an engineering change order)
- **Phase by value loop** (Phase 0 foundation / Phase 1 main structure / Phase 2 finishing) — not by trade
- **Phase-end signoff** (the 4-role signoff at Phase exit = phase acceptance report + carry-over gate)
- **Quality-gate trail** (rule 6 / migration version sequencing = engineering archive)
- **The client's representative is on site throughout** (PM stance reverse-check = construction can't drift from requirements)

### When this doesn't apply

- Hackathon / one-off script / single-PR fix — blueprint + brainstorm + Phase exit gate is heavyweight infrastructure, short tasks don't need it
- Solo rapid iteration — the 4-piece + dual review path assumes multi-person collaboration
- Exploration phase with no settled stance — first use `blueprintflow:brainstorm` to lock stance, then come back

## When to use

Suitable for:
- A new product / major feature / large refactor starting from concept
- Multi-agent collaboration (≥3 roles), too much for a single agent
- Scenarios where stance / blueprint / execution / acceptance need to run on separate but interlocked tracks
- High demand for cross-milestone drift control (stance can't drift with execution)

Not suitable for:
- Single agent / small task (overhead too heavy)
- Pure bugfix (PR review + standard squash merge is enough; never admin/ruleset bypass)
- Operations / oncall on an existing product

## 4-layer structure

```
┌─ Concept layer (blueprint) ───── blueprintflow:brainstorm + blueprintflow:blueprint-write
│      ↓
├─ Plan layer (Phase split) ───── blueprintflow:phase-plan
│      ↓
├─ Milestone layer (execution) ── blueprintflow:milestone-fourpiece + blueprintflow:pr-review-flow
│      ↓
└─ Coordination layer ─────────── blueprintflow:teamlead-fast-cron-checkin (15 min idle)
                                   blueprintflow:teamlead-slow-cron-checkin (2-4 h audit)
                                   blueprintflow:phase-exit-gate (Phase wrap-up)
```

## 6 roles + Teamlead

| Code | Name | Responsibilities |
|---|---|---|
| **Teamlead** | Coordinator | facilitator: assigns work / supervises / guards protocol; doesn't write code |
| **Architect** | Architect | spec brief / blueprint citations / gate 1+2 (template self-check + grep anchor) / PR architecture review |
| **PM** | Product Manager | stance reverse-check table / content lock / gate 3 reverse-check / gate 4 flagship-milestone signoff |
| **Dev** | Developer | implementation code / migration / unit tests / main worktree (only one in-flight at a time) |
| **QA** | Quality Assurance | acceptance template / E2E + behavior-invariant unit tests / current-sync review / gate 4 acceptance run |
| **Designer** | Designer | UI/UX/visual; spawned when a milestone touches client UI (interlocked with PM content lock) |
| **Security** | Security | reviews auth / privacy / admin god-mode / cross-org paths; spawned when sensitive write actions are involved |

Full role prompt templates in `blueprintflow:team-roles`.

## Stages + skill index

### Stage 0: confirm your runtime
**Goal**: know what your agent environment can and can't do before starting anything else

0. **blueprintflow:runtime-adapter** — read this first. It tells you which communication, scheduling, and display commands to use based on your environment (Claude Code team mode + tmux / team mode without tmux / single session / OpenClaw / Codex / basic). Every later stage assumes you already know your runtime config.

Output: you know your config (team mode? tmux? how to create crons? how to notify roles?)

### Stage 1: concept lock-in
**Goal**: fuzzy idea → core stances + concept model + constraints a blueprint can be built on

1. **blueprintflow:brainstorm** — Teamlead facilitates multi-round discussion (PM + Architect drive), locking stances / concepts / constraints
2. **blueprintflow:blueprint-write** — Architect + PM write `docs/blueprint/*.md`

Output: `docs/blueprint/` ready, concepts frozen, every later PR has to cite §X.Y

### Stage 2: execution plan
**Goal**: blueprint → Phase split + exit gates + 4 drift-prevention gates

3. **blueprintflow:phase-plan** — Architect leads, writes `docs/tasks/README.md` (the milestone index) + execution-plan + Phase exit gates

Output: PROGRESS.md ready, Phase 1/2/3+ split clearly

### Stage 3: milestone execution (the main field)
**Goal**: each milestone = one worktree + one branch + one PR — Teamlead creates the worktree, everyone stacks commits, Teamlead is the only one who opens the PR, Teamlead removes the worktree after merge

4. **blueprintflow:git-workflow** — git protocol: one milestone, one worktree; roles don't open PRs, Teamlead is the sole PR opener
5. **blueprintflow:milestone-fourpiece** — the 4 pieces are stacked as commits in the same worktree by everyone (spec / stance / acceptance / content-lock all in the same PR)
6. **blueprintflow:implementation-design** — after the 4 pieces and before code, Dev writes the implementation design; Architect/PM/Security/QA review and only release to write code once all 4 sign off
7. **blueprintflow:pr-review-flow** — PR (opened by Teamlead) goes through dual review + Security checklist + standard squash merge (never admin/ruleset bypass)
8. **blueprintflow:e2e-verification** — for any client-facing UI / frontend change, QA's signoff inside `pr-review-flow` walks the three lines (code-level acceptance + product usability + design reasonableness) before LGTM

Output: every milestone merged + acceptance template ⚪→🟢 flipped + REG-* registered

### Stage 4: ongoing push + Phase exit
**Goal**: idle dispatch + drift correction + issue triage + Phase exit gate

9. **blueprintflow:teamlead-fast-cron-checkin** — 15-min cron, dispatches work to idle roles (PR dimension)
10. **blueprintflow:teamlead-slow-cron-checkin** — 2-4 h cron, drift audit (blueprint-drift dimension)
11. **blueprintflow:issue-triage** — 3 h cron, scans GitHub issues; Teamlead first-call-and-route to Architect/PM/QA (issue dimension, parallel and non-overlapping with fast/slow cron)
12. **blueprintflow:phase-exit-gate** — Phase wrap-up four-role signoff + closure announcement

### Stage 5: blueprint iteration (after all Phases pass)
**Goal**: current blueprint accepted → evolve to the next blueprint version (3-state machine + version-number management)

13. **blueprintflow:blueprint-iteration** — 3-state machine (current/next/GitHub issues backlog) + major/minor version numbers + change routing (real bug into current patch / non-bug into backlog) + freeze + tag cutover

Output: new blueprint version frozen + old version git-tagged for history + source-issues.md to record provenance

## Team startup layout

How you lay out the team on screen depends on your runtime. See `blueprintflow-runtime-adapter` for concrete commands (tmux pane layout, display mode settings, etc.).

General principle: Teamlead gets the biggest field of view (coordination thread), roles are visible at a glance, and every pane/window is named so you can tell who's who.

### Layout anti-patterns

- ❌ All roles in one flat row (too narrow to read)
- ❌ Teamlead crammed into the same row as roles (coordination thread gets drowned)
- ❌ Unnamed panes/windows (can't tell who's who)
- ❌ One window per role with no overview (slow to switch, can't see the full picture)

## Key protocols

- **Git workflow** (see `blueprintflow-git-workflow`): Teamlead is the sole creator of `.worktrees/<milestone>` + branch `feat/<milestone>`. Everyone stacks commits in the same worktree. **Roles don't open PRs; Teamlead is the sole PR opener.** After merge, Teamlead removes the worktree.
- **One milestone, one PR**: 4 pieces + three execution segments + e2e + docs/current sync + REG flip + acceptance ⚪→✅ + PROGRESS [x] **all in the same PR**. No splitting into multiple PRs. No closure follow-up.
- **PR merge never admin-bypasses / never disables ruleset** (hard red line, see pr-review-flow): CI must really pass, flaky tests get fixed not skipped (PR template lint false positives / e2e flakiness / coverage thresholds — fix them, don't skip them)
- **PR template top: 4 lines of bare metadata**: `Blueprint: §X.Y` / `Touches:` / `Current sync:` / `Stage: v0|v1` (or h2-section style)
- **Migration version numbers issued in series** (where applicable): grep before allocating
- **Rule 6 (current sync)**: code change → `docs/current` must sync; PR-level lint enforces it
- **5 layers of stance-drift defense**: spec grep + acceptance reverse-check anchor + stance blacklist + content-lock byte-identical + PR cross-file cross-check
- **author=lead-agent can't self-approve**: use `gh pr comment <num> --body "LGTM"` as approval

## Anti-patterns

- ❌ Skipping the 4 pieces and going straight into execution (stance drift can't be caught)
- ❌ One role running multiple milestones in parallel (worktree conflict)
- ❌ Treating audit as forward motion (audit + dispatch is forward motion)
- ❌ **Any form of admin merge / ruleset disable / bypassing required CI** (permanent ban, no "temporary" or "fallback" excuses)
- ❌ Idle without dispatch (cron must ACT)

## Bootstrap

```
0. blueprintflow:runtime-adapter  — confirm environment config (team mode? tmux? cron commands?)
1. blueprintflow:team-roles      — spawn 6 roles (as needed)
2. blueprintflow:brainstorm      — lock concepts + stances
3. blueprintflow:blueprint-write — write the blueprint
4. blueprintflow:phase-plan      — split into Phases
5. (loop) blueprintflow:milestone-fourpiece + blueprintflow:pr-review-flow + blueprintflow:teamlead-fast-cron-checkin
6. (periodic) blueprintflow:teamlead-role-reminder
7. (periodic) blueprintflow:teamlead-slow-cron-checkin
8. (periodic) blueprintflow:issue-triage
9. (Phase wrap-up) blueprintflow:phase-exit-gate
```

## Activation protocol (cron required)

**When workflow activates, Teamlead must start all four crons**:

```
Start checkin (specific commands in the blueprintflow-runtime-adapter table):
  Frequency: every 15 minutes
  Body: "[auto check-in · 15 min] follow skill blueprintflow-teamlead-fast-cron-checkin"

Start checkin (specific commands in the blueprintflow-runtime-adapter table):
  Frequency: every 30 minutes
  Body: see blueprintflow-teamlead-role-reminder SKILL.md for the <system reminder> block

Start checkin (specific commands in the blueprintflow-runtime-adapter table):
  Frequency: every 2 hours
  Body: "[drift audit · 2 hours] follow skill blueprintflow-teamlead-slow-cron-checkin"

Start checkin (specific commands in the blueprintflow-runtime-adapter table):
  Frequency: every 3 hours
  Body: "[issue triage · 3h] follow skill blueprintflow-issue-triage"
```

**Why required**:
- Agents don't clock in; **without a cron prod, they go idle**. Active-check frequency on long projects drops to 0.
- Under large requirements and long durations, no proactive dispatch = invisible delay (when the user asks "why did this stop?", that's this trigger firing)
- Fast cron handles dispatch + merge gates; role-reminder catches Teamlead drift; slow cron audits blueprint consistency; issue-triage scans the backlog — the four rails cover everything

**Stopping**:
- When the workflow session ends, crons should stop automatically (non-persistent by default)
- Need to pause checkin (e.g. don't dispatch during brainstorm) → explicitly remove the cron jobs; don't let them dispatch blindly

**Anti-patterns**:
- ❌ Starting only fast cron and not the others → long-term drift accumulates, Teamlead drifts into doing work, issues pile up
- ❌ Starting fast + slow but not issue-triage → GitHub issues pile up untriaged, blueprint-iteration state machine starves
- ❌ Skipping role-reminder → Teamlead unconsciously starts doing Dev/QA work, blocks on subagents
- ❌ Starting cron but the prompt doesn't cite `blueprintflow:teamlead-{fast,slow}-cron-checkin` → cron behavior uncontrolled
- ❌ Making crons persist across sessions without user signoff → leaks into the wrong project

## Cross-project use

It's named `blueprintflow:` but the workflow is general:
- Role names default to English (Architect/PM/Dev/QA/Designer/Security); custom aliases allowed
- Path / doc structure (`docs/blueprint/`, `docs/tasks/<m>/`) is a convention; projects may adjust via AGENTS.md / CLAUDE.md
- worktree / migration / lint protocols are core; don't change them
