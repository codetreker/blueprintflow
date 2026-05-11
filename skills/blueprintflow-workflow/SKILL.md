---
name: blueprintflow-workflow
description: "Part of the Blueprintflow methodology. Use when starting a new product, onboarding a team, or unsure which skill applies - navigates the concept-to-blueprint-to-Phase-to-milestone-to-PR-to-gate lifecycle."
---

# Blueprintflow Workflow

Multi-agent collaboration for building products: concept → blueprint → Phase → milestone → PR → gate, driven by 6 roles + Teamlead.

## Mental model

| City engineering | Blueprintflow |
|---|---|
| Chief engineer | Architect — blueprints + spec briefs |
| Client | PM — stances + constraints |
| Construction crew | Dev — builds to spec |
| Inspector | QA — acceptance |
| Designer / safety | Designer / Security |
| General contractor | Teamlead — coordinates, doesn't build |

Core principle: **freeze the blueprint before building**. Changes go through PR + 4-role review (= engineering change order).

Engineering practices that map across:
- **Phase by value loop** (foundation / main structure / finishing) — not by technical layer
- **Phase-end signoff** (4-role signoff = acceptance report + carry-over gate)
- **Quality-gate trail** (rule 6 / migration versioning = engineering archive)
- **PM on site throughout** (stance reverse-check = construction can't drift from requirements)

### When to use

- New product / major feature / large refactor starting from concept
- Multi-agent collaboration (≥3 roles)
- Stance / blueprint / execution / acceptance on separate but interlocked tracks
- High demand for cross-milestone drift control

### When this doesn't apply

- Hackathon / one-off script / single-PR fix — too heavyweight
- Solo rapid iteration — assumes multi-person collaboration
- No settled stance yet — use `blueprintflow:brainstorm` first

## 4-layer structure

```
Concept layer ──── brainstorm + blueprint-write
    ↓
Plan layer ─────── phase-plan
    ↓
Milestone layer ── milestone-fourpiece + pr-review-flow
    ↓
Coordination ───── fast-cron (15 min) + role-reminder (30 min)
                   slow-cron (2-4 h) + issue-triage (3 h)
                   phase-exit-gate
```

## 6 roles + Teamlead

| Role | Responsibilities |
|---|---|
| **Teamlead** | Coordinates, assigns work, guards protocol. Doesn't write code |
| **Architect** | Spec brief, blueprint citations, gates 1+2, PR architecture review |
| **PM** | Stance reverse-check, content lock, gates 3+4 |
| **Dev** | Implementation, migration, unit tests |
| **QA** | Acceptance template, E2E tests, current-sync review, gate 4 |
| **Designer** | UI/UX/visual (when milestone touches client UI) |
| **Security** | Auth/privacy/admin/cross-org review (mandatory independent role) |

Full prompts: `blueprintflow:team-roles`

## Stages

### Stage 0: runtime
Read `blueprintflow:runtime-adapter` first — confirms your environment (team mode, crons, messaging).

### Stage 1: concept
1. `brainstorm` — lock stances + concept model
2. `blueprint-write` — write `docs/blueprint/*.md`

### Stage 2: plan
3. `phase-plan` — split blueprint into Phases, write `docs/tasks/README.md`

### Stage 3: execution
4. `git-workflow` — one milestone = one worktree + one branch + one PR
5. `milestone-fourpiece` — 4 baseline docs in the same PR
6. `implementation-design` — Dev writes design, 4-role review before coding
7. `pr-review-flow` — dual review + Security checklist + squash merge
8. `e2e-verification` — QA walks 3 lines for UI changes

### Stage 4: coordination + Phase exit
9. `teamlead-fast-cron-checkin` — 15 min, idle dispatch + merge gate
10. `teamlead-slow-cron-checkin` — 2-4 h, drift audit
11. `issue-triage` — 3 h, GitHub issue scan
12. `phase-exit-gate` — 4-role signoff + closure

### Stage 5: iteration
13. `blueprint-iteration` — 3-state machine, version management, change routing

## Key protocols

- **One milestone, one PR** — 4 pieces + implementation + e2e + closure all in one PR. No splitting
- **Teamlead is the sole PR opener** — roles commit to the worktree, Teamlead opens the PR
- **Never admin-bypass merge / disable ruleset** — CI must really pass
- **Rule 6 (current sync)** — code change → `docs/current` must sync
- **5-layer stance-drift defense** — spec grep + acceptance anchor + stance blacklist + content-lock byte-identical + cross-file cross-check
- **No self-approve** — `gh pr comment <num> --body "LGTM"`

## Anti-patterns

- ❌ Skipping 4 pieces → stance drift uncatchable
- ❌ One role running multiple milestones in parallel → worktree conflict
- ❌ Audit without dispatch → not forward motion
- ❌ Admin merge / ruleset bypass → permanent ban
- ❌ Idle without dispatch → cron must ACT

## Bootstrap

```
0. runtime-adapter    — confirm environment
1. team-roles         — spawn roles
2. brainstorm         — lock stances
3. blueprint-write    — write blueprint
4. phase-plan         — split into Phases
5. (loop) milestone-fourpiece + pr-review-flow + fast-cron
6. (periodic) role-reminder + slow-cron + issue-triage
7. (Phase wrap-up) phase-exit-gate
```

## Activation protocol

Start all 4 crons when workflow activates (commands from `runtime-adapter`):

| Cron | Frequency | Prompt |
|---|---|---|
| fast-cron | 15 min | `[auto check-in · 15 min] follow skill blueprintflow-teamlead-fast-cron-checkin` |
| role-reminder | 30 min | see `teamlead-role-reminder` SKILL.md for the `<system reminder>` block |
| slow-cron | 2 h | `[drift audit · 2 hours] follow skill blueprintflow-teamlead-slow-cron-checkin` |
| issue-triage | 3 h | `[issue triage · 3h] follow skill blueprintflow-issue-triage` |

Without crons, agents go idle. Crons stop automatically when the session ends; explicitly remove to pause.

**Anti-patterns**: starting only some crons (drift/issues accumulate), cron prompt missing skill name (uncontrolled behavior), persistent crons without user signoff (leaks across projects).

## Team layout principle

Regardless of runtime: Teamlead gets the widest view (coordination thread), roles are visible at a glance, every pane/window is named. Concrete layout commands depend on your runtime — see `blueprintflow-runtime-adapter`.

## Cross-project use

Role names, doc paths (`docs/blueprint/`, `docs/tasks/`), and project aliases are conventions — adjustable via AGENTS.md / CLAUDE.md. Worktree / migration / lint protocols are core and don't change.
