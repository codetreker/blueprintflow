# Codex adapter

### Codex (sandbox) [not yet verified in real runs]

**Capabilities:** persistent at the session level / cross-agent messaging only via the parent agent / shared FS limited (sandboxed) / no scheduled jobs / parallel multi-role only if the caller spawns multiple sessions.

**Lookup table:**

| Generic phrase | Concrete command |
|---------|---------|
| Notify \<Role\> | Relayed by the caller |
| Create worktree | `git worktree add` inside the sandbox (each Codex session is independent) |
| Commit code | Commit inside the sandbox, push to remote when done |
| Start fast-cron | Not supported — the caller has to trigger periodically |
| Start slow-cron | Not supported — the caller has to trigger periodically |
| Check role status | The caller checks itself |
| Open PR | After completion the caller runs `gh pr create` |
| Merge PR | The caller runs `gh pr merge <N> --squash` |

**Rule fit:**
- **Everyone stacks commits**: not possible because of sandbox isolation. Each role commits + pushes independently; the Teamlead confirms there's no conflict before opening the PR.
- **fast / slow cron**: not supported. The caller drives them through a heartbeat or scheduled trigger.
- **Ping protocol**: doesn't apply. Codex sessions have their own completion signal.
- **Parallel review subagents**: supported. The caller can spawn multiple sessions to review in parallel.

---
