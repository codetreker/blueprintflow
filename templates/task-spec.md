---
State: Draft|Ready|Tasking|Completed
Capability: <required-capability>
Pack: <pack id>
Desc: <任务的一句话描述>
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

<!--
frontmatter 字段说明：

- State：由 bf-harness 维护。LLM 不能直接修改。
- Capability：完成这个任务所需的能力。只能填一个。LLM 在拿到 bf-harness next 返回时，会用这个 capability 去 roles 目录反查，并选择最合适的 role 作为 doer。
- Pack：跟所属 bf.md 的 Pack 一致。
- Desc：一句话描述，让 doer 一眼看出在做什么。
-->

# Task

详细的任务描述。doer 主要参考这里来理解要做什么。

## Requirements

- 必须满足的具体要求
- 每条都应该是可以从外部观察的成果

## Acceptance Criteria

这个任务的验收标准。

格式跟 bf.md 一致：稳定 id + capability marker + 验收标准描述。

注意区分两种 capability：
- frontmatter 顶部的 Capability 是**执行能力**（doer 完成任务需要什么能力）。
- 这里 AC 行上的 capability 是**验收能力**（reviewer 验收这条标准需要什么能力）。
- 这两种 capability 通常不相同。例如：执行能力可能是 implementation，验收能力可能是 verification 或 security-review。

- [ ] {id1}|{capability}: 验收标准 1
- [ ] {id2}|{capability}: 验收标准 2

## Boundary

明确不在这个任务范围内的事情。doer 执行时遇到模糊的边界，先看这里再判断。
