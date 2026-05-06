# Claude Code 适配

### Claude Code

Claude Code 有 3 种配置组合。按以下决策树确认你的配置：

```
我有 team mode 吗？
├─ 没有 → 「无 team mode」配置（见下方第 3 段）
└─ 有 → 我在 tmux 里运行吗？
    ├─ 没有 → 「Team mode 无 tmux」配置（见下方第 2 段）
    └─ 有 → 「Team mode + tmux」配置（见下方第 1 段）
```

确认后只读对应的配置段。

#### Team mode + tmux（全能力）

每个 teammate 都是**独立的 Claude Code 进程** (`claude --agent-id <name>@<team>` 启动), 各自独立 context window 和 token 配额. lead spawn teammate 时, Claude Code 自动起 child claude 进程并加入共享 mailbox; 在 tmux session 内, 默认显示模式是 split-pane, 每 teammate 自动占一个 pane.

通讯走 `SendMessage` (背后是文件 mailbox `~/.claude/teams/<team>/inboxes/<name>.json` — 实测观察, 实验功能内部实现可能随版本变), 不是 tmux send-keys.

**能力：** ✅ 持久化 ✅ 跨 agent 通讯 ✅ 共享 fs ✅ 定时调度 ✅ 并行多角色

| 通用描述 | 具体命令 |
|---------|---------|
| 起团 | lead 在 tmux session 内: `TeamCreate({team_name})` + `Agent({team_name, name, subagent_type, run_in_background: true, prompt})` × N. Claude Code 自动起 child claude 进程并布局到 tmux pane |
| 通知 \<Role\> | `SendMessage("role_name", content)` |
| 创建 worktree | `cd <repo> && git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main` |
| 提交代码 | 在 worktree 里 `git add && git commit && git push` |
| 启动 fast-cron | `CronCreate({cron: "7,22,37,52 * * * *", prompt: "...", durable: false})` |
| 启动 slow-cron | `CronCreate({cron: "17 */2 * * *", prompt: "...", durable: false})` |
| 查看角色状态 | 看 tmux pane 输出 / `SendMessage` 问 |
| 开 PR | `gh pr create` (Teamlead 唯一) |
| Merge PR | `gh pr merge <N> --squash` |

**display mode 设置** (`~/.claude/settings.json`):

- `teammateMode: "auto"` (默认) — 在 tmux session 内自动用 split-pane, 否则用 in-process
- `teammateMode: "tmux"` — 强制 split-pane (要求 tmux 或 iTerm2)
- `teammateMode: "in-process"` — 单 terminal, 用 Shift+Down 在不同 teammate 之间切换 (teammate 仍是独立 instance, 只是显示叠在一个 terminal 里)

**前置**: agent teams 是实验功能, 必须开 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (env 或 settings.json), 需要 Claude Code v2.1.32+.

**规则适配：** 全部规则适用。

**反模式**: ❌ 把 teammate 跟 subagent 当成同一个东西. subagent 是 lead session 内 spawn 的 Task, 跟 lead 共享 context, 只能 report 回 lead; teammate 是独立 Claude Code 进程, 各自 1M context, 互相通过 mailbox 直接通讯. 不要互换术语, 也不要假设 teammate 能看到 lead 的对话历史.

#### Team mode 无 tmux（如 Windows）

多个 Claude Code session 通过 team mode 通讯，但没有 tmux（如 Windows 环境）。

**能力：** ✅ 持久化 ✅ 跨 agent 通讯 ✅ 共享 fs ✅ 定时调度 ⚠️ 并行多角色（需手动管理多终端）

| 通用描述 | 具体命令 |
|---------|---------|
| 通知 \<Role\> | `SendMessage("role_name", content)` |
| 创建 worktree | `cd <repo> && git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main` |
| 提交代码 | 在 worktree 里 `git add && git commit && git push` |
| 启动 fast-cron | `CronCreate({cron: "7,22,37,52 * * * *", prompt: "...", durable: false})` |
| 启动 slow-cron | `CronCreate({cron: "17 */2 * * *", prompt: "...", durable: false})` |
| 查看角色状态 | `SendMessage` 问（没有 tmux pane 可看） |
| 开 PR | `gh pr create` (Teamlead 唯一) |
| Merge PR | `gh pr merge <N> --squash` |

**规则适配：**
- ⚠️ **查看角色状态**：没有 tmux pane 一览全局，需要逐个 `SendMessage` 问。workflow skill 里的 tmux 布局段不适用
- 其他规则全部适用

#### 无 team mode（单 session）

单个 Claude Code session，没有 team mode。

**能力：** ✅ 持久化 ❌ 跨 agent 通讯 ✅ 共享 fs ✅ 定时调度 ❌ 并行多角色

| 通用描述 | 具体命令 |
|---------|---------|
| 通知 \<Role\> | 不需要 — 单 session 串行切换角色 |
| 创建 worktree | `cd <repo> && git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main` |
| 提交代码 | 在 worktree 里 `git add && git commit && git push` |
| 启动 fast-cron | `CronCreate({cron: "7,22,37,52 * * * *", prompt: "...", durable: false})` — cron 触发时由当前 session 执行自检 |
| 启动 slow-cron | `CronCreate({cron: "17 */2 * * *", prompt: "...", durable: false})` — 偏差 audit 由当前 session 执行 |
| 查看角色状态 | 不需要 — 自己就是所有角色 |
| 开 PR | `gh pr create` (Teamlead 唯一) |
| Merge PR | `gh pr merge <N> --squash` |

**规则适配：**
- ❌ **并行多角色**：单 session 串行切换，一次一个角色
- ⚠️ **Ping 协议**：不适用（没有其他 agent 可 ping）
- ⚠️ **并行 review subagent**：不支持并行，串行 review
- ⚠️ **4 角色联签**：单 session 按角色逐一签字

---

---

## Ping/Pong 沉默检测（仅 team mode）

派活给 persistent agent 后, 如 10min 内无消息回报, 启动 ping 协议:

1. **第一次 ping** (≤10min 沉默): 通知 "ping. 5min 内回 pong + 当前进度一句话"
2. **第二次 ping** (≤15min 沉默): 通知 "再次 ping. 是否在干活? 5min 内回报或我 shutdown."
3. **Kill + 重 spawn** (≤20min 沉默): shutdown_request → spawn 新 subagent 接活

**阈值可调**：10min 是默认, e2e 调试 30min 沉默正常, schema migration 10min 异常。用户拍板可豁免。

**不适用**：subagent 有自己的完成信号, 不用 ping。

## 如果你检测到缺少能力

如果你发现当前环境缺少 team mode 或 tmux，把下面的提示发给用户，帮他们升级：

### 缺少 Team mode

> **检测到：** 当前 Claude Code 未启用 agent teams。
>
> **影响：** 无法多角色并行协作——所有角色只能串行切换，没有跨 agent 通讯（SendMessage），Ping 协议和并行 review 不可用。
>
> **如何启用：**
>
> Agent teams 默认关闭，需要手动开启。两种方式任选其一：
>
> **方式 1：环境变量**
> ```bash
> export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
> claude
> ```
>
> **方式 2：settings.json**
> ```bash
> # 编辑 ~/.claude/settings.json，添加：
> # "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
> ```
>
> 启用后 Claude Code 会获得 TeamCreate / SendMessage / TaskCreate 等团队协作工具。需要 Claude Code v2.1.32+。
>
> 参考：https://code.claude.com/docs/en/agent-teams

### 缺少 tmux（Linux / macOS）

> **检测到：** 当前环境没有 tmux。
>
> **影响：** 无法用 tmux 管理多个角色 pane——看不到所有角色的实时输出，起团布局不可用。Team mode 通讯不受影响。
>
> **如何安装：**
> ```bash
> # macOS
> brew install tmux
>
> # Ubuntu / Debian
> sudo apt install tmux
> ```
>
> **安装后的推荐起团方式：**
> ```bash
> tmux new-session -s blueprintflow
> # 分多个 pane，每个跑 claude（需先设 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1）
> tmux split-window -h
> tmux split-window -v
> ```
>
> ⚠️ Windows 不原生支持 tmux。可以用 WSL (Windows Subsystem for Linux) 获得支持，或使用"Team mode 无 tmux"配置继续工作。
