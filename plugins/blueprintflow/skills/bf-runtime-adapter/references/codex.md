# Codex Adapter

## Sections

| Section | Use |
|---|---|
| Modes | Pick CLI, App, or cloud-task mode |
| Activation Check | Confirm skills, roles, capacity, reasoning |
| Capacity | Set max depth/threads expectations |
| Reasoning Effort | Choose helper effort by task type |
| CLI Sleeper Fallback | Simulate check-ins without durable cron |
| Context Reuse | Resume coordinators and helpers |
| Command Mapping | Translate Blueprintflow actions to Codex |

## Modes

| Mode | Use for | Scheduling | Parallelism |
|---|---|---|---|
| CLI local session | One task / PR review | Sleeper subagent | Subagents |
| Codex App | Long-running coordination | App automations | Subagents |
| Cloud task | Bounded execution/review | Caller-driven | Per task |

## Activation Check

Run before Phase, milestone, or task work.

| Check | Required |
|---|---|
| Skills | `blueprintflow:bf-*` active, or current checkout reference loaded |
| Repo rules | Read target project `AGENTS.md` |
| Roles | Parent is Teamlead; role agents are coordinators |
| Capacity | `agents.max_depth = 2`; `agents.max_threads >= 24` for full team |
| Reasoning | One model family; helper effort by task type |
| Checkins | App automation or CLI sleeper; no durable CLI cron claim |

## Capacity

| Team shape | Config |
|---|---|
| Serial fallback | `<8` threads or `max_depth < 2` |
| Coordinator roster | `max_threads = 12`, `max_depth = 2` |
| Full team | `max_threads = 24`, `max_depth = 2` |
| Large parallel wave | `max_threads = 32+`, `max_depth = 2` |

```toml
[agents]
max_threads = 24
max_depth = 2
```

## Role Coordinators

| Role | Stable coordinator name |
|---|---|
| Architect | `bf-architect` |
| PM | `bf-pm` |
| Dev | `bf-dev` |
| QA | `bf-qa` |
| Security | `bf-security` |
| Writer/Operator | `bf-writer` |

Rules:
- Coordinators coordinate; helpers execute bounded leaf work.
- Reuse relevant coordinator/helper subagents when their context is still valid; spawn fresh only for independent review, materially different scope, stale/biased context, overload, parallelism, or required Security/review separation.
- Name helpers `bf-<role>:<task>`.
- Spawn role coordinators with the `bf-team-roles` common preamble, delegated activation envelope, and role-specific prompt so they can load routed `bf-*` skills inside scope without re-entering `using-plueprint`.
- If capacity is insufficient, Teamlead runs missing roles as serial lenses and records the downgrade.
- In Codex, bare activation may set up Teamlead/runtime boundaries and role coordinators, but it does not authorize helper dispatch, project content inspection, or sleeper/automation setup. Those start only after the user names a concrete Blueprintflow-scoped objective or explicitly requests ongoing coordination, such as a Phase, milestone, task, issue, PR review, drift audit, or cron check-in.
- Missing or ambiguous user authorization is not a spawn-capacity failure. If Codex host policy or the current tool contract requires explicit user authorization before spawning role/helper agents, Teamlead must ask the user for that authorization instead of declaring `serial fallback`.
- If the Codex runtime or current session truly lacks role/helper spawning capability after required authorization has been requested or resolved, Teamlead must declare `serial fallback` before doing role-lens work in the parent thread.

## Reasoning Effort

| Task type | Effort |
|---|---|
| Teamlead / role coordination | inherit/default |
| Mechanical search, rename, formatting, sleep | `low` |
| Bounded validation | `medium` |
| Bounded implementation | `high` |
| Architecture, QA judgment, unclear CI/root cause | `high` |
| Security review | `xhigh` |
| High-impact planning | `xhigh` |

If unsure, use `high`. Sleeper helpers use `low`.

## Checkins

| Need | Codex App | Codex CLI |
|---|---|---|
| Fast checkin | Automation prompt with `$bf-teamlead-fast-cron-checkin` | Project-cadence sleeper subagent |
| Slow checkin | Automation prompt with `$bf-teamlead-slow-cron-checkin` | Long sleeper only when useful |
| Role reminder | Automation prompt with `$bf-teamlead-role-reminder` | Parent self-check before implementation |
| Issue triage | Automation prompt with `$bf-issue-triage` | Sleeper or explicit parent dispatch |

Sleeper prompt:

```text
Sleep for the project-defined fast-checkin cadence, then return exactly:
[auto check-in] $bf-teamlead-fast-cron-checkin
Do not inspect files, run tools, or make decisions.
```

Sleeper constraints: one-shot; occupies one thread; parent must remain active; parent respawns only if work remains.

## Context Reuse

Do not call `close_agent` on role coordinators as task cleanup; continue existing coordinator threads with concise deltas. Reuse the same worker for follow-up work in the same scope when its context remains useful. Start a fresh worker only for independent/blind review, stale or biased context, materially different scope, parallel work while the existing worker is busy, or mandatory Security/review independence.

## Operation Map

| Blueprintflow phrase | Codex operation |
|---|---|
| Notify `<Role>` | Parent sends task to role coordinator |
| Create worktree | `git worktree add .worktrees/<task> -b feat/<task> origin/main` |
| Commit code | Parent reviews/integrates helper patches, then commits |
| Check role status | Parent checks subagent state, PR comments, issues, TODOs |
| Open PR | Parent Teamlead only: `gh pr create` |
| Merge PR | Parent Teamlead/merge worker: `gh pr merge <N> --squash --delete-branch`; no admin bypass |

## Startup Prompt

```text
Use Blueprintflow in Codex mode.
Use using-plueprint, then this Codex adapter reference.
Act as Teamlead in the parent thread and run the activation check before Phase, milestone, or task work.
```

## Optional Local Agents

Target projects may add `.codex/agents/bf-<role>.toml` templates. Each template must say: no PR creation, no merge; parent Teamlead owns integration; runtime assignment supplies the delegated activation envelope. Use role prompts from `bf-team-roles/references/*.md`.
