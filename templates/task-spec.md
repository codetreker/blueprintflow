---
State: Draft|Ready|Tasking|Completed
Pipeline: <pipeline id>
Pack: <pack id>
Desc: <任务的一句话描述>
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

<!--
frontmatter 字段说明：

- State：由 bf-harness 维护。LLM 不能直接修改。
- Pipeline：这个 task 使用的执行流程。必须能在 `bf list-pipelines --pack <pack id>` 输出里找到。
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
- frontmatter 顶部的 Pipeline 是**执行流程**（doer/reviewer 需要按哪个 pipeline 做）。
- 这里 AC 行上的 capability 是**验收能力**（reviewer 验收这条标准需要什么能力）。
- 执行阶段的 doer capability 由 pipeline stage 定义；task spec 不再填单个执行 Capability。

- [ ] {id1}|{capability}: 验收标准 1
- [ ] {id2}|{capability}: 验收标准 2

## Evidence

每条 task AC 必须至少有一条 evidence requirement。Evidence 是 spec 阶段写入并在 accept 后锁定的验收证据合同；执行阶段只能产出证据，不能改这里的要求。

格式规则：
- `## Evidence` section 必须存在，不能省略。
- 必须是 markdown 列表。
- 每条带稳定 id、对应 AC id、证据类型和证据要求。
- 同一个 task spec 内 evidence id 必须唯一。
- 对应 AC id 必须是本 task `Acceptance Criteria` 里存在的 id。
- 证据类型只能是 `command`、`file`、`artifact`、`review-note`、`screenshot`。
- 证据要求不能为空。

- {evidence-id}|{ac-id}|{kind}: 证据要求
- EV-1|AC-1|command: bash test/run-all.sh
- EV-2|AC-2|review-note: reviewer confirms the edge case manually

## Boundary

明确不在这个任务范围内的事情。doer 执行时遇到模糊的边界，先看这里再判断。
