---
name: blueprintflow-phase-exit-gate
description: "Phase 收尾闸: 严格检查点验收 + Architect/PM/QA/Teamlead 4 角色联签 + closure announcement, 是 Phase 切换之前的最后一道关. 触发: Phase 内所有 milestone PR merged + acceptance ⚪→✅ + REG 状态翻完 / 准备进入下一个 Phase 实施 / Teamlead 主动收口 Phase. 反触发: Phase 内还有 in-flight milestone PR / 单 milestone closure (在 milestone PR 内同一个 commit 落, 不开 follow-up) / 蓝图迭代切版 (走 blueprint-iteration 定下来)."
version: 1.0.0
---

# Phase Exit Gate

Phase 退出 = 严格检查点全 ✅ + 留账挂 Phase N+1 PR # + 4 角色联签 + closure announcement.

## 退出条件

### 0. PROGRESS 完整性检查 (前置条件)
退出 Phase 前要先确认 PROGRESS.md 所有任务状态准确:
- 每个 milestone 是不是已经做完打勾 ✅
- 没打勾的要逐条确认: 是漏了还是真没做完
- 发现对不上 → 先修正 PROGRESS, 再走退出流程

### 1. 严格检查点全 ✅
机器化条件 (比如 G<Phase>.<序号>) 全 SIGNED, 走 commit SHA 锚点.

### 2. 留账挂 Phase N+1 PR # 编号锁 (规则 6)
partial 检查点 (比如留账检查点) 挂占位 PR # — 不能用空头措辞, 必须是真的 PR 号.

### 3. 条件性 ✅ SIGNED 模式 (允许 partial)
不强制全部检查点严格 ✅, 允许这种组合:
- N 个检查点严格 ✅
- M 个检查点 PARTIAL (用 condition signoff 形式挂闭合路径)
- K 个检查点 DEFERRED (留 Phase N+1 PR # 锁)

公告 title 写"条件性全过", 不写"全过" (诚实工程).

> **实战案例 (Borgee):** Phase 2 退出 5 SIGNED + 3 PARTIAL + 2 DEFERRED → "条件性全过".

### 4. 4 角色联签
每个角色独立 PR signoff:
- Architect: readiness review 拍 ✅, 引 PR 锚点
- QA: acceptance + REG count 数学对账, 引 acceptance-templates 锚点
- PM: 规则 OK + 边界守住, 引规则反查表锚点
- Dev: 实施侧 acceptance 全挂上检查点, 引实施 PR 锚点

每个 signoff PR ≤ 5 行修改 (在 announcement §7 表格里加一行).

## 流程

### Step 1: Architect readiness review
- 落 `docs/qa/phase-N-readiness-review.md` (≤100 行)
- 5 个检查点 SIGNED 状态汇总 + PR 锚点
- 拍 ✅ ready / ⚠️ blockers
- Phase N+1 启动前置依赖 + 唯一冲突点

### Step 2: closure announcement skeleton
- 落 `docs/qa/phase-N-exit-announcement.md` (≤80 行)
- §1 SIGNED / PARTIAL / DEFERRED 三段
- §2-§5 各检查点引 PR # / commit SHA + acceptance-templates 锚点
- §7 4 角色联签位 placeholder
- §8 changelog v1.0

### Step 3: 4 角色联签 (每个独立 PR)
每个角色拉新 branch `docs/<role>-phase-N-cosign`, 编辑 announcement §7 里自己那行加 ✅ + 日期 + 锚点.

### Step 4: 占位 PR 全 merged 之后再合联签 4 PR
留账检查点 PR # 锁住的占位 PR 要先 merged, 然后联签 4 PR 一波标准 squash merge.

### Step 5: closure announcement v2 + Phase N+1 启动
- patch announcement 加 §9 关闭宣布段 (日期 + 留账明细 + Phase N+1 启动解封信号)
- PR title `docs(qa): Phase N closure announcement (建军 <date>)`

## 反模式

- ❌ 留账检查点不挂 PR # 用空头措辞 ("同 PR" 而不是具体 PR #)
- ❌ 强制全检查点严格 ✅ 拖延 Phase 退出 (条件性 ✅ SIGNED 是诚实, 不是妥协)
- ❌ 4 联签合到一个 PR (历史脏, 责任不清)
- ❌ 占位 PR 还没 merged 就合联签 (锚 PR 不存在, 逻辑断)

## 调用方式

Phase 进入收尾期 (严格检查点全 ✅, 留账挂占位 PR):
```
follow skill blueprintflow-phase-exit-gate
派 readiness review → announcement skeleton → 4 联签 → closure
```
