---
name: blueprintflow-team-roles
description: "Blueprintflow 6 角色 (Architect/PM/Dev/QA/Designer/Security) prompt 模板 + Teamlead 职责定义, Security 必备独立角色不允许 Architect 兼任, 满编 8 人配置示例 (3 Dev + Architect + PM + QA + Security + Teamlead), 实际可灵活合并但 Security 必独立。触发: 起团 spawn agents / 确认某角色职责边界 / 派活前选合适角色 / 角色冲突仲裁。反触发: 已知道派给谁的具体派活动作 (直接通讯) / 角色 prompt 模板已加载 / 单文件机械改动 / 不需多角色协作的 hotfix。"
version: 1.0.0
---

# Team Roles

> **角色 ≠ 人**：6 角色不要求 6 个 agent 或 6 个人。一个 agent/人可以承担多个角色（如 PM + Designer）。小团队可分担, **但 Security 必须独立, 不允许 Architect 兼任** (见下方 Security 段)。
>

6 个角色 + Teamlead 协调, 多 agent 协作做产品。每角色一个 prompt 模板, 起团按需 spawn (Security 必备, 不按需)。

## 全角色配置示例

满编 8 人示例 (满足所有职责独立 agent):

- 3 Dev
- 1 Architect
- 1 PM
- 1 QA
- **1 Security (必备 + 独立角色)**
- 1 Teamlead (协调, 不写代码)

Designer 按项目需要追加 (视觉新组件多的项目必备)。

### 实际灵活合并 (按 "角色 ≠ 人")

实际可按 "角色 ≠ 人" 原则, 一个 agent / 人承担多个角色, 减少满编人头:

- ✅ PM + Designer (产品立场跟视觉立场天然耦合)
- ✅ QA + Architect (架构 review 跟可测性 review 视角接近)
- ✅ Teamlead 兼任 Architect (小团队协调者也是架构主)
- ❌ **Architect + Security 不允许** (架构视角 ≠ 安全视角, 合并后两边失声)

满编 vs 实际灵活的关系: 满编是**角色边界示例**, 实际按团队规模合并, **但 Security 必须独立, 这是硬约束**。

## Security: 必备 + 独立角色

**所有代码改动必走 Security review** — 这是 2026 拍板的硬规, 不允许:
- ❌ "lazy spawn / 涉及敏感才拉" (旧规则, 已废)
- ❌ Architect 兼任 Security (架构视角 ≠ 安全视角, 合并后两边失声)
- ❌ "这个 milestone 不涉敏感跳过" (鉴权 / capability / cookie 域 / cross-org / admin god-mode 路径无处不在, 默认全审)

实战教训: 多次安全 bug (admin god-mode 漏审 / cookie 域错配 / cross-org 数据泄露) 都是 "看着不敏感所以没拉 Security" 留的口子。改成默认必审后, 这类口子封死。

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
Agent({ name: "architect", subagent_type: "general-purpose", prompt: <Architect prompt 模板> })
Agent({ name: "pm", ... })
Agent({ name: "dev-1", ... })
Agent({ name: "dev-2", ... })
Agent({ name: "dev-3", ... })
Agent({ name: "qa", ... })
Agent({ name: "security", ... })  # 必备, 独立角色, 不允许 Architect 兼任
# 按需:
Agent({ name: "designer", ... })
```

> **实战案例（Borgee）：** 团队按 X 马代号 (feima/yema/zhanma/liema 等) 起团是 Borgee 内部命名习惯, 通用 blueprintflow 团队按角色名 (architect/pm/dev/qa/security) 起即可。

## Teamlead 职责 + 反模式

### 职责
- **协调, 不动手**: 派活给 6 角色 + general-purpose agent (杂活: merge / patch lint / 仓库 patch). 不自己 Bash / Write / Edit 仓库。
- **合成多源诊断**: QA + PM + Architect 报告冲突时, 不自己脑补合并 — 戳真因方 (e.g. 让 Dev 反证), 收齐反证再派活。
- **memory of 决策**: 重要决策 (撤回某条建议 / 接受 dev 反证) 要广播给相关 reviewer, 防止 stale instruction 浮在他们 inbox。
- **效率最大化授权**: 在不打破章程规则 (4 件套 / 双 review / migration v 号 sequencing 等) 不损质量 (反约束 grep 机器化锚 / byte-identical 对照) 的前提下, 灵活安排. 例如: 多 PR 一波 batch merge / review subagent 并行 / acceptance 与 stance 跨界互写 / chore PR 单 reviewer 跳双 review / 大波 LGTM 信号到达后立即派 batch 处理. 不要为流程而流程, 但流程的"为什么"得守住.
- **沉默检测**：如果角色无响应，处理方式取决于运行环境（见 `blueprintflow-runtime-adapter`）
- **issue triage 分发**: cron 扫 untriaged GitHub issues 时 Teamlead 先判分发 — 代码改进/tech-debt → Architect, 新功能 → PM, bug → QA。Teamlead 是分发, **不下场判类型** (跟"协调不动手"同立场)。详见 `blueprintflow-issue-triage`。

### 反模式
- ❌ **subagent 同步阻塞**: 派 general-purpose agent 必须 `run_in_background: true`, 否则 teamlead 卡在等结果上, 不能继续协调。背景: subagent 干杂活 (merge / lint patch) 跟 teamlead 主线 (协调派活 / 收 LGTM / 合成诊断) **本来就独立**, 没理由阻塞。
- ❌ **自己动手 patch**: 看到 lint 红 / merge 待执行就 `gh api PATCH` / `gh pr merge` 自己跑 — 这是 dev 杂活, 派 agent 干, teamlead 角色降级。
- ❌ **合成多源诊断时脑补因果**: 多个 reviewer 给的现象拼起来时, 容易脑补 "A 因为 B 所以 C", 真因可能在 D。让真因方反证, 不替代他做 root cause。
- ❌ **不广播撤回**: 改主意了不告诉所有人, reviewer 拿着 stale instruction 继续做无用功 (PM 跑 grep / QA改 content-lock)。
