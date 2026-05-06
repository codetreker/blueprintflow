# Basic mode (subagent / single agent)

**The minimum viable setup any coding agent can run.**

**Capabilities:** persistent at the task level / shared FS sometimes / cross-agent messaging not available / scheduled jobs not available / parallel multi-role not available.

**How to do things:**

| Generic phrase | How |
|---------|---------|
| Notify \<Role\> | Not needed — a single agent switches roles serially, context is passed internally |
| Create worktree | `git worktree add` locally |
| Commit code | Local commit + push |
| Start fast-cron | Skip — the single agent self-checks for idle after each task |
| Start slow-cron | Skip — run a drift audit every N tasks |
| Check role status | Not needed — the single agent knows what it's doing |
| Open PR | `gh pr create` |
| Merge PR | `gh pr merge <N> --squash` |

**Rule fit:**

| Rule | How you carry it out here |
|------|---------------|
| Code commits | The single agent commits in role order. Before switching roles, commit whatever the previous role was doing. |
| Cron checks | No cron. Self-check for idle after each task. |
| Ping protocol | Doesn't apply (you are the only one). |
| Review | Serial review: first as Architect, then as QA. |
| Co-signoff | Sign off for each role one after another. |

> Core rules are in the entry SKILL.md, "Core rules" section.

---
