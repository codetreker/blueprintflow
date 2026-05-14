# Skill Runtime Design

Status: next-generation design target. Use this document to plan and review the upcoming `plugins/blueprintflow/skills/*` rewrite. Until the owning skills are updated, legacy execution paths may still use older state names; treat conflicts as rewrite targets, not as permission to mix state models.

Blueprintflow skills are goal-directed operating protocols for probabilistic agents. They use code-inspired discipline for state, ownership, routing, and verification, but they should not pretend the LLM is a CPU or that skill text is an executable program.

Write skills to make the goal, invariants, source of truth, and handoff unambiguous. Leave tactical execution space when multiple safe paths can reach the same goal.

Use this design before changing `plugins/blueprintflow/skills/*`. Update the design first when the state model, ownership boundary, or routing rule changes; then patch the owning skills to match it in the same change set or mark the design section as a future target.

## Design Principles

| Principle | Rule |
|---|---|
| State first | Route by explicit state values on owned rows. |
| One owner | Keep each state value in one ledger only. |
| Parent ledger owns child state | Store child row state in the parent artifact. |
| Stage gates are state checks | Start a stage only after the prior object row reaches the required state. |
| Logs are not state | Use logs, PR comments, and notes as evidence only. |
| Skills are operating protocols | Each skill owns one stage or boundary and states the goal, invariants, normal path, stop condition, and handoff. |
| Goals guide judgment | State what success means before prescribing steps. |
| Invariants constrain freedom | Hard rules protect state ownership, review gates, role boundaries, and source-of-truth files. |
| Local choices stay flexible | Leave room for the agent to handle local exceptions when the invariants and done state remain intact. |
| Teamlead is the scheduler | Teamlead routes, dispatches, and resolves blockers; leaf work runs in role/helper agents. |
| Roles are worker orchestrators | Role coordinators dispatch helpers/reviewers for leaf work, synthesize results, and decide within their role boundary. |
| Git/GitHub evidence is worker I/O | Teamlead delegates mechanical `git` and `gh` inspection to worker agents and consumes summaries; Teamlead keeps PR open/merge/review decisions. |

## Skills As Operating Protocols

Treat a skill like an operating protocol, not a prose essay and not a pseudo-program. A good skill tells an intelligent agent what outcome to produce, which invariants cannot break, where truth lives, and how to hand off. It should not enumerate every micro-step or simulate a function call when judgment is required.

Use code concepts as review lenses:

| Code-inspired concern | Skill design question |
|---|---|
| Trigger | When should `bf-workflow` route here? |
| Preconditions | What state or artifact must exist before work starts? |
| Inputs | Which user objective, state ledgers, source artifacts, and role scope matter? |
| Invariants | What must stay true even when the local path changes? |
| Actions | What normal path usually advances the stage? |
| Side effects | Which state rows, docs, dispatches, or PR artifacts may change? |
| Handoff | What state, owner, blocker, or summary lets the next actor continue? |
| Exception handling | When should the agent adapt, route back, stop, or escalate? |
| Progressive disclosure | Which references, templates, scripts, or child skills load only when needed? |
| Tests | Which validation scripts, pressure scenarios, and review checks prove the protocol works? |

LLM runtime differences:

| Difference | Design response |
|---|---|
| Inputs are natural language plus repo state. | Name source-of-truth files and state rows explicitly. |
| The interpreter is probabilistic. | Use directive language, state checks, stop conditions, and short procedures. |
| Loaded text consumes context. | Keep skill bodies short; move stage-specific detail to references. |
| Execution can dispatch agents. | Separate orchestration from leaf work and record handoffs. |
| Failures are often silent drift. | Review for wrong routing, duplicated state, stale logs, over-broad ownership, and context leaks. |

## Protocol Design Checklist

Write each skill around this checklist. The checklist is for design review; it is not a required section template.

| Field | Required content |
|---|---|
| Trigger | Metadata description and `bf-workflow` route state when the skill should run. |
| Owner | One stage, boundary, or scheduler responsibility. |
| Goal | The state transition, artifact, or coordination outcome the skill exists to achieve. |
| Inputs | Source-of-truth artifacts, state rows, user objective, and assigned role scope. |
| Entry check | Exact state or artifact that must exist before any action starts. |
| Invariants | State ownership, source-of-truth, review, role, and handoff rules that cannot be bypassed. |
| Actions | Directive steps using verbs such as `Read`, `Route`, `Dispatch`, `Create`, `Update`, `Record`, `Verify`, and `Stop`. |
| Allowed local choices | Local execution choices the agent may adapt when they preserve invariants and done state. |
| State write | Explicitly listed owned state row or no product state. Never duplicate state into a child detail file. |
| Done state | Exact state value or artifact that proves the stage completed. |
| Durable review artifact | State row, PR comment, review summary, or ledger entry that records review/gate outcome when the skill changes behavior or completes a gate. |
| Handoff | Next owner skill, role coordinator, blocker owner, or user decision. |
| Exception path | State when to adapt, route back, stop, or escalate. When stopping or routing back, name the missing state or artifact, blocker owner, required action, and stop condition. |
| Fallback | Runtime/session-capacity fallback, serial fallback rule, or user escalation when required delegation cannot run. |
| Imports | References, templates, scripts, or child skills loaded only when the current action needs them. |

Before changing a skill, answer:

1. What state does this skill read?
2. What state does this skill own and write?
3. What precondition must hold before it runs?
4. What postcondition proves it completed?
5. Where does it route on failure?
6. Which leaf work must it delegate?
7. Which details belong in a reference instead of the main skill body?
8. Where is the durable review or gate artifact recorded?
9. What fallback applies when required role/helper dispatch is unavailable?
10. Which local choices should be left to the agent because several safe paths may work?

If any answer is unclear, update this design or the owning reference before editing the skill body.

## Goal-Directed Skill Shape

Use short natural-language sections. A child stage skill should normally use this shape:

```markdown
## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else until it routes back.

## Goal

This skill moves <object> from <entry state> to <done state> while preserving <invariants>.

## Source Of Truth

Read <owned parent ledger> for state. Use <detail files> only for scope, evidence, or rationale.

## Operating Rules

- Continue only when <entry state/artifact> exists.
- Update only <owned row>.
- Delegate <leaf work> when evidence, drafting, edits, or validation are needed.
- Adapt local steps when the chosen path preserves <invariants> and reaches <done state>.
- Stop, route back, or escalate when continuing would break <invariant>.

## Normal Path

1. Read the source of truth.
2. Decide whether the entry state is satisfied or which owner must repair it.
3. Dispatch bounded leaf work as needed.
4. Update the owned row only after the done condition is satisfied.
5. Record the durable artifact.

## Handoff

Return <next owner> with <state>, <artifact>, <blocker owner>, or <completion summary>.
```

Keep the entrypoint and scheduler skills smaller than stage skills. `bf-workflow` routes and sets boundaries; cron skills diagnose stalls and route to owners; neither should contain child-stage procedure detail.

Avoid writing skill bodies as pseudo-code. Use imperative verbs where obligations must be clear, but include enough intent for the agent to make good choices under ambiguity.

## Skill Types

Do not force every skill into the same shape. Match the writing style to the skill's runtime responsibility.

These type rules supplement the Protocol Design Checklist; they do not replace trigger, goal, owner, invariants, durable artifact, fallback, or exception-path requirements.

| Type | Examples | Type-specific emphasis | Flexible areas |
|---|---|---|---|
| Entry / router | `bf-workflow` | Activate boundaries, route by objective and state, avoid product-state writes, keep child-stage detail out. | Wording, setup sequencing, concise recovery explanation. |
| Stage controller | `bf-blueprint-iteration`, `bf-phase-plan`, `bf-milestone-breakdown`, `bf-milestone-progress`, `bf-phase-exit-gate` | Read entry state, protect owned ledgers, write only owned rows, prove done state, hand off next owner or blocker. | Evidence-gathering method, helper split, local repair path when invariants stay intact. |
| Execution / judgment | `bf-implementation-design`, `bf-verification`, `bf-current-doc-standard` | State goal, quality bar, evidence requirement, verdict shape, escalation rule, and any artifact it may write. | Tool choice, reading order, analysis path, examples used, reviewer synthesis style. |
| Scheduler / check-in | Teamlead cron skills | Detect stalls, idle roles, blockers, PR gates, and routing needs; update Teamlead notebook only unless routed owner writes state. | Cadence, exact checks, summary format, follow-up batching. |
| Role coordinator | `bf-team-roles` prompts and role references | Keep role scope, delegate leaf work, synthesize helper evidence, return decision/blocker/handoff. | Review strategy, helper assignment shape, evidence organization. |

Type rules:

1. Router and scheduler skills should be terse. They coordinate, route, and preserve context; they do not own child-stage procedures.
2. Stage controller skills need the strongest state language: entry state, done state, owned row, durable artifact, and exception path.
3. Execution and judgment skills need the clearest goal and quality bar. They should leave method choice to the agent when evidence and verdict requirements are satisfied.
4. Role coordinator guidance should emphasize judgment, delegation, and synthesis rather than long leaf-work instructions.
5. Mixed skills should split sections by responsibility. Put state control in the controller section and judgment guidance in the execution section.

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
| Task execution | Task row `State = READY` for a new task, or `TASKING` / `READY_FOR_IMPL` / `IMPLEMENTING` / `ACCEPTING` when resuming. | Each executed Task row reaches `State = ACCEPTED`. |
| Milestone close | Required task rows have `State = ACCEPTED`. | The target Milestone row has `State = ACCEPTED`. |
| Phase exit | Required Milestone rows have `State = ACCEPTED`. | The target Phase row has `State = ACCEPTED`. |
| Current promotion | Phase row `State = ACCEPTED`. | Corresponding next anchor rows have `State = COMPLETED`. |

## Skill Ownership

| Skill | Owns | Reads | Writes state |
|---|---|---|---|
| `bf-workflow` | Entry routing and Teamlead boundary. | User objective, Teamlead notebook, top-level state. | No product state. |
| `bf-brainstorm` | Fuzzy idea and stance convergence. | User input, existing product context when routed. | No runtime state; hands stances to `bf-blueprint-write`. |
| `bf-blueprint-write` | Next blueprint product shape and anchors. | Brainstorm output or clear non-issue source. | Anchor rows as `OPEN` or ready for `PLANNED`. |
| `bf-blueprint-iteration` | Source intake, anchor planning, anchor selection, and current promotion. | Source artifacts, next ledger, accepted task/Phase state. | Source trace mapping; anchor rows to `OPEN`, `PLANNED`, `IMPLEMENTING`, or `COMPLETED`. |
| `bf-phase-plan` | Phase rows and Milestone rows for planned anchors. | Anchor rows with `State = PLANNED`. | Phase rows in `docs/tasks/README.md`; Milestone rows in `phase-plan.md`. |
| `bf-milestone-breakdown` | Task set for one selected milestone. | Milestone row with `State = SELECTED`. | Task rows in `milestone.md`; selected Milestone row to `TASK_SET_READY`. |
| `bf-task-execute` | One task execution loop. | Task row with ready execution state. | Task row progress toward `ACCEPTED`; task-local progress evidence. |
| `bf-milestone-progress` | Milestone selection, task acceptance aggregation, and next-task selection. | Milestone rows in `phase-plan.md`; task rows in `milestone.md`. | Milestone row to `SELECTED` or `ACCEPTED`; next task readiness in `milestone.md`. |
| `bf-phase-exit-gate` | Phase closure. | Milestone rows in `phase-plan.md`. | Phase row state in `docs/tasks/README.md`. |
| Teamlead cron skills | Scheduling backstop and utilization checks. | State ledgers and Teamlead notebook. | Teamlead notebook only, unless routed owning skill updates product state. |

Ownership rules:

1. A skill writes only the state owned by its stage or boundary.
2. A parent ledger owns each child row state: anchor rows own Phase links, Phase rows own milestone state, milestone rows own task state.
3. Detail artifacts may hold scope, acceptance, evidence, blockers, or rationale; they do not create a second state source.
4. `_meta` records selected source trace and intended anchor mapping only; it does not hold runtime state, lock evidence, diary logs, or scheduler output.
5. Logs, PR comments, and local notes are evidence. They cannot satisfy a done state unless an owning skill has updated the owned row.

## Stage Controller Pattern

Every execution stage follows the same controller loop:

1. Read the parent ledger row for the target object.
2. Verify the entry state exactly.
3. Stop with the owning prior-stage route when the entry state is missing.
4. Dispatch bounded leaf work for evidence, drafting, edits, or validation.
5. Update only the owned row when the done condition is satisfied.
6. Return the next owner and the state row that proves handoff readiness.

Do not infer completion from file presence, fresh comments, elapsed time, review prose, or a checklist count. Completion is the done state on the owned row.

## Role Orchestration

| Layer | Owns | Delegates |
|---|---|---|
| Teamlead | Global routing, priority, blockers, merge gates, context protection, and forward motion. | Role coordinator assignments and mechanical git/GitHub evidence collection. |
| Role coordinator | Role-specific judgment: PM value, Architect structure, QA acceptance, Security risk, Dev implementation, Designer interaction. | Helper/reviewer leaf work inside the role boundary. |
| Helper/reviewer | Bounded reading, drafting, editing, testing, verification, or review evidence. | Nothing. Returns artifacts and findings. |

Role coordinators preserve their context by orchestrating workers. They read enough to decide, dispatch bounded leaf work, synthesize results, and return a role decision or blocker to Teamlead.

Teamlead operating loop:

1. Read the user objective and the highest-level relevant state row.
2. Route to the owner of the next missing state.
3. Assign role coordinators for judgment, not leaf work.
4. Assign mechanical `git` and `gh` inspection to workers and consume summaries.
5. Keep every available teammate assigned to useful independent work, a legitimate wait state, or a named blocker with an unblock owner.
6. Reconcile after interruption from source-of-truth state plus the Teamlead notebook; dispatch the restart action in the same turn when it is known.
7. Keep PR open, review-gate, merge, and final integration decisions in Teamlead scope.

Role coordinator return format:

```markdown
Role: <PM|Architect|Dev|QA|Security|Designer>
Scope: <stage/object/path>
Decision: <LGTM|NOT LGTM|BLOCKED|handoff>
Evidence: <files, state rows, commands, or helper summaries>
Findings: <must-fix first; informational second>
Blocker owner: <role/user/none>
Next handoff: <skill/role/state row>
```

Helper/reviewer return format:

```markdown
Scope: <bounded task>
Changed files: <paths or none>
Evidence: <commands, state rows, excerpts, or observations>
Findings: <bugs, conflicts, gaps, or none>
Blockers: <owner and required action, or none>
```

## Git And GitHub Boundary

Mechanical `git` and `gh` work is worker I/O in Teamlead mode.

| Action | Owner |
|---|---|
| Inspect status, diff, branch, commits, CI, PR metadata, labels, or comments | Worker/helper |
| Summarize changed files, pushed commit hash, CI result, PR body state, or review status | Worker/helper |
| Decide whether to open a PR | Teamlead |
| Decide whether review gate is satisfied | Teamlead |
| Decide whether to merge | Teamlead |
| Resolve conflicts between role decisions | Teamlead |

Teamlead consumes summaries and asks for targeted follow-up when evidence conflicts. Teamlead should not spend main context parsing long command output.

## Cron And Scheduler Skills

Cron/check-in skills are schedulers, not stage owners.

They must:

1. Check whether active work is stalled.
2. Check whether any role coordinator or helper is idle while useful work exists.
3. Check whether PR gates, blockers, or review waits need routing.
4. Route to the owning skill for stage logic.
5. Update the Teamlead notebook when coordination state changes.

They must not create durable runtime logs in `_meta` or replace owned row state with scheduler notes. Transient detail belongs in PR comments or local notes when needed.

## Progressive Disclosure

Keep loaded skill text proportional to the current action.

| Content | Location |
|---|---|
| Trigger, entry check, state write, handoff, and stop conditions | `SKILL.md` |
| Long role prompts, review prompts, templates, examples, or pressure scenarios | `references/*.md` |
| Mechanical validation | `.github/scripts/*` |
| Source trace | `docs/blueprint/_meta/<version>/*` |
| Runtime state | Parent ledgers under `docs/blueprint/next/` and `docs/tasks/` |

Load references only when the current step needs them. A skill entrypoint should tell the agent what to read next, not preload the whole workflow.

## Routing Rules

Use top-down recovery:

```text
docs/blueprint/next/README.md anchor row
-> docs/tasks/README.md Phase row
-> phase-plan.md Milestone row
-> milestone.md Task row
```

Route to the owner of the first row that is missing the next required state. The owner skill updates that row or stops with a blocker owner and required action.

State transition names should be stable and small. Main next-anchor states are `OPEN`, `PLANNED`, `IMPLEMENTING`, and `COMPLETED`. Reopening is an event that moves a row back to `OPEN`; it is not a separate long-lived state. Avoid parallel concepts such as `Decision`, `Work`, lock evidence, or freshness gates when one owned `State` value can route the workflow.

## Failure Prevention Checks

Use these checks during design review and local skill review:

| Failure symptom | Prevention check |
|---|---|
| Teamlead stalls after a handoff. | Does the skill return the next owner, exact state row, and restart action? |
| Teamlead serializes independent work. | Does the instruction require idle-role/utilization diagnosis and dispatch when independent work exists? |
| Teamlead burns context on git/gh output. | Does the instruction delegate mechanical inspection and require summary-only evidence? |
| Teamlead does leaf work. | Does the skill route reading, drafting, edits, tests, and review evidence to role/helper workers? |
| Repair logic becomes the main path. | Does the main procedure use normal state transitions, with repair isolated as exceptional recovery? |
| State is inferred from logs or evidence. | Does completion require the done state on the owned row? |
| `_meta` becomes runtime diary storage. | Does `_meta` hold source trace only? |
| `bf-workflow` absorbs child-stage detail. | Does the detail live in the owning child skill or reference? |

For a failure-driven change, record `symptom -> missing/weak instruction -> owning skill/reference -> prevention check`, then ask whether the new instruction would have prevented the observed failure.

## Skill Change Protocol

1. Update this design document when the behavior change affects state, ownership, or routing.
2. Patch only the skills and references that own the changed behavior.
3. Keep `bf-workflow` as the entry router, not the place for child-stage procedure details.
4. Keep cron skills as schedulers; route stage logic to the owning skill.
5. Review every changed skill as a whole, not only the diff.
6. Run validation and the `repo-update` local review gate before marking a skill change ready.
7. Treat local reviewer LGTM as a prerequisite for PR readiness, not as all-hands approval.

Minimum validation for this document and skill rewrites:

```bash
rg --files plugins/blueprintflow .claude docs .github .claude-plugin .agents
rg "TODO|FIXME|TBD" plugins/blueprintflow/skills docs README.md
git diff --check
.github/scripts/validate-plugin-layout.sh
.github/scripts/validate-skills.sh
.github/scripts/validate-release-version.sh origin/main
```
