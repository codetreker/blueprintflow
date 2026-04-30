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

多个 Claude Code session 通过 team mode 通讯，tmux 管理多 pane。

**能力：** ✅ 持久化 ✅ 跨 agent 通讯 ✅ 共享 fs ✅ 定时调度 ✅ 并行多角色

| 通用描述 | 具体命令 |
|---------|---------|
| 通知 \<Role\> | `SendMessage("role_name", content)` |
| 创建 worktree | `cd <repo> && git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main` |
| 提交代码 | 在 worktree 里 `git add && git commit && git push` |
| 启动 fast-cron | `CronCreate({cron: "7,22,37,52 * * * *", prompt: "...", durable: false})` |
| 启动 slow-cron | `CronCreate({cron: "17 */2 * * *", prompt: "...", durable: false})` |
| 查看角色状态 | 看 tmux pane 输出 / `SendMessage` 问 |
| 开 PR | `gh pr create` (Teamlead 唯一) |
| Merge PR | `gh pr merge <N> --squash` |

**规则适配：** 全部规则适用。

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
