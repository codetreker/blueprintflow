# Skill Runtime Design

Status: next-generation design target. Use this document to plan and review the upcoming `plugins/blueprintflow/skills/*` rewrite. Until the owning skills are updated, legacy execution paths may still use older state names; treat conflicts as rewrite targets, not as permission to mix state models.

Blueprintflow skills are LLM runtime code. They control agent behavior the way application code controls program behavior.

Use this design before changing `plugins/blueprintflow/skills/*`. Update the design first when the state model, ownership boundary, or routing rule changes; then patch the owning skills to match it in the same change set or mark the design section as a future target.

## Design Principles

| Principle | Rule |
|---|---|
| State first | Route by explicit state values on owned rows. |
| One owner | Keep each state value in one ledger only. |
| Parent ledger owns child state | Store child row state in the parent artifact. |
| Stage gates are state checks | Start a stage only after the prior object row reaches the required state. |
| Logs are not state | Use logs, PR comments, and notes as evidence only. |
| Skills are control units | Each skill owns one stage or boundary and exposes clear entry, action, stop, and handoff rules. |
| Teamlead is the scheduler | Teamlead routes, dispatches, and resolves blockers; leaf work runs in role/helper agents. |
| Roles are worker orchestrators | Role coordinators dispatch helpers/reviewers for leaf work, synthesize results, and decide within their role boundary. |
| Git/GitHub evidence is worker I/O | Teamlead delegates mechanical `git` and `gh` inspection to worker agents and consumes summaries; Teamlead keeps PR open/merge/review decisions. |

## Skills As Control Modules

Treat a skill like a callable control module, not a prose document.

| Code concept | Skill equivalent |
|---|---|
| Function signature | Skill metadata description and `bf-workflow` route. |
| Preconditions | Direct invocation guard and required state checks. |
| Inputs | User objective, state ledgers, source artifacts, assigned role scope. |
| Function body | Directive steps and referenced procedures. |
| Side effects | State row updates, document edits, role dispatches, PR/review artifacts. |
| Return value | Handoff target, next state, blocker owner, or completion summary. |
| Error handling | `STOP`, route back, blocker owner, required action. |
| Imports | References, templates, scripts, and delegated child skills. |
| Tests | Validation scripts, pressure scenarios, and local/all-hands review. |

LLM runtime differences:

| Difference | Design response |
|---|---|
| Inputs are natural language plus repo state. | Name source-of-truth files and state rows explicitly. |
| The interpreter is probabilistic. | Use directive language, state checks, stop conditions, and short procedures. |
| Loaded text consumes context. | Keep skill bodies short; move stage-specific detail to references. |
| Execution can dispatch agents. | Separate orchestration from leaf work and record handoffs. |
| Failures are often silent drift. | Review for wrong routing, duplicated state, stale logs, over-broad ownership, and context leaks. |

Before changing a skill, answer:

1. What state does this skill read?
2. What state does this skill own and write?
3. What precondition must hold before it runs?
4. What postcondition proves it completed?
5. Where does it route on failure?
6. Which leaf work must it delegate?
7. Which details belong in a reference instead of the main skill body?

## Iteration State Model

Mainline:

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

Object state owners:

| Object row | State owner |
|---|---|
| Source trace | `docs/blueprint/_meta/<version>/source-issues.md` or `source-notes.md` |
| Anchor | `docs/blueprint/next/README.md` |
| Phase | `docs/tasks/README.md` |
| Milestone | `docs/tasks/phase-N-*/phase-plan.md` |
| Task | `docs/tasks/phase-N-*/milestone-*/milestone.md` |

Stage rules:

| Stage | Entry check | Done state |
|---|---|---|
| Source intake | Source candidates exist. | Source trace artifact maps selected sources to intended anchors. |
| Next blueprint anchors | Source trace artifact exists. | Each selected source maps to one or more anchor rows; each anchor row has `State = OPEN` or `State = PLANNED`. |
| Anchor planning | Anchor row `State = OPEN`. | Each anchor selected for execution has `State = PLANNED`. |
| Phase planning | Anchor row `State = PLANNED`. | Each planned Phase row has `State = PLANNED`. |
| Milestone planning | Phase row exists for the target scope. | Each Milestone row under the target Phase has `State = PLANNED`. |
| Milestone selection | Milestone row `State = PLANNED` and dependencies are satisfied. | One dependency-ready Milestone row has `State = SELECTED`. |
| Milestone breakdown | Milestone row `State = SELECTED`. | The selected Milestone row has `State = TASK_SET_READY`. |
| Task execution | Task row is ready for execution. | Each executed Task row reaches `State = ACCEPTED`. |
| Milestone close | Required task rows have `State = ACCEPTED`. | The target Milestone row has `State = ACCEPTED`. |
| Phase exit | Required Milestone rows have `State = ACCEPTED`. | The target Phase row has `State = ACCEPTED`. |
| Current promotion | Phase row `State = ACCEPTED`. | Corresponding next anchor rows have `State = COMPLETED`. |

## Skill Ownership

| Skill | Owns | Reads | Writes state |
|---|---|---|---|
| `bf-workflow` | Entry routing and Teamlead boundary. | User objective, Teamlead notebook, top-level state. | No product state. |
| `bf-brainstorm` | Fuzzy idea and stance convergence. | User input, existing product context when routed. | No runtime state; hands stances to `bf-blueprint-write`. |
| `bf-blueprint-write` | Next blueprint product shape and anchors. | Brainstorm output or clear non-issue source. | Anchor rows as `OPEN` or ready for `PLANNED`. |
| `bf-blueprint-iteration` | Source intake, anchor selection, current promotion. | Source artifacts, next ledger, accepted task/Phase state. | Source trace mapping, anchor `State`. |
| `bf-phase-plan` | Phase rows and Milestone rows for planned anchors. | Anchor rows with `State = PLANNED`. | Phase rows in `docs/tasks/README.md`; Milestone rows in `phase-plan.md`. |
| `bf-milestone-breakdown` | Task set for one selected milestone. | Milestone row with `State = SELECTED`. | Task rows in `milestone.md`; selected Milestone row to `TASK_SET_READY`. |
| `bf-task-execute` | One task execution loop. | Task row with ready execution state. | Task row progress toward `ACCEPTED`; task-local progress evidence. |
| `bf-milestone-progress` | Task acceptance aggregation and next-task selection. | Task rows in `milestone.md`. | Milestone row state in `phase-plan.md`; next task readiness in `milestone.md`. |
| `bf-phase-exit-gate` | Phase closure. | Milestone rows in `phase-plan.md`. | Phase row state in `docs/tasks/README.md`. |
| Teamlead cron skills | Scheduling backstop and utilization checks. | State ledgers and Teamlead notebook. | Teamlead notebook only, unless routed owning skill updates product state. |

## Role Orchestration

| Layer | Owns | Delegates |
|---|---|---|
| Teamlead | Global routing, priority, blockers, merge gates, context protection, and forward motion. | Role coordinator assignments and mechanical git/GitHub evidence collection. |
| Role coordinator | Role-specific judgment: PM value, Architect structure, QA acceptance, Security risk, Dev implementation, Designer interaction. | Helper/reviewer leaf work inside the role boundary. |
| Helper/reviewer | Bounded reading, drafting, editing, testing, verification, or review evidence. | Nothing. Returns artifacts and findings. |

Role coordinators preserve their context by orchestrating workers. They read enough to decide, dispatch bounded leaf work, synthesize results, and return a role decision or blocker to Teamlead.

## Routing Rules

Use top-down recovery:

```text
docs/blueprint/next/README.md anchor row
-> docs/tasks/README.md Phase row
-> phase-plan.md Milestone row
-> milestone.md Task row
```

Route to the owner of the first row that is missing the next required state. The owner skill updates that row or stops with a blocker owner and required action.

## Skill Change Protocol

1. Update this design document when the behavior change affects state, ownership, or routing.
2. Patch only the skills and references that own the changed behavior.
3. Keep `bf-workflow` as the entry router, not the place for child-stage procedure details.
4. Keep cron skills as schedulers; route stage logic to the owning skill.
5. Run validation and the `repo-update` local review gate before marking a skill change ready.
