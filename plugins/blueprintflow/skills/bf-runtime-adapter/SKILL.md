---
name: bf-runtime-adapter
description: "Part of the Blueprintflow methodology. Use when bringing up a Blueprintflow team, switching agent environments, or checking runtime capabilities."
---

# Runtime Adapter

Blueprintflow rules (current is implemented/accepted, next locks before task work, four-piece set, stance-drift defenses, one-task-one-PR) are environment-independent. **How** you carry them out depends on the runtime. This skill centralizes runtime differences; other skills say "what to do", this one says "how".

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Capability dimensions

| Capability | Meaning |
|---|---|
| Persistent session | Long-running agent, holds context, receives messages |
| Cross-agent messaging | Agents message each other (not just parent↔child return values) |
| Shared file system | Multiple agents reach the same worktree |
| Scheduled jobs | Timed jobs (cron / heartbeat) available |
| Parallel multi-role | Multiple role agents run simultaneously |

## Generic → concrete vocabulary

| Generic phrase | Meaning |
|---|---|
| Notify \<Role\> | Any cross-role message (dispatch, completion, review request) |
| Create worktree | Teamlead creates task working directory |
| Commit code | Role does `commit` + `push` in worktree |
| Start cron checks | Set up project-defined role-reminder active coordination + slow drift audit |
| Check role status | Teamlead checks whether each role is working or idle |

## Core rules (all environments)

- Next-blueprint anchor lock before starting task work
- Current blueprint changes only after implementation and acceptance complete
- Four-piece set (spec / stance / acceptance / content-lock)
- Five-layer stance-drift defense
- One task, one PR
- No admin bypass merge (standard squash merge)

## Environment adapters (load on demand)

Read **only** the matching adapter file:

| Environment | Adapter file | Status |
|---|---|---|
| Claude Code | `references/claude-code.md` | Verified |
| OpenClaw | `references/openclaw.md` | Verified |
| Codex | `references/codex.md` | Codex CLI / App / cloud task |
| Other | `references/basic.md` | Generic |

## How to invoke

```
follow skill bf-runtime-adapter
```
