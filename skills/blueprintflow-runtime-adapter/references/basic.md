# Basic Mode (single agent / subagent)

Minimum viable setup for any coding agent.

**Capabilities**: persistent (task-level) ✅ / shared FS sometimes / cross-agent messaging ❌ / scheduled jobs ❌ / parallel multi-role ❌

## Lookup table

| Generic phrase | How |
|---|---|
| Notify \<Role\> | Not needed — single agent switches roles serially |
| Create worktree | `git worktree add` locally |
| Commit code | Local commit + push |
| Start fast-cron | Skip — self-check for idle after each task |
| Start slow-cron | Skip — drift audit every N tasks |
| Check role status | Not needed — you know what you're doing |
| Open PR | `gh pr create` |
| Merge PR | `gh pr merge <N> --squash` |

## Rule fit

| Rule | Adaptation |
|---|---|
| Code commits | Commit in role order; commit before switching roles |
| Cron checks | No cron — self-check after each task |
| Ping protocol | N/A (you are the only one) |
| Review | Serial: first as Architect, then QA |
| Co-signoff | Sign off for each role sequentially |
