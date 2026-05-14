# Claude Code Adapter

## Sections

| Section | Use |
|---|---|
| Decision tree | Pick the one Claude Code operating mode |
| Team mode + tmux | Full multi-agent setup |
| Team mode, no tmux | Team process without tmux layout |
| Single session | Serial fallback behavior |
| Teamlead checklist | Activation/capacity checks |
| Role bootstrap | Agent prompt and worktree setup |

## Decision tree

```
Team mode enabled?
├─ No  → Section 3 (single session)
└─ Yes → tmux available?
    ├─ No  → Section 2 (team, no tmux)
    └─ Yes → Section 1 (team + tmux)
```

Read only the matching section.

---

## 1. Team mode + tmux (full capability)

Every teammate = independent Claude Code process (`claude --agent-id <name>@<team>`), each with its own context window. Messaging via `SendMessage` (file mailbox), not tmux send-keys.

**Capabilities**: persistent ✅ / cross-agent messaging ✅ / shared FS ✅ / scheduled jobs ✅ / parallel multi-role ✅

**Prerequisite**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (env or settings.json), Claude Code v2.1.32+.

### Lookup table

| Generic phrase | Concrete command |
|---|---|
| Start team | `TeamCreate({team_name})` + `Agent({team_name, name, subagent_type, run_in_background: true, prompt})` × N |
| Notify \<Role\> | `SendMessage("role_name", content)` |
| Create worktree | `git worktree add .worktrees/<task> -b feat/<task> origin/main` |
| Commit code | `git add && git commit && git push` in worktree |
| Start fast-cron | `CronCreate({cron: "<project fast-checkin cron>", prompt: "...", durable: false})` |
| Start slow-cron | `CronCreate({cron: "<project slow-drift cron>", prompt: "...", durable: false})` |
| Check role status | tmux pane output / `SendMessage` |
| Open PR | `gh pr create` (Teamlead only) |
| Merge PR | `gh pr merge <N> --squash` |

Role `Agent(..., prompt)` values must use the `bf-team-roles` common preamble, delegated activation envelope, and role-specific prompt.

### Recommended tmux layout

```
┌──────────────┬───────────┬───────────┐
│              │ Architect │ PM        │
│  Teamlead   ├───────────┼───────────┤
│  (tall left) │ Dev-A     │ Dev-B/C   │
│              ├───────────┼───────────┤
│              │ QA        │ Security  │
└──────────────┴───────────┴───────────┘
```

Teamlead = left column (coordination, biggest view). 6 roles in 2×3 grid.

### Team-startup command skeleton

```bash
SESSION=blueprintflow
tmux new-session -d -s $SESSION -x 220 -y 60
# Right half split into 2x3 grid
tmux split-window -h -p 60 -t $SESSION:0
tmux split-window -v -p 66 -t $SESSION:0.1
tmux split-window -v -p 50 -t $SESSION:0.2
tmux split-window -h -t $SESSION:0.1
tmux split-window -h -t $SESSION:0.3
tmux split-window -h -t $SESSION:0.5

# Name panes
tmux set-option -t $SESSION pane-border-status top
tmux select-pane -t $SESSION:0.0 -T 'teamlead'
# ... architect / pm / dev-a / dev-b / qa / security

# Start claude only in Teamlead pane
tmux send-keys -t $SESSION:0 'claude' Enter
tmux attach -t $SESSION
```

Lead spawns teammates via team tools — Claude Code auto-starts child processes in remaining panes.

### Display modes (`~/.claude/settings.json`)

| Mode | Behavior |
|---|---|
| `"auto"` (default) | Split-pane in tmux, in-process otherwise |
| `"tmux"` | Force split-pane (requires tmux/iTerm2) |
| `"in-process"` | Single terminal, Shift+Down to switch |

### Pane anti-patterns

- ❌ 7 thin columns (content invisible)
- ❌ Teamlead in same row as roles (coordination thread drowned)
- ❌ Unnamed panes (status line shows `bash`)
- ❌ Running `claude` in every pane manually (lead spawns via team tools)

---

## 2. Team mode without tmux

Same team messaging, no tmux pane management.

**Capabilities**: persistent ✅ / cross-agent messaging ✅ / shared FS ✅ / scheduled jobs ✅ / parallel multi-role ✅ (manage terminal windows manually)

Lookup table same as Section 1 except:

| Generic phrase | Difference |
|---|---|
| Check role status | `SendMessage` only (no tmux pane to view) |

---

## 3. No team mode (single session)

Single Claude Code session, no team mode.

**Capabilities**: persistent ✅ / shared FS ✅ / scheduled jobs ✅ / cross-agent messaging ❌ / parallel multi-role ❌

| Generic phrase | Concrete command |
|---|---|
| Notify \<Role\> | Not needed — single session switches roles serially |
| Create worktree | `git worktree add .worktrees/<task> -b feat/<task> origin/main` |
| Commit code | `git add && git commit && git push` in worktree |
| Start fast-cron | `CronCreate({cron: "<project fast-checkin cron>", ...})` — current session runs self-check |
| Start slow-cron | `CronCreate({cron: "<project slow-drift cron>", ...})` — current session runs drift audit |
| Check role status | Not needed — you are all the roles |
| Open PR | `gh pr create` |
| Merge PR | `gh pr merge <N> --squash` |

**Rule fit**: parallel multi-role not possible (serial). Ping protocol N/A. Reviews serial. Co-signoff: one role at a time.

---

## Teammate vs subagent

| | Teammate | Subagent |
|---|---|---|
| What | Separate Claude Code process per role | Child task inside one process |
| Lifecycle | Long-lived session | One-shot, returns to parent |
| Communication | `SendMessage` / `TaskCreate` | Return value |
| Context | Own 1M context window | Shares parent's context |

**Implications**:
- "One task, one PR, everyone stacks commits" requires teammates (persistent, independent commit)
- Ping/Pong applies to teammates only (subagents have completion signals)
- Parallel review via subagents is allowed, but teammate signs off

❌ Don't treat teammates as subagents or vice versa.

---

## Ping / Pong silence detection (team mode only)

| Time | Action |
|---|---|
| First silence threshold | First ping: "Reply pong + one-line progress by the ping deadline" |
| Second silence threshold | Second ping: "Still working? Reply by the ping deadline or shutdown" |
| Takeover threshold | `shutdown_request` → spawn fresh agent to take over |

Thresholds are project/runtime-defined. Does not apply to subagents.

---

## Missing capability prompts

### Missing team mode

> Agent teams not enabled. Impact: no multi-role parallel, no `SendMessage`, no ping protocol.
>
> Enable: `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` or add to `~/.claude/settings.json` → `"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}`. Requires v2.1.32+.

### Missing tmux

> No tmux detected. Impact: can't watch all panes at once. Team messaging still works.
>
> Install: `brew install tmux` (macOS) / `sudo apt install tmux` (Ubuntu). Windows: use WSL.
