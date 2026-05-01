---
name: blueprintflow-team-roles
description: Blueprintflow 6 角色 prompt 模板（架构/PM/Dev/QA/设计/安全）+ Teamlead 职责定义。前提：项目已采用 blueprintflow 工作流。触发词：起团、spawn agents、角色分工、职责边界。触发场景：起团 spawn agents 时，或需要确认某角色职责时。
version: 1.0.0
---

# Team Roles

> **角色 ≠ 人**：6 角色不要求 6 个 agent 或 6 个人。一个 agent/人可以承担多个角色（如 Architect + Security、PM + Designer）。小团队 2-3 人即可分担全部角色。角色定义的是职责边界，不是人头。
>

6 个角色 + Teamlead 协调, 多 agent 协作做产品。每角色一个 prompt 模板, 起团按需 spawn。

## Teamlead (协调, facilitator)

**不写代码**, 只协调:
- 派活 / 监督进度 / 协议守门
- 跨角色冲突仲裁
- PR review 路径分配
- merge agent 调度
- cron 巡检 (fast 15min idle 派活 / slow 2-4h 偏差 audit)

不需要 spawn (Teamlead 通常是顶层 agent / 你自己)。

## 6 角色 prompt 模板

确认你的角色后，只读对应的 prompt 文件：

| 角色 | Prompt 文件 |
|------|-----------|
| Architect（架构师） | `references/architect.md` |
| PM（产品） | `references/pm.md` |
| Dev（开发） | `references/dev.md` |
| QA（测试） | `references/qa.md` |
| Designer（设计） | `references/designer.md` |
| Security（安全） | `references/security.md` |

> **渐进式披露**：只读你的角色 prompt，不加载其他角色。

## 通用协议

### Worktree 协议

- 所有角色在 Teamlead 创建的 milestone worktree 里工作 (`<repo-root>/.worktrees/<milestone>`)
- 一个 milestone 一个 worktree, 全员叠 commit
- 不开 `/tmp/` 临时 clone (已弃用, 参见 `blueprintflow:git-workflow`)

### PR 协议

- 顶部 4 行裸 metadata + `## Acceptance` + `## Test plan` H2 段
- author=lead-agent 不能 self-approve, 用 `gh pr comment <num> --body "LGTM"` 等同
- 双 review 路径见 `blueprintflow:pr-review-flow`

### 立场漂移 5 层防御 (硬约束)

1. spec brief grep 反查 (反约束)
2. acceptance template 反查锚 (机器化)
3. stance checklist 黑名单 grep
4. content-lock byte-identical
5. PR review 跨文件 cross-check

## 起团示例

```
Agent({ name: "feima", subagent_type: "general-purpose", prompt: <Architect prompt 模板> })
Agent({ name: "yema", ... })
Agent({ name: "zhanma", ... })
Agent({ name: "liema", ... })
# 按需:
Agent({ name: "banma", ... })
Agent({ name: "aima", ... })
```

## Teamlead 职责 + 反模式

### 职责
- **协调, 不动手**: 派活给 6 角色 + general-purpose agent (杂活: merge / patch lint / 仓库 patch). 不自己 Bash / Write / Edit 仓库。
- **合成多源诊断**: QA + PM + Architect 报告冲突时, 不自己脑补合并 — 戳真因方 (e.g. 让 Dev 反证), 收齐反证再派活。
- **memory of 决策**: 重要决策 (撤回某条建议 / 接受 dev 反证) 要广播给相关 reviewer, 防止 stale instruction 浮在他们 inbox。
- **效率最大化授权**: 在不打破章程规则 (4 件套 / 双 review / migration v 号 sequencing 等) 不损质量 (反约束 grep 机器化锚 / byte-identical 对照) 的前提下, 灵活安排. 例如: 多 PR 一波 batch merge / review subagent 并行 / acceptance 与 stance 跨界互写 / chore PR 单 reviewer 跳双 review / 大波 LGTM 信号到达后立即派 batch 处理. 不要为流程而流程, 但流程的"为什么"得守住.
- **沉默检测**：如果角色无响应，处理方式取决于运行环境（见 `blueprintflow-runtime-adapter`）

### 反模式
- ❌ **subagent 同步阻塞**: 派 general-purpose agent 必须 `run_in_background: true`, 否则 teamlead 卡在等结果上, 不能继续协调。背景: subagent 干杂活 (merge / lint patch) 跟 teamlead 主线 (协调派活 / 收 LGTM / 合成诊断) **本来就独立**, 没理由阻塞。
- ❌ **自己动手 patch**: 看到 lint 红 / merge 待执行就 `gh api PATCH` / `gh pr merge` 自己跑 — 这是 dev 杂活, 派 agent 干, teamlead 角色降级。
- ❌ **合成多源诊断时脑补因果**: 多个 reviewer 给的现象拼起来时, 容易脑补 "A 因为 B 所以 C", 真因可能在 D。让真因方反证, 不替代他做 root cause。
- ❌ **不广播撤回**: 改主意了不告诉所有人, reviewer 拿着 stale instruction 继续做无用功 (PM 跑 grep / QA改 content-lock)。
