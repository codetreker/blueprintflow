# Claude Code adapter

### Claude Code

Claude Code has three configuration combinations. Use the decision tree below to confirm yours:

```
Do I have team mode?
├─ No → "No team mode" config (see section 3 below)
└─ Yes → Am I running inside tmux?
    ├─ No → "Team mode without tmux" config (see section 2 below)
    └─ Yes → "Team mode + tmux" config (see section 1 below)
```

Once confirmed, read only the matching section.

#### Team mode + tmux (full capability)

Every teammate is an **independent Claude Code process** (`claude --agent-id <name>@<team>` on startup), each with its own context window and token budget. When the lead spawns a teammate, Claude Code automatically starts a child claude process and adds it to the shared mailbox; inside the tmux session the default display mode is split-pane, where each teammate automatically takes one pane.

Messaging goes through `SendMessage` (backed by a file mailbox `~/.claude/teams/<team>/inboxes/<name>.json` — observed in practice; as an experimental feature, internals may change between versions), not through tmux send-keys.

**Capabilities:** persistent / cross-agent messaging / shared FS / scheduled jobs / parallel multi-role — all available.

##### Recommended layout (6 roles + Teamlead)

```
┌─────────────────┬──────────────┬──────────────┐
│                 │  Architect   │  PM          │
│   Teamlead      ├──────────────┼──────────────┤
│   (tall left)   │  Dev-A       │  Dev-B/C     │
│                 ├──────────────┼──────────────┤
│                 │  QA          │  Security   │
└─────────────────┴──────────────┴──────────────┘
```

- **Teamlead takes the entire left column** (the coordination thread, biggest field of view)
- **6 roles in a 2×3 grid on the right** (each cell equal height, names visible at a glance)
- Security is required as an independent role and must take a cell (Architect can't double up); Designer is added per project need

##### Team-startup command skeleton

```bash
# 1. Create tmux canvas + split into layout
SESSION=blueprintflow
tmux new-session -d -s $SESSION -x 220 -y 60
# Right half split into 2x3 grid (empty panes)
tmux split-window -h -p 60 -t $SESSION:0
tmux split-window -v -p 66 -t $SESSION:0.1
tmux split-window -v -p 50 -t $SESSION:0.2
tmux split-window -h -t $SESSION:0.1
tmux split-window -h -t $SESSION:0.3
tmux split-window -h -t $SESSION:0.5

# 2. Name panes (shown in status line)
tmux set-option -t $SESSION pane-border-status top
tmux select-pane -t $SESSION:0.0 -T 'teamlead'
tmux select-pane -t $SESSION:0.1 -T 'architect'
# ... pm / dev-a / dev-b / qa / security

# 3. Start claude only in Teamlead pane
tmux send-keys -t $SESSION:0 'claude' Enter
tmux attach -t $SESSION
```

After entering the Teamlead session, the lead uses team mode tools to create the team and spawn roles — Claude Code auto-starts child claude processes and fills the remaining panes. No need to manually run `claude` in each pane. Messaging goes through mailbox notifications (see the table below), not tmux send-keys.

##### Pane anti-patterns

- ❌ Splitting everything left/right (7 thin columns, content invisible)
- ❌ Teamlead in the same row as the roles (the coordination thread gets drowned)
- ❌ Panes left unnamed (status line just says `bash`, can't tell who's who)
- ❌ One window per session (slow to switch windows, can't see the full picture)
- ❌ Running `claude` in every pane manually (lead spawns teammates via team mode tools)

| Generic phrase | Concrete command |
|---------|---------|
| Start team | Lead inside the tmux session: `TeamCreate({team_name})` + `Agent({team_name, name, subagent_type, run_in_background: true, prompt})` × N. Claude Code auto-starts child claude processes and lays them out in tmux panes |
| Notify \<Role\> | `SendMessage("role_name", content)` |
| Create worktree | `cd <repo> && git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main` |
| Commit code | Inside the worktree: `git add && git commit && git push` |
| Start fast-cron | `CronCreate({cron: "7,22,37,52 * * * *", prompt: "...", durable: false})` |
| Start slow-cron | `CronCreate({cron: "17 */2 * * *", prompt: "...", durable: false})` |
| Check role status | Look at the tmux pane output / ask via `SendMessage` |
| Open PR | `gh pr create` (Teamlead only) |
| Merge PR | `gh pr merge <N> --squash` |

**Display mode setting** (`~/.claude/settings.json`):

- `teammateMode: "auto"` (default) — automatically uses split-pane inside a tmux session, otherwise uses in-process
- `teammateMode: "tmux"` — force split-pane (requires tmux or iTerm2)
- `teammateMode: "in-process"` — single terminal, use Shift+Down to switch between teammates (teammates are still independent instances, just displayed stacked in one terminal)

**Prerequisite**: agent teams is an experimental feature, you must enable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (env or settings.json), requires Claude Code v2.1.32+.

**Rule fit:** all rules apply.

**Anti-pattern**: ❌ Treating a teammate as a subagent. A subagent is a Task spawned inside the lead's session, shares the lead's context, and can only report back to the lead; a teammate is an independent Claude Code process, each with its own 1M context, communicating directly with each other through mailbox. Don't interchange the terms, and don't assume a teammate can see the lead's conversation history.

#### Team mode without tmux (e.g. Windows)

Multiple Claude Code sessions still talk through team mode, but there's no tmux (e.g. on Windows).

**Capabilities:** persistent / cross-agent messaging / shared FS / scheduled jobs are available; parallel multi-role works but you have to manage multiple terminal windows by hand.

| Generic phrase | Concrete command |
|---------|---------|
| Notify \<Role\> | `SendMessage("role_name", content)` |
| Create worktree | `cd <repo> && git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main` |
| Commit code | Inside the worktree: `git add && git commit && git push` |
| Start fast-cron | `CronCreate({cron: "7,22,37,52 * * * *", prompt: "...", durable: false})` |
| Start slow-cron | `CronCreate({cron: "17 */2 * * *", prompt: "...", durable: false})` |
| Check role status | Ask via `SendMessage` (no tmux pane to look at) |
| Open PR | `gh pr create` (Teamlead only) |
| Merge PR | `gh pr merge <N> --squash` |

**Rule fit:**
- **Check role status**: there's no tmux pane to see everything at once, so you have to ask each role one by one through `SendMessage`. The tmux layout section in the workflow skill does not apply here.
- All other rules apply.

#### No team mode (single session)

A single Claude Code session, no team mode.

**Capabilities:** persistent / shared FS / scheduled jobs are available; cross-agent messaging and parallel multi-role are not.

| Generic phrase | Concrete command |
|---------|---------|
| Notify \<Role\> | Not needed — a single session switches roles serially |
| Create worktree | `cd <repo> && git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main` |
| Commit code | Inside the worktree: `git add && git commit && git push` |
| Start fast-cron | `CronCreate({cron: "7,22,37,52 * * * *", prompt: "...", durable: false})` — when cron fires, the current session runs the self-check |
| Start slow-cron | `CronCreate({cron: "17 */2 * * *", prompt: "...", durable: false})` — the drift audit is run by the current session |
| Check role status | Not needed — you are all the roles |
| Open PR | `gh pr create` (Teamlead only) |
| Merge PR | `gh pr merge <N> --squash` |

**Rule fit:**
- **Parallel multi-role**: not possible. A single session switches roles serially, one role at a time.
- **Ping protocol**: does not apply (no other agent to ping).
- **Parallel review subagents**: not supported. Reviews run serially.
- **Four-role co-signoff**: a single session signs off for each role one after another.

---

## Teammate vs subagent — they are not the same thing

A common confusion in Claude Code: people mix up "teammate" with "subagent". They look similar on the surface but are completely different topologies.

- **Every teammate is its own Claude Code process.** Architect, PM, Dev, QA, Teamlead — each runs as its own Claude Code instance with its own session, its own context, and its own tool budget. They communicate through `SendMessage` / `TaskCreate`, not through return values.
- **In-process vs tmux is a display mode, not a spawn topology.** Whether the teammate's pane is mounted inside the same tmux window or in a separate terminal does not change the fact that it is a separate Claude Code process. Tmux just decides where you see the output.
- **Subagents are different.** A subagent is spawned inside a single Claude Code process by the parent agent, runs to completion, and returns. It is a tool call, not a teammate. It has no persistent session, no cross-agent messaging, and dies when the task ends.

So the right mental model is:

| Concept | What it is | Lifecycle | Communicates via |
|---|---|---|---|
| **Teammate** | A separate Claude Code process per role | Long-lived session | `SendMessage` / `TaskCreate` |
| **Subagent** | A child task inside one Claude Code process | One-shot, returns to parent | Return value |

This matters for the rules:
- "One milestone, one PR; everyone stacks commits in the same worktree" assumes teammates that are persistent and can pull / commit independently. Subagents cannot replace this.
- "Ping/Pong silence detection" applies to teammates only, because subagents have a built-in completion signal — when they return, they are done.
- "Parallel review" via subagents is allowed (the parent fans out review subagents), but a teammate is the one who finally signs off.

If you find yourself using a subagent where the rule says "Notify \<Role\>", you have collapsed the topology. Step back and dispatch through `SendMessage` to the teammate instead.

---

## Ping / Pong silence detection (team mode only)

After dispatching work to a persistent agent, if there's no message back within 10 minutes, start the ping protocol:

1. **First ping** (≤10 min of silence): send "ping. Reply pong + one-line current progress within 5 min."
2. **Second ping** (≤15 min of silence): send "ping again. Are you still working? Reply within 5 min or I shut you down."
3. **Kill + respawn** (≤20 min of silence): `shutdown_request` → spawn a fresh subagent to take over.

**Threshold is tunable.** 10 min is the default. e2e debugging often takes 30 min of silence, which is normal. Schema migration silence of 10 min is unusual. The user can grant exceptions.

**Doesn't apply** to subagents. Subagents have their own completion signal, no ping needed.

## If you detect a missing capability

If you find that the current environment is missing team mode or tmux, send the prompt below to the user to help them upgrade:

### Missing team mode

> **Detected:** Agent teams is not enabled in this Claude Code.
>
> **Impact:** No multi-role parallel collaboration — all roles can only run serially, no cross-agent messaging (`SendMessage`), the ping protocol and parallel reviews are not available.
>
> **How to enable:**
>
> Agent teams is off by default. You can turn it on either way:
>
> **Option 1: environment variable**
> ```bash
> export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
> claude
> ```
>
> **Option 2: settings.json**
> ```bash
> # Edit ~/.claude/settings.json and add:
> # "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
> ```
>
> Once enabled, Claude Code gets the team-collaboration tools — `TeamCreate` / `SendMessage` / `TaskCreate` and so on. Requires Claude Code v2.1.32+.
>
> Reference: https://code.claude.com/docs/en/agent-teams

### Missing tmux (Linux / macOS)

> **Detected:** This environment doesn't have tmux.
>
> **Impact:** You can't manage multiple role panes through tmux — you can't watch every role's output at once, and the team-startup layout isn't available. Team-mode messaging itself still works.
>
> **How to install:**
> ```bash
> # macOS
> brew install tmux
>
> # Ubuntu / Debian
> sudo apt install tmux
> ```
>
> **Recommended way to bring up the team after install:**
> ```bash
> tmux new-session -s blueprintflow
> # Split panes, run claude in each one
> # (set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 first)
> tmux split-window -h
> tmux split-window -v
> ```
>
> Note: Windows doesn't support tmux natively. Use WSL (Windows Subsystem for Linux) to get it, or stay on the "Team mode without tmux" config.
