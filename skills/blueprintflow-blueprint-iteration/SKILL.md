---
name: blueprintflow-blueprint-iteration
description: 蓝图首版 freeze 后的演进规则: 3 状态机 (current/next/backlog) + major/minor 版本号 (蓝图自带 frontmatter) + 变更流转判定 (真 bug 入当前 patch / 非 bug 入 backlog) + 迭代生命周期 (验收过 → 提醒 → 扫 backlog → 落 next → freeze + tag)。触发: 当前迭代验收过, 用户拍开下一版讨论 / 收到变更建议需判 bug vs 非 bug / blueprint-next 收敛要 freeze 切版。反触发: 蓝图首版起草期 (走 blueprint-write) / 实施期 milestone 拆段 / 当前蓝图字面 typo 直 commit (patch 不 bump 版号)。
version: 1.0.0
---

# Blueprint Iteration

蓝图不是一锤子 freeze 之后永久不动, 但也不允许当前版直接立场反转改。本 skill 定义蓝图落地后的演进规则: 3 状态机 + 版本号 + 变更流转判定。

适用阶段: 蓝图首版已 freeze + 至少一个 Phase 已实施。早期 brainstorm + 首版 blueprint-write 阶段不走本 skill。

## 3 状态机

| 状态 | 路径 | 含义 |
|------|-----|-----|
| 当前蓝图 | `docs/blueprint/` | frozen, 自带版本号, 实施 PR 锚点都指向这里 |
| 下一版蓝图 | `docs/blueprint-next/` | 草拟期, 4 角色 + Teamlead/用户讨论中 |
| Backlog | `docs/blueprint-backlog/` | 未规划, 持续积累, 不进当前迭代 |

3 状态独立, 不混。当前蓝图允许 patch (字面/锚/反约束), 但**不允许立场反转** — 立场反转必走 `blueprint-next/`。

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

每条变更建议进来, Architect 先判:

- **真 bug** (蓝图设计如此但实施漂 / 蓝图 typo / 反约束漏锚) → 加进**当前迭代**作为 patch 或 bugfix milestone
- **不是 bug** (新立场 / 新模块 / 立场反转) → 入 **backlog**
- 拿不准 → 升 Teamlead + 用户拍

**默认走 backlog**。举证责任在 "这是 bug" 那边, 反 "啥都塞当前迭代" 拖死实施。

## 当前蓝图 patch 规则

- ✅ 允许 patch — 字面 / 锚补 / 反约束 / typo, 不 bump 版号, 直接 commit, 无上限
- ❌ 不允许立场反转 — 必走 `blueprint-next/`, freeze 时一次性切

患者: 当前 patch 写多了发现实际是立场反转 → 立刻拉 `blueprint-next/`, 把 patch 退回去。

## Backlog 真账规则

每条 backlog item 必写:

- **来源**: 谁提的 / 哪个 PR / 哪次讨论
- **为什么入这**: 不是 bug 的真因 — 新立场 / 新模块 / 优先级低 / 暂不确定
- **不在范围**: 跟当前迭代的边界

**不自动清理**。视情况讨论清理。

**每次下一版讨论开始时必扫所有 backlog** (清理良机, 一条条评 "要 / 不要 / 删")。这是 backlog 集中梳理时机, 错过就堆积。

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
扫 backlog (清理 + 挑选) + brainstorm
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
  - backlog 不动 (持续)
  - 创空 blueprint-next/ 开启下一版讨论入口
```

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
- ❌ 没扫 backlog 直接开下一版讨论 (清理良机错过, backlog 越积越大)
- ❌ 版本号写在 AGENTS.md (蓝图自带 frontmatter, 跟蓝图同 source of truth)
- ❌ 自动清 backlog (人工讨论时清, 反 "误删用户真需求")
- ❌ 单 milestone 卡死拖整迭代 (踢 backlog 或拆段, 不僵)
- ❌ 把 "新立场" 当 "bug" 塞当前迭代 (举证责任倒置, 拖延实施)
- ❌ Patch 写多了发现是立场反转还硬塞当前 (立刻拉 next, 不硬塞)

## 调用方式

蓝图首版 freeze + 至少一个 Phase 实施过后:

```
follow skill blueprintflow-blueprint-iteration

# 场景 1: 收到变更建议
Architect 判 bug / 非bug → 当前迭代 patch / backlog

# 场景 2: 当前迭代验收过
Teamlead 提醒用户 → 用户拍 → 开 blueprint-next/

# 场景 3: blueprint-next/ 讨论收敛
4 角色 + 用户拍板 → freeze + tag + 切版
```
