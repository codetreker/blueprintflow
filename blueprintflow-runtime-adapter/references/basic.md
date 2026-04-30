# 基础模式（subagent / 单 agent）

**任何 coding agent 都能跑的最小可用集。**

**能力：** ⚠️ 持久化（任务级） ❌ 跨 agent 通讯 ⚠️ 共享 fs（可能有） ❌ 定时调度 ❌ 并行多角色

**操作方式：**

| 通用描述 | 具体方式 |
|---------|---------|
| 通知 \<Role\> | 不需要 — 单 agent 串行切换角色，内部上下文传递 |
| 创建 worktree | `git worktree add` 在本地 |
| 提交代码 | 本地 commit + push |
| 启动 fast-cron | ❌ 跳过 — 单 agent 每完成一个任务后自检 idle 状态 |
| 启动 slow-cron | ❌ 跳过 — 每 N 个任务后做一次偏差 audit |
| 查看角色状态 | 不需要 — 单 agent 知道自己在干什么 |
| 开 PR | `gh pr create` |
| Merge PR | `gh pr merge <N> --squash` |

**规则适配：**

| 规则 | 在你这里怎么执行 |
|------|---------------|
| 代码提交 | 单 agent 按角色依次 commit，每次切换角色前 commit 上一个的工作 |
| 巡检 | 不用 cron，每完成一个任务后自检 idle 状态 |
| Ping 协议 | 不适用（只有你自己） |
| Review | 串行 review：先以 Architect 视角审，再以 QA 视角审 |
| 联签 | 按角色逐一签字 |

> 核心规则见入口 SKILL.md「核心规则」段。

---
