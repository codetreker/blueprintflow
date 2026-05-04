---
name: blueprintflow-blueprint-iteration
description: 蓝图首版 freeze 后的演进规则 (3 状态机 + 版本号 + 变更流转 + freeze 切版)。触发: 当前迭代验收过开下一版讨论 / 收到变更建议判 bug vs 非 bug / blueprint-next 收敛要 freeze。反触发: 蓝图首版起草 (走 blueprint-write) / 实施期 milestone 拆段 / 当前蓝图字面 typo 直 commit。
version: 1.0.0
---

# Blueprint Iteration

蓝图不是一锤子 freeze 之后永久不动, 但也不允许当前版直接立场反转改。本 skill 定义蓝图落地后的演进规则: 3 状态机 + 版本号 + 变更流转判定。

适用阶段: 蓝图首版已 freeze + 至少一个 Phase 已实施。早期 brainstorm + 首版 blueprint-write 阶段不走本 skill。

## 3 状态机

| 状态 | 位置 | 含义 |
|------|-----|-----|
| 当前蓝图 | `docs/blueprint/` (repo 内) | frozen, 自带版本号, 实施 PR 锚点都指向这里 |
| 下一版蓝图 | `docs/blueprint-next/` (repo 内) | 草拟期, 4 角色 + Teamlead/用户讨论中 |
| Backlog | **GitHub issues** (label `backlog`) | 未规划, 持续积累, 不进当前迭代 |

3 状态独立, 不混。当前蓝图允许 patch (字面/锚/反约束), 但**不允许立场反转** — 立场反转必走 `blueprint-next/`。

> **为什么 backlog 走 GitHub issues**:
> - **Fork-friendly**: GitHub issues 跟着 origin 仓库走, 不污染 fork。fork 拿到的是干净蓝图 + 实施代码, 上游内部讨论 (噪音/敏感) 留在 origin。
> - **协作原生**: comment / label / assign / link PR 全是 GitHub 原生能力, 不重发明。
> - **可搜索 / 可 link**: PR `Closes gh#NNN` 直 link 真因, 不靠手写交叉引用。

## Backlog: GitHub issues SSOT

Backlog 真账走 GitHub issues, label `backlog` 标记。

### Tag 体系 (3 维度)

每个 issue 必带至少一个 type + 一个状态 label。优先级 label 项目可选。

**类型** (必须 1 个):
- `type:bug` — 当前蓝图设计如此但实施漂 / 蓝图 typo / 反约束漏锚
- `type:feature` — 新立场 / 新模块 / 新需求
- `type:question` — 拿不准 bug 还是 feature, 待 Architect/Teamlead 判
- `type:tech-debt` — 实施期欠的技术债 (refactor / 测试覆盖 / 文档跟不上)

**状态** (必须 1 个):
- `backlog` — 未规划, 等下一版讨论挑
- `current-iteration` — 已纳入当前迭代 (bug fix / patch milestone)
- `next-iteration` — 已纳入下一版蓝图 (blueprint-next 阶段)
- `archived` — 历史保留, 不再处理 (上下文价值)
- `wont-fix` — 评估过决定不做, close

**优先级 (项目可选)**:
- `p0-blocker` / `p1-high` / `p2-normal` / `p3-low`

### Issue 流转规则

新 issue 进来的 **入闸 triage** 走 `blueprintflow-issue-triage` (cron 扫 + Teamlead 先判分发 + Architect/PM/QA 角色分类 + 打 `triaged` label)。本 skill 主管 triage 之后的**状态机流转**:

```
issue triaged (label 已打) → 状态机流转:
  ├── type:bug + 当前蓝图覆盖 → label `current-iteration` + 派 patch / bugfix milestone
  ├── type:feature / type:tech-debt → label `backlog` 等下一版
  └── type:question → 升 Teamlead + 用户拍

下一版讨论开始 → 扫所有 label `backlog` issues (人工一条条评):
  ├── 挑入 → 移 label `backlog` → `next-iteration`
  ├── 不要 → label `wont-fix` + close
  └── 留 → 留 label `backlog` (但 issue body 更新 "为什么继续留")
```

### Backlog issue body 必写字段

每个 backlog issue body 必含 (反 "光标题不够"):

- **来源**: 谁提的 / 哪个 PR # 触发的 / 哪次讨论
- **为什么入这**: 不是 bug 的真因 — 新立场 / 新模块 / 优先级低 / 暂不确定
- **不在范围**: 跟当前迭代的边界 (避免后续误塞当前)

### 反约束

- 每个 issue 落 backlog 必有 "为什么入这" 说明, body 不能只标题
- **不自动清理**, 每次下一版讨论开始时**人工扫所有 `backlog` label issues** 一次 (清理良机错过就堆积)
- bug fix issue 必须 link 当前迭代的 patch / bugfix milestone (issue 跟 PR 双向可追)

## 版本号 (蓝图自带, 不在 AGENTS.md)

蓝图版本号写在 `docs/blueprint/` 的 frontmatter:

```yaml
---
version: vN.M.0
frozen: <YYYY-MM-DD>
prev: vN.M-1
---
```

### Major bump (vN.M → v(N+1).0)

立场反转 / 重命名 / 删模块 / 方向性大转。

例: 原蓝图 "本地优先无服务器" → 改成 "服务端优先 + 本地缓存"。

### Minor bump (vN.M → vN.(M+1))

一组新需求加入, 没反转旧立场。

例: 原蓝图有 A/B/C 三模块, 新加 D 模块, A/B/C 不动。

### Patch (不设版号)

字面 / 锚 / 反约束补丁。直接 commit, 无上限, 不 bump 版号。

例: spec brief grep 锚补一条 / 反约束多写一句 / typo / §X.Y 引用修齐。

### 经验法则 (Architect 一句话)

> 看到这版蓝图的人, 跟看 v(N-1) 的人沟通会**误解**吗?
>
> - 会 → **major** (立场冲突, 沟通会撞)
> - 不会, 只是不知道新东西 → **minor** (新增, 旧的还成立)
> - 不影响理解 → **patch** (补漏, 不 bump 版号)

## 变更流转判定 (Architect 一句话)

每条变更建议 (issue / PR comment / 用户提的需求) 进来, Architect 先判:

- **真 bug** (蓝图设计如此但实施漂 / 蓝图 typo / 反约束漏锚) → 加进**当前迭代**作为 patch 或 bugfix milestone, issue label `current-iteration` + `type:bug`
- **不是 bug** (新立场 / 新模块 / 立场反转) → 入 **backlog**, issue label `backlog` + `type:feature` 或 `type:tech-debt`
- 拿不准 → label `type:question` + 升 Teamlead

**默认走 backlog**。举证责任在 "这是 bug" 那边, 反 "啥都塞当前迭代" 拖死实施。

## 当前蓝图 patch 规则

- ✅ 允许 patch — 字面 / 锚补 / 反约束 / typo, 不 bump 版号, 直接 commit, 无上限
- ❌ 不允许立场反转 — 必走 `blueprint-next/`, freeze 时一次性切

患者: 当前 patch 写多了发现实际是立场反转 → 立刻拉 `blueprint-next/`, 把 patch 退回去。

### Patch / bugfix milestone PR 必 link 真因

patch / bugfix milestone PR body 用 GitHub `Closes gh#NNN` 语法 link 来源 issue:

```
## Summary
修齐 §X.Y 立场漂移 (issue 报的真因)

Closes gh#NNN
```

效果:
- merge 后 issue 自动 close
- 蓝图迭代真因可追 (PR ↔ issue 双向 link)
- backlog issue 转 `current-iteration` 后实施完闭环留痕

## Backlog 扫描 (下一版讨论开始时)

`gh issue list -l backlog --limit 1000` 拉所有 backlog issues, 一条条评:

- 挑入 → label 改 `next-iteration`, 移出 `backlog`
- 不要 → label 加 `wont-fix`, close
- 留 → 留 `backlog`, 但 issue body 更新 "为什么继续留"

这是 backlog 集中梳理时机, 错过就堆积。

## 迭代生命周期

```
当前迭代验收过
   ↓
Teamlead 提醒用户 "可开下一版讨论"
   ↓
用户没回应 → AGENTS.md reminder-period 重复提醒
   ↓
用户拍开始
   ↓
扫 GitHub issues label `backlog` (清理 + 挑选, 移 `next-iteration`) + brainstorm
   ↓
落 docs/blueprint-next/ + 迁移分析
   ↓
4 角色 + Teamlead/用户讨论
   ↓
用户拍板 (或用户授权 Teamlead 拍板)
   ↓
Freeze:
  - blueprint-next/ → blueprint/ 替换
  - 旧版 git tag (blueprint-vN.M) 留历史
  - 写 docs/blueprint/<version>/source-issues.md (link 被挑入的 issue #, 没挑的不写, fork 可追溯)
  - 被挑入的 issues label 从 `next-iteration` 改 `current-iteration`, 派 milestone 后实施
  - 留 `backlog` 的 issues 不动 (持续)
  - 创空 blueprint-next/ 开启下一版讨论入口
```

### source-issues.md 留痕

freeze 时把被挑入的 issue # 列进 `docs/blueprint/<version>/source-issues.md`:

```markdown
# Source issues for blueprint vN.M

本版蓝图来源 issues (按主题分组):

## 模块 X
- gh#123 — 标题, 1 句话本版兑现什么
- gh#125 — 标题, 1 句话本版兑现什么

## 模块 Y
- gh#127 — ...
```

效果:
- 让 fork 用户能追溯本版蓝图来源 (即便 fork 拿不到上游 issues 历史, 也能看到原 # 自己去上游查)
- 没挑入的 issue 不写 (噪音, 留 GitHub backlog 即可)
- 跟蓝图同 version 一起 freeze, 不可改

### 卡死保险

单 milestone 卡 ≥2 周 → Architect + PM 评估踢回 backlog 或拆段, 不拖整迭代。

## AGENTS.md 配置 (项目自定, 不在蓝图)

```yaml
blueprint-iteration:
  reminder-period: 2w  # 用户没回应时多久提醒一次
```

reminder-period 项目自定 (e.g. 2w / 1m), 不写死。版本号规则**不写在这** — 在蓝图自带 frontmatter。

## 反模式

- ❌ 蓝图当前版直接立场反转改 (实施 PR 锚漂, 历史污染)
- ❌ 没扫 GitHub `backlog` issues 直接开下一版讨论 (清理良机错过, backlog 越积越大)
- ❌ 版本号写在 AGENTS.md (蓝图自带 frontmatter, 跟蓝图同 source of truth)
- ❌ Backlog 走 repo 内 docs 目录而非 GitHub issues (反 fork-friendly, 上游讨论噪音跟 fork 走)
- ❌ 自动清 backlog issues (人工讨论时清, 反 "误删用户真需求")
- ❌ Backlog issue body 只写标题不写 "为什么入这" (后续扫描无法判)
- ❌ Patch / bugfix milestone PR 不 link `Closes gh#NNN` (真因断链)
- ❌ 单 milestone 卡死拖整迭代 (踢回 backlog issue 或拆段, 不僵)
- ❌ 把 "新立场" 当 "bug" 塞当前迭代 (举证责任倒置, 拖延实施)
- ❌ Patch 写多了发现是立场反转还硬塞当前 (立刻拉 next, 不硬塞)

## 调用方式

蓝图首版 freeze + 至少一个 Phase 实施过后:

```
follow skill blueprintflow-blueprint-iteration

# 场景 1: 收到变更建议 (issue / PR comment / 用户提)
Architect 判 bug / 非 bug → label issue + 当前迭代 patch / backlog

# 场景 2: 当前迭代验收过
Teamlead 提醒用户 → 用户拍 → 扫 GitHub `backlog` issues + 开 blueprint-next/

# 场景 3: blueprint-next/ 讨论收敛
4 角色 + 用户拍板 → freeze + tag + 写 source-issues.md + label 改 current-iteration
```
