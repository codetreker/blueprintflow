# OpenClaw adapter

### OpenClaw (multi-agent)

Use the decision tree below to confirm your configuration:

```
Do I share a file system with the other agents?
├─ Yes (same machine / instance, no sandbox) → "Same instance" config (section 1)
└─ No (different machines, or sandbox is on) → "Cross instance" config (section 2)
```

Once confirmed, read only the matching section.

#### Same instance, multi-agent (shared file system)

Multiple agents run on the same machine / instance and share the file system because the sandbox is off.

**Capabilities:** persistent / cross-agent messaging / shared FS / scheduled jobs / parallel multi-role — all available.

| Generic phrase | Concrete command |
|---------|---------|
| Notify \<Role\> | `sessions_send(sessionKey, message)` — direct message between agents inside the same instance |
| Create worktree | `exec("git worktree add .worktrees/<milestone> ...")` |
| Commit code | Inside the worktree: `exec("git add -A && git commit && git push")` |
| Start fast-cron | `exec('openclaw cron add --cron "7,22,37,52 * * * *" --message "<fast-cron prompt>" --to <project-channel-id>')` or add an item to HEARTBEAT.md |
| Start slow-cron | `exec('openclaw cron add --cron "17 */2 * * *" --message "<slow-cron prompt>" --to <project-channel-id>')` |
| Check role status | `sessions_list` / `sessions_history` |
| Open PR | `exec("gh pr create")` (Teamlead only) |
| Merge PR | `exec("gh pr merge <N> --squash")` |

#### Cross-instance / Discord collaboration (no shared file system)

Agents are spread across different machines and collaborate through a Discord channel.

**Capabilities:** persistent / cross-agent messaging (through Discord) / scheduled jobs / parallel multi-role are available; shared FS is not.

| Generic phrase | Concrete command |
|---------|---------|
| Notify \<Role\> | `message(action=send, target=<channel-id>, message=content)` — through the Discord channel |
| Create worktree | Each agent runs `git worktree add` locally, sync via `git push` / `git pull` |
| Commit code | Local commit + `git push`; other agents `git pull` to pick it up |
| Start fast-cron | `exec('openclaw cron add --cron "7,22,37,52 * * * *" --message "<fast-cron prompt>" --to <project-channel-id>')` or add an item to HEARTBEAT.md |
| Start slow-cron | `exec('openclaw cron add --cron "17 */2 * * *" --message "<slow-cron prompt>" --to <project-channel-id>')` |
| Check role status | Channel message history / `message(action=read)` |
| Open PR | `exec("gh pr create")` (Teamlead only) |
| Merge PR | `exec("gh pr merge <N> --squash")` |

**Rule fit (applies to both shapes):**
- **Ping protocol**: if a role isn't responding, the Teamlead troubleshoots first (check session state, resend the message); if that doesn't recover it, escalate to the user.
- **Cross-instance file sync**: when there's no shared FS, "everyone stacks commits" turns into "each agent commits + pushes independently, and the Teamlead pulls and confirms there's no conflict before opening the PR".
---
