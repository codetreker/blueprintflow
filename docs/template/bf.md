---
Id: <可读的工作对象 id；跟 bf-wo 目录名一致，建议 kebab-case>
Desc: <一句话描述这次工作想完成什么>
Pack: <pack id；必须能在 bf list-packs 输出里找到>
State: Draft|Accepted|Implementing|Completed
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

# Goal

这次工作的整体目标。一两句话讲清楚要实现什么。

## Requirement

必须达成的目标，每条都是用户可以观察到的成果，不是实现细节。

## Acceptance Criteria

整个蓝图的验收标准。

格式规则：
- 必须是 markdown checkbox 列表；未通过是 `[ ]`，通过是 `[x]`。
- checkbox 状态由 bf-harness 在 verify 过程中翻动，LLM 不能直接改。
- 每条带一个稳定的 id（推荐 AC-1、AC-2 这种形式）和验收这条标准所需的能力（capability）。
- bf-harness 会用 capability 反查 roles 目录里谁有此能力，把对应的 role 拉起来做 review。
- 验收能力跟 task spec.md 顶部的 Capability（执行能力）不是一回事；这里讲的是谁来验收，不是谁来做。

- [ ] {id1}|{capability}: 一条独立可验证的验收标准
- [ ] {id2}|{capability}: 另一条验收标准

## Boundary

明确不在本次工作范围内的事情。这一节是为了防止 breakdown 跑偏，也让 reviewer 能用它判断某个 task 是否越界。

## Task List

任务列表。按执行顺序排列；依赖关系写在冒号后面，多个依赖用逗号分开。

- task-id-1
- task-id-2
- task-id-3: task-id-1, task-id-2   // task-id-3 依赖 task-id-1 和 task-id-2 都完成
