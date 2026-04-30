# Blueprintflow Task Board

> **Owner** = 此刻球在谁手上，随状态流转变化。所有任务必须有 Owner，无主任务不允许存在。
> 对应关系：Backlog/Ready/讨论中→Team Lead，In Progress→Dev，In Review→Team Lead，验收→QA，Done→Team Lead。

| ID | 任务 | 状态 | Owner | PR |
|----|------|------|-------|----|
| BPF-001 | 通用化改造（解除 Borgee 绑定） | Done | Architect | [#1](https://github.com/codetreker/blueprintflow/pull/1) |
| BPF-002 | Description 重写（做什么 + 触发条件 + 触发词） | Done | Architect | [#2](https://github.com/codetreker/blueprintflow/pull/2) |
| BPF-003 | 角色 → Role 名 + "角色≠人" 说明 | Done | Architect | [#3](https://github.com/codetreker/blueprintflow/pull/3) |
| BPF-004 | team-roles prompt 模板：/tmp clone → git worktree | In Progress | Architect | [#5](https://github.com/codetreker/blueprintflow/pull/5) |
| BPF-005 | 工作量/时间评估按 agent 效率 | Done | Architect | [#4](https://github.com/codetreker/blueprintflow/pull/4) |
| BPF-006 | 区分工作模式（subagent/CC team/真多 agent/tmux） | Ready | Architect | — |
| BPF-007 | Service 项目每个 milestone deploy 到 test 环境验证 | Ready | Architect | — |
| BPF-009 | skill review checklist 加渐进式披露 tradeoff 评估 | Done | Architect | [#7](https://github.com/codetreker/blueprintflow/pull/7) |
| BPF-010 | Review 所有 skill：哪些需要渐进式披露拆 references | Ready | Architect | — |
| BPF-011 | fast-cron PR blocker 处理路由（conflict→subagent, CI fail→author） | In Progress | Architect | [#8](https://github.com/codetreker/blueprintflow/pull/8) |
| BPF-013 | Teamlead 必须保证 PROGRESS 准确：反模式——已完成的还标 TODO / 未完成的标 Done | Ready | Architect | — |
| BPF-014 | Phase exit gate 加 PROGRESS 完整性检查：所有任务是否已完成并打勾，未勾的必须逐条确认 | Ready | Architect | — |
