# Blueprintflow Task Board

> **Owner** = 此刻球在谁手上，随状态流转变化。所有任务必须有 Owner，无主任务不允许存在。
> 对应关系：Backlog/Ready/讨论中→Team Lead，In Progress→Dev，In Review→Team Lead，验收→QA，Done→Team Lead。

| ID | 任务 | 状态 | Owner | PR |
|----|------|------|-------|----||
| BPF-001 | 通用化改造：解绑 Borgee 特定内容 | In Review | 飞马 | [#1](https://github.com/codetreker/blueprintflow/pull/1) |
| BPF-002 | Description 重写：统一「做什么 + 触发条件」结构 | Ready | 飞马 | — |
| BPF-003 | X马→Role：角色名通用化 + Role ≠ Person 明确化 | Ready | 飞马 | — |
| BPF-004 | team-roles prompt 模板：/tmp clone → git worktree 统一 | Ready | 飞马 | — |
| BPF-005 | 工作量/时间评估按 agent 效率而非人类效率（如 ≤3天/≤500行 等约束重新标定） | Ready | 飞马 | — |
| BPF-006 | 区分工作模式：subagent / Claude Code team / OpenClaw 多 agent / tmux 等，规则尽量通用，特定特性显式标注模式依赖 | Ready | 飞马 | — ||
| BPF-001 | 通用化改造（解除 Borgee 绑定） | In Review | 飞马 | [#1](https://github.com/codetreker/blueprintflow/pull/1) |
| BPF-002 | Description 重写（做什么 + 触发条件） | Ready | 飞马 | — |
| BPF-003 | X马 → Role 名 + "角色≠人" 说明 | Ready | 飞马 | — |
| BPF-004 | team-roles prompt 模板：/tmp clone → git worktree | Ready | 飞马 | — |
| BPF-005 | 工作量/时间评估按 agent 效率，不按人类 | Ready | 飞马 | — |
| BPF-006 | 区分工作模式（subagent/CC team/真多 agent/tmux），skill 尽量通用，特性相关部分标注模式 | Ready | 飞马 | — |
