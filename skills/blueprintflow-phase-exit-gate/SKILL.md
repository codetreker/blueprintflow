---
name: blueprintflow-phase-exit-gate
description: "Phase 收尾的最后一关. 这一 Phase 里所有 milestone 都做完了, Architect/PM/QA/Teamlead 4 个人签字确认, 然后才能进下一 Phase. 触发: Phase 内所有 milestone PR 都合了 + acceptance 都翻 ✅ + REG 状态都翻完 / 准备进入下一个 Phase / Teamlead 主动收口. 反触发: Phase 内还有 in-flight milestone / 单个 milestone 收尾 (在那个 milestone 自己 PR 里收, 不开 follow-up) / 蓝图换版 (走 blueprint-iteration)."
version: 1.0.0
---

# Phase 收尾

Phase 收尾就是这一 Phase 的最后一道闸门: 检查所有该做的事都做到了, 4 个角色都签字, 然后才能进下一 Phase. 跟一个 milestone 完工不是一回事 — 单 milestone 收尾在那个 milestone 自己的 PR 里就解决了, Phase 收尾是更上一级, 收一整段工作.

## 退出之前要确认的事

进入收尾流程前, 这些都得先到位:

### 1. PROGRESS.md 真实

每个 milestone 该打勾的都打勾了. 没打勾的得逐条确认: 是真没做完, 还是做完了忘记翻牌. 状态对不上就先修 PROGRESS, 别带病走收尾.

### 2. 机器化检查全 ✅

Phase 内的每道严格检查 (G<Phase>.<序号> 那种) 都 SIGNED, 引 commit SHA 锚.

### 3. 留账留对了

允许有些事这一 Phase 没做完, 但**留账必须挂下一 Phase 的占位 PR 编号** (规则 6) — 不能写"以后做"这种空话, 得是真 PR 号. 没占位 PR 就先开一个再来收 Phase.

### 4. 不强求"全过"

不是非要每道闸都严格 ✅. 允许这种组合:
- N 道严格 ✅
- M 道 PARTIAL (有 condition signoff, 闭环路径已经挂上)
- K 道 DEFERRED (留下一 Phase 的占位 PR 锁住)

公告标题写 "条件性全过", 不写 "全过" — 这是诚实, 不是放水.

> **实战案例 (Borgee)**: Phase 2 退出是 5 SIGNED + 3 PARTIAL + 2 DEFERRED, 写"条件性全过".

## 怎么走

整个 Phase 收尾走**一个** PR, 不拆 4 个角色独立 PR (那样跟"一 milestone 一 PR"铁律自相矛盾).

worktree: `.worktrees/phase-N-exit/`, branch: `docs/phase-N-exit`. 4 角色都在这个 worktree 内 commit, 也都在 PR comments 里 review, 跟 milestone PR 一样.

### Step 1: Architect 起草

Architect 在 worktree 里写两份文档, 一并 commit:

- `docs/qa/phase-N-readiness-review.md` (≤100 行) — 这一 Phase 准备好退出了吗
  - 每道闸的 SIGNED / PARTIAL / DEFERRED 状态汇总 + PR 锚
  - 拍 ✅ ready 或 ⚠️ 还有 blocker
  - 下一 Phase 启动的前置条件 + 跟当前 Phase 的衔接点

- `docs/qa/phase-N-exit-announcement.md` (≤80 行) — 收尾公告
  - §1 三段 (SIGNED / PARTIAL / DEFERRED) 各列了什么
  - §2-§5 每道闸引 PR # / commit SHA + acceptance-templates 锚点
  - §7 4 角色签字位 (placeholder, 等签)
  - §8 changelog v1.0

### Step 2: 4 角色 review + 签字

review 走 PR comments (跟 milestone PR 一样), 不开新 PR:

- **Architect**: readiness review 自己起草的, 在 PR comments 里 LGTM 自己的部分
- **QA**: 看 acceptance 都翻完, REG 数学对账对得上, 引 acceptance-templates 锚
- **PM**: 看产品规则没走样, 边界守住了, 引规则反查表锚
- **Teamlead**: 总签 (协调 + 看 4 件事都到位)

每个角色 review 通过后, **直接在 worktree 里 commit** 把自己那行签字写进 announcement §7 (一行: 角色名 / ✅ / 日期 / PR 锚). 不另开 branch, 不另开 PR.

### Step 3: 留账的占位 PR 先合

如果有 DEFERRED 闸挂着下一 Phase 占位 PR, 那些占位 PR 必须先 merged 再走 Phase 收尾合并 (否则 announcement 引的 PR 还不存在, 锚就断了).

### Step 4: 公告闭环 + Phase N+1 启动

4 角色都签了 + 占位 PR 都合了之后, 同一个 worktree 里 Architect 再 commit 一段 §9 关闭宣布:

- 日期
- 留账明细 (DEFERRED 闸都挂在哪)
- 下一 Phase 启动信号 (Phase N+1 entry 解封)

然后 Teamlead squash merge 整个 PR, 删 worktree, 删 branch.

PR title: `docs(qa): Phase N closure announcement`

## 反模式

- ❌ 留账闸用 "同 PR" 这种空话, 不挂具体 PR 号
- ❌ 非要每道闸严格 ✅ 才退, 拖死 Phase 切换 — "条件性全过"是诚实, 不是放水
- ❌ 4 角色每人一个独立 PR 联签 — 跟"一 milestone 一 PR"撞, Phase 收尾是一件事走一个 PR
- ❌ 占位 PR 还没合就合 Phase 收尾 PR (锚的 PR 不存在, 逻辑断)
- ❌ 公告分 v1 / v2 两次 PR (跟 ❌ "4 PR 联签"同源, 一件事拆多次合反铁律)

## 调用方式

Phase 进入收尾期 (机器化闸全 ✅, 留账挂占位 PR):

```
follow skill blueprintflow-phase-exit-gate
Architect 起草 readiness review + announcement → 4 角色在 PR comments review + commit 签字 → 占位 PR 全合 → §9 关闭宣布 → Teamlead squash merge
```
