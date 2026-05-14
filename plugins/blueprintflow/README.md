# Blueprintflow Iteration Flow

Status: next-generation design target. Use this document to design the upcoming child-skill rewrite. Current v4.0.1 skills still carry legacy `Decision` / `Work` / `LOCKED` state in some execution paths; the rewrite must bring those skills into this model before this file becomes the active runtime procedure.

Blueprintflow turns selected sources into accepted current behavior through a dependency-ordered path:

```text
source intake
-> source trace
-> next blueprint anchors
-> Phase planning
-> Milestone planning
-> selected milestone breakdown
-> task execution loop
-> milestone close
-> Phase exit
-> current promotion
```

## Flow Diagram

```mermaid
flowchart TD
    A["New product / module / fuzzy idea"] --> B["bf-brainstorm"]
    B --> C["bf-blueprint-write"]
    C --> D["docs/blueprint/_meta/version/source-notes.md"]
    E["Backlog issues"] --> F["Select issues for this iteration"]
    F --> G["docs/blueprint/_meta/version/source-issues.md"]
    H["Non-issue idea"] --> I{"Clear enough?"}
    I -->|No| B
    I -->|Yes| C
    D --> J["docs/blueprint/next anchors"]
    G --> J
    C --> J
    J --> K{Anchor State}
    K -->|OPEN| J
    K -->|PLANNED| L["Phase planning"]
    L --> M["Milestone planning"]
    M --> N["Select one milestone"]
    N --> O["Milestone breakdown"]
    O --> P["Task execution loop"]
    P --> Q["Milestone close"]
    Q --> R{More required milestones?}
    R -->|Yes| N
    R -->|No| S["Phase exit"]
    S --> T{More required phases?}
    T -->|Yes| L
    T -->|No| U["Promote accepted scope to current"]
    U --> V["Anchor State = COMPLETED"]
```

## Source Intake

| Source | Route | Trace artifact |
|---|---|---|
| New product, new module, or fuzzy idea | Run `bf-brainstorm`, then `bf-blueprint-write`. | `docs/blueprint/_meta/<version>/source-notes.md` |
| Backlog GitHub issues | Select this iteration's issues. | `docs/blueprint/_meta/<version>/source-issues.md` |
| Non-issue idea in an existing product | Run `bf-brainstorm` when unclear; otherwise run `bf-blueprint-write`. | `docs/blueprint/_meta/<version>/source-notes.md` |

`source-issues.md` maps issue-backed sources to next anchors. `source-notes.md` maps non-issue sources to next anchors. Both are source trace only.

## State Ledger

`docs/blueprint/next/README.md` is the resume ledger for next-blueprint anchors.

Use this shape:

```markdown
| Anchor | Detail anchor | Topic | State | Milestone path |
|---|---|---|---|---|
| AUTH-1 | auth.md#auth-1 | Auth model | OPEN | - |
| AUTH-2 | auth.md#auth-2 | Login session | PLANNED | - |
| AUTH-3 | auth.md#auth-3 | Org role API | IMPLEMENTING | docs/tasks/phase-1-auth/milestone-2-role-api |
| AUTH-4 | auth.md#auth-4 | Invite flow | COMPLETED | docs/tasks/phase-1-auth/milestone-3-invite |
```

| State | Meaning | Next route |
|---|---|---|
| `OPEN` | Product scope is still being discussed. | Continue blueprint discussion. |
| `PLANNED` | Product scope is selected and ready for execution planning. | Run Phase/Milestone planning. |
| `IMPLEMENTING` | The anchor is active in `docs/tasks`. | Resume from `docs/tasks/README.md` and `milestone.md`. |
| `COMPLETED` | Accepted scope is ready for current promotion or already reflected in current. | Promote or confirm current sync. |

`_meta` stores source trace only. Runtime routing comes from `docs/blueprint/next/README.md` and `docs/tasks` state files.

## State Ownership

Parent ledgers own child row state. Keep each state in one place.

| Object row | State owner |
|---|---|
| Source batch | `docs/blueprint/_meta/<version>/source-issues.md` or `source-notes.md` |
| Anchor | `docs/blueprint/next/README.md` |
| Phase | `docs/tasks/README.md` |
| Milestone | `docs/tasks/phase-N-*/phase-plan.md` |
| Task | `docs/tasks/phase-N-*/milestone-*/milestone.md` |

Resume from top to bottom: next anchor row -> Phase row -> Milestone row -> Task row. Detail files may explain scope, acceptance, blockers, or implementation evidence; they do not duplicate parent-owned state.

## Stage Rules

Read state values from the relevant row or batch, not from logs or inferred file presence.

| Stage | Entry check | Done state |
|---|---|---|
| Source intake | Source candidates exist. | Source batch `State = SELECTED`. |
| Next blueprint anchors | Source batch `State = SELECTED`. | Each selected source maps to one or more anchor rows; each anchor row has `State = OPEN` or `State = PLANNED`. |
| Anchor planning | Anchor row `State = OPEN`. | Each anchor selected for execution has `State = PLANNED`. |
| Phase planning | Anchor row `State = PLANNED`. | Each planned Phase row has `State = PLANNED`. |
| Milestone planning | Phase row exists for the target scope. | Each Milestone row under the target Phase has `State = PLANNED`. |
| Milestone selection | Milestone row `State = PLANNED` and dependencies are satisfied. | One dependency-ready Milestone row has `State = SELECTED`. |
| Milestone breakdown | Milestone row `State = SELECTED`. | The selected Milestone row has `State = TASK_SET_READY`. |
| Task execution | Task row is ready for execution. | Each executed Task row reaches `State = ACCEPTED`. |
| Milestone close | Required task rows have `State = ACCEPTED`. | The target Milestone row has `State = ACCEPTED`. |
| Phase exit | Required Milestone rows have `State = ACCEPTED`. | The target Phase row has `State = ACCEPTED`. |
| Current promotion | Phase row `State = ACCEPTED`. | Corresponding next anchor rows have `State = COMPLETED`. |

State belongs to object rows: source batch, anchor, Phase, Milestone, and Task. A stage is done only when the relevant row set reaches the done state.

## Planning Rules

- Phase is a dependency-ordered stage inside one major iteration. Default to no more than 3 Phases.
- Milestone is a user-facing deliverable inside a Phase. Default to no more than 3 Milestones per Phase.
- Task is the execution and PR atom. One task uses one worktree, one branch, and one PR.
- Milestone breakdown runs for one selected milestone at a time.
- Parallel work is valid inside a stage when dependencies are clear and the owning plan records the safe parallelism.
