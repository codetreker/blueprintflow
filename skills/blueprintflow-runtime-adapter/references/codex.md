# Codex Adapter [not yet verified in real runs]

**Capabilities**: persistent (session-level) ✅ / cross-agent messaging (via caller only) / shared FS ❌ (sandboxed) / scheduled jobs ❌ / parallel multi-role (caller spawns multiple sessions)

## Lookup table

| Generic phrase | Concrete command |
|---|---|
| Notify \<Role\> | Relayed by caller |
| Create worktree | `git worktree add` inside sandbox (each session independent) |
| Commit code | Commit in sandbox, push to remote when done |
| Start fast-cron | Not supported — caller triggers periodically |
| Start slow-cron | Not supported — caller triggers periodically |
| Check role status | Caller checks |
| Open PR | Caller runs `gh pr create` after completion |
| Merge PR | Caller runs `gh pr merge <N> --squash` |

## Rule fit

| Rule | Adaptation |
|---|---|
| Stacking commits | Not possible (sandbox isolation) — each role commits + pushes independently; Teamlead confirms no conflict before PR |
| Cron | Not supported — caller drives via heartbeat/schedule |
| Ping protocol | N/A — sessions have completion signals |
| Parallel review | Supported — caller spawns multiple sessions |
