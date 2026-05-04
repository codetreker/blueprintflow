---
name: blueprintflow-runtime-adapter
description: Blueprintflow 运行时适配层, 按 agent 环境能力组合给出通讯/文件/调度/观察/沉默检测的具体操作方式 (e.g. tmux + SendMessage 替代 / cron 实现 / idle 检测路径)。触发: 首次启动 blueprintflow 团队需确认运行模式 / 切换 agent 环境 (本地 ↔ 云 / 通讯通道更换) / 沉默检测协议拿不准。反触发: 蓝图/Phase/milestone 业务流程 (各自走对应 skill) / 已配好运行时直接派活 / 单文件 commit / hotfix。
version: 1.0.0
---

# Runtime Adapter

Blueprintflow 的规则（蓝图先 freeze、4 件套、立场漂移防御、一 milestone 一 PR）跟运行环境无关。但**怎么执行**这些规则，取决于 agent 环境的能力。

本 skill 集中管理运行时差异——其他 skill 只写"做什么"（如"通知 Dev 开始实施"），本 skill 定义"怎么做"。

## 能力维度

5 个能力维度决定你的运行模式：

| 能力 | 说明 |
|------|------|
| **持久化 session** | agent 能长期运行，保持上下文，接收消息 |
| **跨 agent 通讯** | agent 之间能互发消息（不只是父子返回值） |
| **共享文件系统** | 多 agent 能访问同一个文件系统 / worktree |
| **定时调度** | 能创建定时任务（cron / heartbeat） |
| **并行多角色** | 能同时运行多个角色 agent |

## 词汇表

规则 skill 里的通用描述 → 本 adapter 给出具体命令：

| 通用描述 | 含义 |
|---------|------|
| **通知 \<Role\>** | 派活、报告完成、review 通知等任何跨角色消息 |
| **创建 worktree** | Teamlead 为 milestone 创建工作目录 |
| **提交代码** | 角色在 worktree 里 commit + push |
| **启动巡检** | 设置 fast-cron (idle 派活) 和 slow-cron (偏差 audit) |
| **查看角色状态** | Teamlead 检查各角色是否在工作、是否 idle |

---

## 核心规则（所有环境通用）

无论什么环境，以下规则始终适用：
- 蓝图先 freeze 再开工
- 4 件套（spec / stance / acceptance / content-lock）
- 立场漂移 5 层防御
- 一 milestone 一 PR
- 立场写不出反约束 = 不成立
- PR 合并永远不 admin bypass（标准 squash merge）

## 环境适配（按需加载）

启动 blueprintflow 时，确认我的运行环境，**只读对应的那一个适配文件**：

| 我的环境 | 适配文件 | 状态 |
|-------------|---------|------|
| **Claude Code** | `references/claude-code.md`（区分 team+tmux / team无tmux / 无team） | ✅ 已验证 |
| **OpenClaw** | `references/openclaw.md`（区分同实例 / 跨实例） | ✅ 已验证 |
| **Codex** | `references/codex.md` | ⚠️ 未实跑验证 |
| **其他** | `references/basic.md` | ✅ 通用 |

读完适配文件后，后续 skill 里的通用描述按对照表执行。切换 agent 环境时重新选择。

## 调用方式

首次启动 blueprintflow 时：
```
follow skill blueprintflow-runtime-adapter
确认运行模式 → 加载对照表
```

