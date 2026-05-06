---
name: blueprintflow-issue-triage
description: "定时扫描 GitHub issues, Teamlead 先判分发到 Architect/PM/QA 做 triage (打 type/状态 label + 派 milestone), 是 blueprint-iteration 状态机的入口闸。触发: cron 周期到期 / 新 issue 进来未分类 / 用户提需求落 issue 后。反触发: 已有 `triaged` label 的 issue / closed 的 issue (wont-fix/archived) / type:question 等待用户回复中 / PR 维度卡点 (走 fast-cron / slow-cron)。"
version: 1.0.0
---

# Issue Triage

GitHub issues 是 backlog SSOT (见 `blueprintflow-blueprint-iteration`), 但新 issue 进来不会自动分类。本 skill 定义 cron 扫 issue + Teamlead 先判分发 + 角色分类的闸。

跟 `blueprintflow-teamlead-fast-cron-checkin` (PR 维度) / `blueprintflow-teamlead-slow-cron-checkin` (蓝图偏差 audit 维度) 平行不重叠 — issue-triage 是 **issue 维度**。

## 职责

扫所有 open GitHub issues, 找出 untriaged 的 (没有 `triaged` label), Teamlead 先看, 判分发:

| issue 性质 | 分发给 | 看什么 |
|---|---|---|
| 代码改进 / tech-debt | Architect | 架构师审是不是 bug / 立场反转 / 加 backlog |
| 新功能 / feature | PM | 产品立场审 / 用户价值 / 蓝图覆盖性 |
| bug | QA | 复现 / 触发条件 / 影响面 |
| 拿不准 | 升用户拍 + label `type:question` | — |

三角色 triage 完成后:
- 打 `type:*` (bug/feature/question/tech-debt)
- 打**状态** label (`backlog`/`current-iteration`/`next-iteration`/`wont-fix`/`archived`)
- 加 `triaged` label 标记已处理

## Cron 配置

**默认频次**: 3h (跟 fast-cron 15m / slow-cron 2-4h 同体系, issue 流入比 PR 慢, 3h 够)

**AGENTS.md 可覆盖**:

```yaml
issue-triage:
  cron: 3h           # 默认 3 小时, 项目可改
  scope: open-only   # 仅扫 open issue
```

## 扫描范围

- 全 open issue
- **跳过已有 `triaged` label 的** (避免 re-triage 浪费)
- 跳过 `wont-fix` / `archived` 标 close 的 (已闭账)
- 跳过 `type:question` 等待用户回复中的 (避免反复扫直到用户回)

GitHub CLI 例:

```bash
gh issue list --state open --json number,title,labels,body --limit 1000 \
  | jq '[.[] | select((.labels | map(.name) | index("triaged")) | not)
                    | select((.labels | map(.name) | index("type:question")) | not)]'
```

## `triaged` label 引入

新加的 **ops label**, 跟 `type:*` / 状态 / 优先级 不是一个维度。

- 含义: 这个 issue 已经被 Teamlead + Architect/PM/QA 看过 + 分类过, 不需要再 triage
- 何时打: 三角色 triage 完成后, 打 type + 状态 label 同步打 `triaged`
- 何时去: 一般不去。如果 issue 重新需要分类 (e.g. 用户 follow-up 改了诉求), 移除 `triaged` 让下次 cron 重扫

**反约束**: triage 完成后必须打 `triaged`, 否则下次 cron 会重扫同一 issue 浪费。

## Triage 流程示例

```
[T+0] 用户开 issue: "登录页 logo 偏左 5px"
       label: (无)

[T+1h] cron 触发, Teamlead 扫 open issues
       → 看到此 issue 无 triaged label, 进 untriaged 列
       → Teamlead 判: 这是 UI bug → 分发给 QA

[T+1h05] QA 复现 + 评估影响面
       → 打 label: type:bug, current-iteration, p2-normal, triaged
       → 派 patch milestone (issue link in PR via Closes gh#NNN)

[T+1h] 另一 issue: "我想加协作多端实时同步"
       → Teamlead 判: 大功能 → 分发给 PM

[T+1h10] PM 审产品立场
       → 蓝图当前版无此模块, 价值高但需立场讨论
       → 打 label: type:feature, backlog, p1-high, triaged
       → body 补 "为什么入这: 新模块, 等下一版讨论挑入"
```

## 报告格式 (跟 fast/slow cron 一致)

短行风格:

- 有 untriaged: `[issue-triage cron] N open issues, M untriaged 派分发: X→Architect / Y→PM / Z→QA, 无 hard blocker`
- 全 triaged: `[issue-triage cron] N open issues, 全 triaged, 无 hard blocker`
- 卡点: `[issue-triage cron] N open issues, M untriaged, K 个 ≥24h 未分发 → 派 Teamlead 处理`

## 流转规则 (引 blueprint-iteration)

triage 后续走 `blueprintflow-blueprint-iteration` 的状态机:

- `type:bug` + 当前蓝图覆盖 → `current-iteration` + 派 patch / bugfix milestone (link issue 走 `Closes gh#NNN`)
- `type:feature` / `type:tech-debt` → `backlog` 等下一版讨论
- 拿不准 → label `type:question` 升 Teamlead + 用户拍

issue-triage 主管 **入闸 (Teamlead 分发 + 角色分类)**, blueprint-iteration 主管 **状态机后续 (流转 / 挑入下一版 / freeze)**。

## 跟其他 cron skill 边界

| skill | 维度 | 频率 | 做什么 |
|---|---|---|---|
| `teamlead-fast-cron-checkin` | PR | 15m | idle 角色派活 + PR 卡点扫 |
| `teamlead-slow-cron-checkin` | 蓝图偏差 / 文档一致性 | 2-4h | drift audit + 翻牌延迟纠正 |
| `issue-triage` (本 skill) | issue | 3h | 扫 untriaged + Teamlead 分发 + 角色分类 |

3 个独立, 不重叠。

## 反模式

- ❌ Teamlead 自己 triage 不分发 (用户拍 Teamlead 是分发, 不下场判类型 — 跟 team-roles "协调不动手" 立场一致)
- ❌ Architect/PM/QA 越界 triage 别人的领域 (代码改进给 PM 看 / 新功能给 QA 看 / bug 给 Architect 看)
- ❌ triage 完忘打 `triaged` label (cron 会重扫同 issue 浪费 context)
- ❌ triage 把 issue 直接 close 了不留 reason (要打 `wont-fix` 或 `archived` label, body 留一句 "为什么不做")
- ❌ triage 完没派 milestone / 没 link `Closes gh#NNN` (current-iteration issue 跟 PR 断链)
- ❌ 全 cron 一过就把所有 untriaged 挤给一个角色 (按性质分发, 不一刀切)

## 调用方式

cron prompt:

```
[issue triage · 3h]
follow skill blueprintflow-issue-triage
```

新 issue 进来场景 (cron 之外的即时触发):

```
新 issue gh#NNN 进来
follow skill blueprintflow-issue-triage
Teamlead 判 → 分发 → 角色分类 → 打 triaged
```
