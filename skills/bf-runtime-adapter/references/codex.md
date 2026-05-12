# Codex Adapter

## Capability matrix

| Mode | Best fit | Persistent | Messaging | FS | Scheduling | Parallel roles |
|---|---|---:|---|---|---|---|
| CLI local session | One milestone / PR review | ✅ | Parent-routed | Local repo | Sleeper subagent | Subagents |
| Codex App + automations | Long-running coordination | ✅ | Parent thread | Platform worktree | Automations | Subagents |
| Cloud task | Bounded execution/review | Task-scoped | Task comments | Task worktree | Caller-driven | Per task |

## Activation check

Run before Phase or milestone work:

| Check | Required action | If missing |
|---|---|---|
| Environment | Identify CLI / App automation / cloud task | Pick the closest mode above |
| Skill access | Confirm this adapter loaded from plugin or repo path | Use explicit `skills/.../codex.md` path |
| Repo instructions | Read target project's `AGENTS.md` | Ask before creating a short Blueprintflow section |
| Role mode | Spawn fixed role coordinator subagents for active phase/task set | Use parent-thread serial lenses only when capacity is missing |
| Subagent capacity | Require `max_depth = 2`; choose thread count from capacity table | Reduce concurrency or ask to update config |
| Reasoning budget | Keep one model family; tune `reasoning_effort` by task type | Coordination uses default; helpers use `high` when unsure |
| Role templates | Optional `.codex/agents/` in target project only | Use prompts from `team-roles/references/*.md` inline |
| Checkins | App: create automations. CLI: spawn one-shot sleeper subagent. Cloud: caller-driven | Do not claim durable cron in CLI-only mode |

## Automation and checkins

Codex CLI has no built-in cron. In CLI sessions, emulate Blueprintflow checkins with a one-shot sleeper subagent.

| Need | Codex App | Codex CLI |
|---|---|---|
| Same conversation heartbeat | Thread automation attached to current thread | Sleeper subagent wakes parent thread |
| Independent recurring sweep | Standalone/project automation | Not native in CLI; start a new parent session and re-read handoff files |
| Skill trigger | Put `$bf-teamlead-fast-cron-checkin` or another `$skill-name` in automation prompt | Sleeper returns the skill trigger; parent runs the matching `SKILL.md` |
| Custom cadence | Use App-supported schedule options | Parent chooses sleeper interval and respawns after each callback |
| 15-min fast-cron | Confirm App supports this interval | Spawn 15-min sleeper subagent |
| 2-4h slow-cron | Confirm App supports this interval | Spawn long sleeper only when thread budget allows |

Sleeper heartbeat flow:

| Step | Action |
|---|---|
| 1 | Parent Teamlead spawns a bounded sleeper subagent |
| 2 | Sleeper waits for the interval and returns only the wakeup message |
| 3 | Parent runs the matching checkin skill |
| 4 | Parent respawns the sleeper only if work remains open |

Sleeper prompt:

```text
Sleep for 15 minutes, then return exactly:
[auto check-in · 15 min] $bf-teamlead-fast-cron-checkin
Do not inspect files, run tools, or make decisions.
```

| Constraint | Rule |
|---|---|
| Durability | Parent session must remain active; no guarantee after session exit |
| Session exit | No active parent remains; a new run must re-read files/PRs/issues |
| Thread cost | Sleeper occupies one `agents.max_threads` slot |
| Looping | Sleeper is one-shot; parent must respawn it |
| Authority | Sleeper only wakes parent; Teamlead makes decisions |
| Nested use | Role-owned sleeper requires `agents.max_depth = 2` |

## Subagent capacity

| Team shape | Required config | Notes |
|---|---|---|
| Serial fallback | Below 8 threads or `max_depth < 2` | Parent serializes some roles; not full Blueprintflow team mode |
| Coordinator roster | `max_threads = 12`, `max_depth = 2` | Parent + 6 role coordinators + limited helper headroom |
| Full Blueprintflow team | `max_threads = 24`, `max_depth = 2` | 6 role coordinators × up to 4 helper/reviewer subagents |
| Large parallel wave | `max_threads = 32+`, `max_depth = 2` | Use only when write scopes are disjoint |

Recommended full-team target-project config:

```toml
[agents]
max_threads = 24
max_depth = 2
```

Hard boundary: set `max_depth = 2` for Blueprintflow. With `max_depth < 2`, role coordinators cannot spawn helper/reviewer subagents and the run must downgrade to serial fallback.

## Reasoning policy

Use the current Codex model for all Blueprintflow agents. Do not switch models by role unless the user explicitly asks; set `reasoning_effort` by task type when spawning short-lived helpers.

| Task type | Suggested effort | Notes |
|---|---|---|
| Routine coordination | inherit/default | Teamlead or role coordinator dispatch, status, handoff routing |
| Bounded implementation | `high` | Production code changes inside bounded write scope |
| Mechanical work | `low` | Search, rename, docs cleanup, formatting, `git status`, simple `git diff` summary |
| Bounded validation | `medium` | Run a known test/CI command, reproduce one failure, apply a clear local fix |
| Architecture / QA / ambiguous failure | `high` | Design tradeoffs, regression judgment, unclear CI/root cause, merge readiness |
| Security review | `xhigh` | Threat modeling, trust boundaries, auth/data-flow risks |
| High-impact planning | `xhigh` | Blueprint/phase/API/data-model changes or unclear multi-role tradeoffs |
| Sleeper heartbeat | `low` | Sleep and return wakeup message only |

Rules:

- Long-lived Teamlead and role coordinators inherit the current session effort by default.
- Coordinators coordinate; helpers execute bounded leaf work.
- Use `medium` only for bounded validation or similarly clear non-production-code tasks.
- If a helper discovers higher-risk work, report back and respawn with higher effort.

## Role coordinators

Role definitions and Teamlead/role-boundary rules live in `bf-team-roles`. Codex implements that model with stable role coordinator subagents.

| Role | Coordinator task name |
|---|---|
| Architect | `bf-architect` |
| PM | `bf-pm` |
| Dev | `bf-dev` |
| QA | `bf-qa` |
| Security | `bf-security` |
| Writer/Operator | `bf-writer` |

Rules:

- Spawn one role coordinator per active role when thread capacity allows.
- Keep role coordinator names stable; add a suffix only for long-lived phase/release/worktree scopes.
- Keep role coordinators open while the phase or active task set is live; close them after handoff.
- Coordinators delegate execution/review work to helper subagents instead of doing all work inline.
- Name helpers with role plus task/milestone, for example `bf-dev:<task>`.
- Helpers report bounded results to their coordinator; coordinators summarize decisions, risks, and handoff to Teamlead.
- If capacity is insufficient, Teamlead runs missing roles as serial lenses and records the downgrade.

## Operation mapping

| Generic phrase | Codex operation |
|---|---|
| Notify `<Role>` | Parent Teamlead sends task to role coordinator; coordinator dispatches helpers |
| Create worktree | CLI: `git worktree add .worktrees/<milestone-or-issue> -b feat/<milestone-or-issue> origin/main` |
| Commit code | Parent reviews/integrates subagent patches before commit + push |
| Start fast-cron | App automation prompt includes `$bf-teamlead-fast-cron-checkin`; CLI spawns 15-min sleeper subagent |
| Start slow-cron | App automation prompt includes `$bf-teamlead-slow-cron-checkin`; CLI spawns long sleeper only when useful |
| Start role-reminder | App automation prompt includes `$bf-teamlead-role-reminder`; CLI parent self-checks before implementation work |
| Start issue-triage | App automation prompt includes `$bf-issue-triage`; CLI uses sleeper or explicit parent dispatch |
| Check role status | Parent checks subagent completion, PR comments, issue state, and TODOs |
| Open PR | Parent Teamlead only: `gh pr create` after four-piece + design + implementation + tests + closure flips |
| Merge PR | Parent Teamlead or merge worker: `gh pr merge <N> --squash --delete-branch`; no admin bypass |

## Rule fit

| Rule | Codex adaptation |
|---|---|
| Role != session | Prefer stable role coordinator subagents; serial lenses are capacity fallback only |
| Everyone stacks commits | Prefer parent-owned commits after coordinator review; helper write scopes must be disjoint |
| Parallel review | Use read-only review subagents for Architect / QA / Security lenses |
| Nested delegation | Allowed only with `agents.max_depth = 2` |
| Cron checks | Codex App automations or CLI sleeper subagents; new CLI runs must rehydrate from files/PRs/issues |
| Silence detection | No ping/pong for one-shot subagents; wait, timeout, close, or replace |

## Role context reuse

Resume is a runtime capability, not a Blueprintflow guarantee. Keep fixed role coordinators open across the phase or active task set when possible, but keep file-based handoff as the source of truth.

| Mode | Use when | Boundary |
|---|---|---|
| Keep role coordinator open | Parent session is active and phase/task set remains open | Same role and long-lived scope only |
| Resume role coordinator | Runtime exposes a resume mechanism and the role has ongoing work | Same role and long-lived scope only |
| Spawn fresh role coordinator | Resume is unavailable or stale | Provide role prompt + phase/task files + latest parent summary |
| File handoff | Always | `docs/tasks/<milestone-or-issue>/*` and PR comments must contain decisions needed after restart |

Rules:

- Do not rely on resumed memory for source-of-truth decisions.
- Before closing or replacing a role coordinator, require a short handoff summary in the milestone docs or parent thread.
- A resumed Dev/QA/Security agent still cannot open PRs or merge; parent Teamlead owns integration.
- If resumed context conflicts with repo files, repo files win and the role re-reads the relevant skill + milestone docs.

## Startup prompt

```text
Use Blueprintflow in Codex mode.
Read skills/bf-workflow/SKILL.md, then read only skills/bf-runtime-adapter/references/codex.md.
Act as Teamlead in the parent thread. Run the Codex activation check before Phase or milestone work.
```

## Optional project-local agents

Blueprintflow's plugin installs skills, not consumer-project `.codex/agents` files.

Target projects may add `.codex/agents/bf-<role>.toml` templates for frequent roles. Each template must say: no PR creation, no merge, parent Teamlead owns integration. Use role prompts from `bf-team-roles/references/*.md`.
