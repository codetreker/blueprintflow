# Blueprintflow Overview

Read this only when someone needs the fuller lifecycle map or conceptual explanation behind `bf-workflow`.

## Mental model

| City engineering | Blueprintflow |
|---|---|
| Chief engineer | Architect - blueprints + spec briefs |
| Client | PM - stances + constraints |
| Construction crew | Dev - builds to spec |
| Inspector | QA - acceptance |
| Designer / safety | Designer / Security |
| General contractor | Teamlead - coordinates, doesn't build |

Core principle: **freeze the blueprint before building**. Changes go through PR + 4-role review, like an engineering change order.

Engineering practices that map across:

- **Phase by value loop** - not by technical layer.
- **Phase-end signoff** - 4-role signoff as acceptance report + carry-over gate.
- **Quality-gate trail** - rule 6 / migration versioning as engineering archive.
- **PM on site throughout** - stance reverse-check so construction cannot drift from requirements.

## 4-layer structure

```text
Concept layer ---- brainstorm + blueprint-write
    ->
Plan layer ------- phase-plan
    ->
Milestone layer -- milestone-fourpiece + current-doc-standard + pr-review-flow
    ->
Coordination ----- fast-cron (15 min) + role-reminder (30 min)
                   slow-cron (2-4 h) + issue-triage (3 h)
                   phase-exit-gate
```

## Roles

| Role | Responsibilities |
|---|---|
| Teamlead | Coordinates, assigns work, guards protocol. Doesn't write code |
| Architect | Spec brief, blueprint citations, gates 1+2, PR architecture review |
| PM | Stance reverse-check, content lock, gates 3+4 |
| Dev | Implementation, migration, unit tests |
| QA | Acceptance template, E2E tests, current-sync review, gate 4 |
| Designer | UI/UX/visual when milestone touches client UI |
| Security | Auth/privacy/admin/cross-org review; mandatory independent role |

Full role prompts live in `bf-team-roles`.

## Stages

| Stage | Skill path |
|---|---|
| Runtime | `bf-runtime-adapter` confirms environment (team mode, crons, messaging) |
| Concept | `bf-brainstorm` locks stances + concept model; `bf-blueprint-write` writes `docs/blueprint/*.md` |
| Plan | `bf-phase-plan` splits blueprint into Phases and writes `docs/tasks/README.md` |
| Execution | `bf-git-workflow`, `bf-milestone-fourpiece`, `bf-implementation-design`, `bf-current-doc-standard`, `bf-pr-review-flow`, `bf-e2e-verification` |
| Coordination + Phase exit | fast/slow check-ins, role reminders, issue triage, `bf-phase-exit-gate` |
| Iteration | `bf-blueprint-iteration` manages current / next / backlog after freeze |

## Anti-patterns

- Skipping 4 pieces -> stance drift becomes uncatchable.
- One role running multiple milestones in parallel -> worktree conflict.
- Audit without dispatch -> not forward motion.
- Admin merge / ruleset bypass -> permanent ban.
- Idle without dispatch -> cron must act.
- Letting a non-Blueprintflow skill turn Teamlead into a leaf worker -> role boundaries collapse.

## Drift defenses

Five layers defend against stance drift:

1. Spec brief grep cross-check.
2. Acceptance template anchor cross-check.
3. Stance checklist blacklist grep.
4. Content-lock byte-identical check.
5. Cross-file cross-check during PR review.

## Cross-project use

Role names, doc paths (`docs/blueprint/`, `docs/tasks/`), and project aliases are conventions, adjustable via `AGENTS.md` / `CLAUDE.md`. Worktree / migration / lint protocols are core and do not change.
