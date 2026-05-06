---
name: blueprintflow-runtime-adapter
description: "Part of the Blueprintflow methodology. Use when bringing up a team or switching agent environments - maps environment capabilities (messaging, files, scheduling, silence detection) to concrete operations."
version: 1.1.1
---

# Runtime Adapter

Blueprintflow's rules (freeze the blueprint first, the four-piece set, the stance-drift defenses, one milestone one PR) do not depend on the runtime environment. But **how you carry out** those rules does depend on what the agent environment can do.

This skill is where runtime differences are kept in one place. Other skills only describe "what to do" (e.g. "notify Dev to start implementing"); this skill defines "how to do it".

## Capability dimensions

Five capability dimensions decide your run mode:

| Capability | Meaning |
|------|------|
| **Persistent session** | The agent can run for a long time, hold context, and receive messages |
| **Cross-agent messaging** | Agents can send messages to each other (not just parent ↔ child return values) |
| **Shared file system** | Multiple agents can reach the same file system / worktree |
| **Scheduled jobs** | You can create timed jobs (cron / heartbeat) |
| **Parallel multi-role** | Multiple role agents can run at the same time |

## Vocabulary

Generic phrases used in the rule skills → the concrete commands this adapter gives:

| Generic phrase | Meaning |
|---------|------|
| **Notify \<Role\>** | Any cross-role message: dispatch work, report completion, request review, etc. |
| **Create worktree** | Teamlead creates the working directory for a milestone |
| **Commit code** | A role does `commit` + `push` inside a worktree |
| **Start cron checks** | Set up fast-cron (idle dispatch) and slow-cron (drift audit) |
| **Check role status** | Teamlead checks whether each role is working or idle |

---

## Core rules (apply everywhere)

No matter the environment, the following rules always apply:
- Freeze the blueprint before starting work
- The four-piece set (spec / stance / acceptance / content-lock)
- The five-layer stance-drift defense
- One milestone, one PR
- A stance you can't write a counter-constraint for is not a real stance
- Never use admin bypass to merge a PR (standard squash merge)

## Environment adapters (load on demand)

When you start blueprintflow, confirm your runtime environment and **read only the matching adapter file**:

| My environment | Adapter file | Status |
|-------------|---------|------|
| **Claude Code** | `references/claude-code.md` (separates team+tmux / team without tmux / no team) | Verified |
| **OpenClaw** | `references/openclaw.md` (separates same-instance / cross-instance) | Verified |
| **Codex** | `references/codex.md` | Not yet verified in real runs |
| **Other** | `references/basic.md` | Generic |

After reading the adapter file, follow the lookup table whenever a later skill uses one of the generic phrases. When the agent environment changes, pick the adapter file again.

## How to invoke

The first time you bring up blueprintflow:
```
follow skill blueprintflow-runtime-adapter
confirm the run mode → load the lookup table
```
