---
name: blueprintflow-runtime-adapter
description: "Part of the Blueprintflow methodology. Use when bringing up a team or switching agent environments - maps environment capabilities (messaging, files, scheduling, silence detection) to concrete operations."
---

# Runtime Adapter

Blueprintflow rules (blueprint freeze, four-piece set, stance-drift defenses, one-milestone-one-PR) are environment-independent. **How** you carry them out depends on the runtime. This skill centralizes runtime differences; other skills say "what to do", this one says "how".

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
| Create worktree | Teamlead creates milestone working directory |
| Commit code | Role does `commit` + `push` in worktree |
| Start cron checks | Set up fast-cron (15min) + slow-cron (2-4h) |
| Check role status | Teamlead checks whether each role is working or idle |

## Core rules (all environments)

- Blueprint freeze before starting work
- Four-piece set (spec / stance / acceptance / content-lock)
- Five-layer stance-drift defense
- One milestone, one PR
- No admin bypass merge (standard squash merge)

## Environment adapters (load on demand)

Read **only** the matching adapter file:

| Environment | Adapter file | Status |
|---|---|---|
| Claude Code | `references/claude-code.md` | Verified |
| OpenClaw | `references/openclaw.md` | Verified |
| Codex | `references/codex.md` | Not yet verified |
| Other | `references/basic.md` | Generic |

## How to invoke

```
follow skill blueprintflow-runtime-adapter
```
