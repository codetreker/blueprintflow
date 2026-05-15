# OpenClaw Adapter

## Decision tree

```
Shared file system with other agents?
├─ Yes (same machine, no sandbox) → Section 1
└─ No  (different machines / sandbox on) → Section 2
```

---

## 1. Same instance (shared FS)

**Capabilities**: persistent ✅ / cross-agent messaging ✅ / shared FS ✅ / scheduled jobs ✅ / parallel multi-role ✅

| Generic phrase | Concrete command |
|---|---|
| Notify \<Role\> | `sessions_send(sessionKey, message)` |
| Create worktree | `exec("git worktree add .worktrees/<task> -b feat/<task> origin/main")` |
| Commit code | `exec("git add -A && git commit && git push")` in worktree |
| Start role reminder | `exec('openclaw cron add --cron "<project role-reminder cron>" --message "<prompt>" --to <channel-id>')` |
| Start slow-cron | `exec('openclaw cron add --cron "<project slow-drift cron>" --message "<prompt>" --to <channel-id>')` |
| Check role status | `sessions_list` / `sessions_history` |
| Open PR | `exec("gh pr create")` (Teamlead only) |
| Merge PR | `exec("gh pr merge <N> --squash")` |

---

## 2. Cross-instance / Discord (no shared FS)

**Capabilities**: persistent ✅ / cross-agent messaging ✅ (via Discord) / shared FS ❌ / scheduled jobs ✅ / parallel multi-role ✅

| Generic phrase | Concrete command |
|---|---|
| Notify \<Role\> | `message(action=send, target=<channel-id>, message=content)` |
| Create worktree | Each agent uses `.worktrees/<task>` on the same `feat/<task>` branch, sync via push/pull |
| Commit code | Local commit + push; others pull |
| Start role reminder | `exec('openclaw cron add --cron "<project role-reminder cron>" --message "<prompt>" --to <channel-id>')` |
| Start slow-cron | `exec('openclaw cron add --cron "<project slow-drift cron>" --message "<prompt>" --to <channel-id>')` |
| Check role status | Channel message history / `message(action=read)` |
| Open PR | `exec("gh pr create")` (Teamlead only) |
| Merge PR | `exec("gh pr merge <N> --squash")` |

**Rule fit (both shapes)**:
- Ping protocol: troubleshoot first (check session, resend), then escalate to user
- No shared FS: each agent commits + pushes independently; Teamlead confirms no conflict before PR
