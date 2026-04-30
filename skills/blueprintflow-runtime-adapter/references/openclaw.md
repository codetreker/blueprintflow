# OpenClaw 适配

### OpenClaw（多 agent）

按以下决策树确认配置：

```
我跟其他 agent 共享文件系统吗？
├─ 是（同一台机器/实例，未开 sandbox）→ 「同实例」配置（见第 1 段）
└─ 否（不同机器，或开了 sandbox）→ 「跨实例」配置（见第 2 段）
```

确认后只读对应的配置段。

#### 同实例多 agent（共享文件系统）

多个 agent 运行在同一台机器/实例上，未开启 sandbox 时共享文件系统。

**能力：** ✅ 持久化 ✅ 跨 agent 通讯 ✅ 共享 fs ✅ 定时调度 ✅ 并行多角色

| 通用描述 | 具体命令 |
|---------|---------|
| 通知 \<Role\> | `sessions_send(sessionKey, message)` — 同实例内 agent 间直接发消息 |
| 创建 worktree | `exec("git worktree add .worktrees/<milestone> ...")` |
| 提交代码 | 在 worktree 里 `exec("git add -A && git commit && git push")` |
| 启动 fast-cron | 在 OpenClaw 设置 cron：`/cron add "7,22,37,52 * * * *" "<fast-cron prompt>"` 或在 HEARTBEAT.md 里加巡检项 |
| 启动 slow-cron | 在 OpenClaw 设置 cron：`/cron add "17 */2 * * *" "<slow-cron prompt>"` 或单独配置 cron job |
| 查看角色状态 | `sessions_list` / `sessions_history` |
| 开 PR | `exec("gh pr create")` (Teamlead 唯一) |
| Merge PR | `exec("gh pr merge <N> --squash")` |

#### 跨实例 / Discord 协作（不共享文件系统）

多个 agent 分布在不同机器上，通过 Discord 频道协作。

**能力：** ✅ 持久化 ✅ 跨 agent 通讯（Discord） ❌ 共享 fs ✅ 定时调度 ✅ 并行多角色

| 通用描述 | 具体命令 |
|---------|---------|
| 通知 \<Role\> | `message(action=send, target=<channel-id>, message=content)` — 通过 Discord 频道 |
| 创建 worktree | 各 agent 本地 `git worktree add`，通过 `git push/pull` 同步 |
| 提交代码 | 本地 commit + `git push`，其他 agent `git pull` 获取 |
| 启动 fast-cron | 在 OpenClaw 设置 cron：`/cron add "7,22,37,52 * * * *" "<fast-cron prompt>"` 或在 HEARTBEAT.md 里加巡检项 |
| 启动 slow-cron | 在 OpenClaw 设置 cron：`/cron add "17 */2 * * *" "<slow-cron prompt>"` 或单独配置 cron job |
| 查看角色状态 | 频道消息历史 / `message(action=read)` |
| 开 PR | `exec("gh pr create")` (Teamlead 唯一) |
| Merge PR | `exec("gh pr merge <N> --squash")` |

**规则适配（两种形态通用）：**
- ⚠️ **Ping 协议**：如果角色无响应，Teamlead 先自行排查（检查 session 状态、重发消息）；无法解决 → escalate 到用户处理
- ⚠️ **跨实例文件同步**：不共享 fs 时，"全员叠 commit"改为各 agent 独立 commit + push，Teamlead 在开 PR 前 pull 确认无冲突

---
