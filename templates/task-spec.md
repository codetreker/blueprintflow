---
State: Draft|Ready|Tasking|Completed
Pipeline: <pipeline id>
Pack: <pack id>
Desc: <任务的一句话描述>
Requires-Worktree: true|false
Branch:
Worktree:
Pull-Request:
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

<!--
frontmatter 字段说明：

- State：由 bf-harness 维护。LLM 不能直接修改。
- Pipeline：这个 task 使用的执行流程。必须能在 `bf list-pipelines --pack <pack id>` 输出里找到。
- Pack：跟所属 bf.md 的 Pack 一致。
- Desc：一句话描述，让 task driver 一眼看出在做什么。
- Requires-Worktree：严格填写 `true` 或 `false`。在 Git project 里会修改 repo 代码或文档的 task 填 `true`；planning/review-only/non-repo task 填 `false`。
- Branch / Worktree / Pull-Request：harness-owned execution metadata。Draft/Ready 时保持空值，LLM 不直接修改。
-->

# Task

任务的 scope contract。这里说明这个 task 要完成什么、由谁负责哪段范围、
交付给谁、做到什么状态才算完成。这里不是详细 implementation design；
具体文件、命令参数、内部 API、migration 策略和实现顺序，除非已经是用户
接受的 contract 或 Evidence 要求，否则留给执行阶段的 design artifact。

## Requirements

- 必须满足的具体要求
- 每条都应该是可以从外部观察的成果
- 不要把未验证的实现细节写成要求；写可观察结果和边界

## Acceptance Criteria

这个任务的验收标准。

格式跟 bf.md 一致：稳定 id + capability marker + 验收标准描述。

注意区分两种 capability：
- frontmatter 顶部的 Pipeline 是**执行流程**（task driver/reviewer 需要按哪个 pipeline 做）。
- 这里 AC 行上的 capability 是**验收能力**（reviewer 验收这条标准需要什么能力）。
- 执行阶段的 stage-owner capability 由 pipeline stage 定义；task spec 不再填单个执行 Capability。

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

明确不在这个任务范围内的事情。task driver 执行时遇到模糊的边界，先看这里再判断。
如果这里没有说明 owner、handoff 或 terminal state，spec review 应该要求补清楚。
