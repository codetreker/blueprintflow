---
name: blueprintflow-blueprint-iteration
description: "蓝图首版定下来后怎么演进 (3 状态机 + 版本号 + 变更怎么走 + 切版). 触发: 当前迭代验收过, 开下一版讨论 / 收到变更建议判是 bug 还是不是 / blueprint-next 收敛要切版. 反触发: 蓝图首版起草 (走 blueprint-write) / 实施期 milestone 拆段 / 当前蓝图字面 typo 直 commit."
version: 1.0.0
---

# Blueprint Iteration

蓝图不是一锤子定下来就永远不动, 但也不允许在当前版本里直接把规则反过来改. 这个 skill 讲蓝图落地后怎么演进: 3 个状态机 + 版本号 + 变更建议怎么走.

适用阶段: 蓝图首版已经定下来 + 至少一个 Phase 实施过. 早期 brainstorm + 首版 blueprint-write 阶段不走这个 skill.

## 3 个状态

| 状态 | 位置 | 含义 |
|------|-----|-----|
| 当前蓝图 | `docs/blueprint/` (repo 内) | 已定下来, 自带版本号, 实施 PR 引用都指向这里 |
| 下一版蓝图 | `docs/blueprint-next/` (repo 内) | 草拟阶段, 4 角色 + Teamlead/用户讨论中 |
| Backlog | **GitHub issues** (label `backlog`) | 还没规划, 持续积累, 不进当前迭代 |

3 个状态分开, 不混. 当前蓝图允许小修 (字面 / 锚点 / 边界), 但**不允许把规则反过来改** — 真要反的话必须走 `blueprint-next/`.

> **为什么 backlog 走 GitHub issues**:
> - **fork 友好**: GitHub issues 跟着 origin 仓库走, 不污染 fork. fork 拿到的是干净的蓝图 + 实施代码, 上游内部讨论 (噪音 / 敏感的) 留在 origin
> - **协作原生**: comment / label / assign / 链接 PR 全是 GitHub 自带的, 不重发明
> - **可搜可链**: PR `Closes gh#NNN` 直接链到来源, 不靠手写交叉引用

## Backlog: GitHub issues 是真账

Backlog 真账走 GitHub issues, 用 `backlog` label 标记.

### Tag 体系 (3 维度)

每个 issue 必须至少带一个 type + 一个状态 label. 优先级 label 项目可选.

**类型** (必须 1 个):
- `type:bug` — 当前蓝图设计是这样但实施漂了 / 蓝图 typo / 边界漏了锚点
- `type:feature` — 新规则 / 新模块 / 新需求
- `type:question` — 拿不准是 bug 还是 feature, 等 Architect/Teamlead 判
- `type:tech-debt` — 实施时欠的技术债 (refactor / 测试覆盖 / 文档跟不上)

**状态** (必须 1 个):
- `backlog` — 还没规划, 等下一版讨论再挑
- `current-iteration` — 已经放进当前迭代 (bug fix / patch milestone)
- `next-iteration` — 已经放进下一版蓝图 (blueprint-next 阶段)
- `archived` — 历史保留, 不再处理 (留作上下文)
- `wont-fix` — 评估过决定不做, close

**优先级** (项目可选):
- `p0-blocker` / `p1-high` / `p2-normal` / `p3-low`

### Issue 怎么流转

新 issue 进来先走 `blueprintflow-issue-triage` (cron 扫 + Teamlead 先判 + 分给 Architect/PM/QA 角色分类 + 打 `triaged` label). 这个 skill 管的是 triage 之后的状态流转:

```
issue triage 完 (label 已经打好) → 状态怎么走:
  ├── type:bug + 当前蓝图覆盖 → 加 `current-iteration` label + 派 patch / bugfix milestone
  ├── type:feature / type:tech-debt → 加 `backlog` label, 等下一版
  └── type:question → 升给 Teamlead + 用户拍

下一版讨论开始 → 扫所有 `backlog` label 的 issues (一条条人工评):
  ├── 挑入 → label 从 `backlog` 改成 `next-iteration`
  ├── 不要 → 加 `wont-fix` + close
  └── 留 → 还是 `backlog` (但 issue body 更新 "为什么继续留")
```

### Backlog issue body 必填字段

每个 backlog issue body 必须有 (反"光标题不够"):

- **来源**: 谁提的 / 哪个 PR # 触发的 / 哪次讨论
- **为什么放这**: 为什么不是 bug — 新规则 / 新模块 / 优先级低 / 暂不确定
- **不在范围**: 跟当前迭代的边界 (避免后续误塞当前)

### 例外

- 每个 issue 进 backlog 必须有"为什么放这", body 不能只写标题
- **不自动清理**, 每次下一版讨论开始时**人工扫一遍所有 `backlog` label issues** (错过这个时机就开始堆积)
- bug fix issue 必须链到当前迭代的 patch / bugfix milestone (issue 跟 PR 双向可追)

## 版本号 (写在蓝图里, 不写在 AGENTS.md)

蓝图版本号写在 `docs/blueprint/` 的 frontmatter:

```yaml
---
version: vN.M.0
frozen: <YYYY-MM-DD>
prev: vN.M-1
---
```

### Major bump (vN.M → v(N+1).0)

规则反过来 / 重命名 / 删模块 / 方向性大转.

例: 原蓝图 "本地优先无服务器" → 改成 "服务端优先 + 本地缓存".

### Minor bump (vN.M → vN.(M+1))

加一组新需求, 没改旧规则.

例: 原蓝图有 A/B/C 三个模块, 新加 D 模块, A/B/C 不动.

### Patch (不动版本号)

字面 / 锚点 / 边界补丁. 直接 commit, 不限次数, 不动版本号.

例: spec brief 加一条 grep 锚点 / 边界多写一句 / typo / §X.Y 引用修齐.

### 经验法则 (Architect 一句话判)

> 看到这版蓝图的人, 跟看 v(N-1) 的人沟通会**误解**吗?
>
> - 会 → **major** (规则冲突, 沟通会撞)
> - 不会, 只是不知道新东西 → **minor** (新增, 旧的还成立)
> - 不影响理解 → **patch** (补漏, 不动版本号)

## 变更建议怎么判 (Architect 一句话)

每条变更建议 (issue / PR comment / 用户提的需求) 进来, Architect 先判:

- **真 bug** (蓝图设计是这样但实施漂了 / 蓝图 typo / 边界漏锚点) → 加进**当前迭代**作为 patch 或 bugfix milestone, issue label `current-iteration` + `type:bug`
- **不是 bug** (新规则 / 新模块 / 规则反转) → 进 **backlog**, issue label `backlog` + `type:feature` 或 `type:tech-debt`
- 拿不准 → label `type:question` + 升给 Teamlead

**默认走 backlog**. 举证责任在"这是 bug"那边, 防止啥都塞当前迭代拖死实施.

## 当前蓝图小修规则

- ✅ 允许小修 — 字面 / 加锚点 / 边界 / typo, 不动版本号, 直接 commit, 不限次数
- ❌ 不允许规则反转 — 必须走 `blueprint-next/`, 切版时一次性切

注意: 小修写多了发现实际是规则反转 → 立刻拉 `blueprint-next/`, 把 patch 退回去.

### Patch / bugfix milestone PR 必须链来源

patch / bugfix milestone PR body 用 GitHub `Closes gh#NNN` 语法链来源 issue:

```
## Summary
修齐 §X.Y 规则漂移 (issue 报的真因)

Closes gh#NNN
```

效果:
- merge 后 issue 自动 close
- 蓝图迭代来源可追 (PR ↔ issue 双向链)
- backlog issue 转 `current-iteration` 后实施完闭环留痕

## Backlog 扫一遍 (下一版讨论开始时)

`gh issue list -l backlog --limit 1000` 拉所有 backlog issues, 一条条评:

- 挑入 → label 改 `next-iteration`, 移出 `backlog`
- 不要 → 加 `wont-fix`, close
- 留 → 留 `backlog`, 但 issue body 更新"为什么继续留"

这是 backlog 集中清理时机, 错过就堆积.

## 迭代生命周期

```
当前迭代验收过
   ↓
Teamlead 提醒用户 "可以开下一版讨论了"
   ↓
用户没回 → AGENTS.md 里设的提醒间隔重复提醒
   ↓
用户拍板开始
   ↓
扫 GitHub issues 里 `backlog` label 的 (清理 + 挑选, 移到 `next-iteration`) + brainstorm
   ↓
落 docs/blueprint-next/ + 写迁移分析
   ↓
4 角色 + Teamlead/用户讨论
   ↓
用户拍板 (或用户授权 Teamlead 拍板)
   ↓
切版:
  - blueprint-next/ → blueprint/ 替换
  - 旧版打 git tag (blueprint-vN.M) 留历史
  - 写 docs/blueprint/<version>/source-issues.md (链被挑入的 issue #, 没挑的不写, fork 可追)
  - 被挑入的 issues label 从 `next-iteration` 改成 `current-iteration`, 派 milestone 实施
  - 留 `backlog` 的 issues 不动 (持续)
  - 建空的 blueprint-next/ 开启下一版讨论入口
```

### source-issues.md 留痕

切版时把被挑入的 issue # 列进 `docs/blueprint/<version>/source-issues.md`:

```markdown
# Source issues for blueprint vN.M

本版蓝图来源 issues (按主题分组):

## 模块 X
- gh#123 — 标题, 一句话本版做了什么
- gh#125 — 标题, 一句话本版做了什么

## 模块 Y
- gh#127 — ...
```

效果:
- 让 fork 用户能追溯本版蓝图来源 (就算 fork 拿不到上游 issues 历史, 也能看到原 # 自己去上游查)
- 没挑入的 issue 不写 (噪音, 留在 GitHub backlog 就行)
- 跟蓝图同 version 一起定下来, 不可改

### 卡死保险

单 milestone 卡 ≥2 周 → Architect + PM 评估, 踢回 backlog 或拆段, 不拖整个迭代.

## AGENTS.md 配置 (项目自己定, 不在蓝图里)

```yaml
blueprint-iteration:
  reminder-period: 2w  # 用户没回时多久提醒一次
```

提醒间隔项目自己定 (e.g. 2w / 1m), 不写死. 版本号规则**不写这里** — 写在蓝图自带的 frontmatter 里.

## 反模式

- ❌ 在蓝图当前版直接把规则反过来改 (实施 PR 锚点漂, 历史被污染)
- ❌ 没扫 GitHub `backlog` issues 就直接开下一版讨论 (错过清理时机, backlog 越积越大)
- ❌ 版本号写在 AGENTS.md (蓝图自带 frontmatter, 跟蓝图同一份真值)
- ❌ Backlog 走 repo 内 docs 目录而不是 GitHub issues (不 fork 友好, 上游讨论噪音跟着 fork 走)
- ❌ 自动清 backlog issues (要人工讨论时清, 防误删用户真需求)
- ❌ Backlog issue body 只写标题不写"为什么放这" (后面扫的时候没法判)
- ❌ Patch / bugfix milestone PR 不链 `Closes gh#NNN` (来源断链)
- ❌ 单 milestone 卡死拖整个迭代 (踢回 backlog 或拆段, 别僵在那)
- ❌ 把"新规则"当成"bug"塞当前迭代 (举证责任反了, 拖死实施)
- ❌ 小修写多了发现是规则反转还硬塞当前 (立刻拉 next, 别硬塞)

## 调用方式

蓝图首版定下来 + 至少一个 Phase 实施过后:

```
follow skill blueprintflow-blueprint-iteration

# 场景 1: 收到变更建议 (issue / PR comment / 用户提)
Architect 判 bug / 非 bug → label issue + 当前迭代 patch / backlog

# 场景 2: 当前迭代验收过
Teamlead 提醒用户 → 用户拍 → 扫 GitHub `backlog` issues + 开 blueprint-next/

# 场景 3: blueprint-next/ 讨论收敛
4 角色 + 用户拍板 → 切版 + tag + 写 source-issues.md + label 改成 current-iteration
```
