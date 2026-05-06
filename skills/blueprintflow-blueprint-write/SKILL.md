---
name: blueprintflow-blueprint-write
description: "把 brainstorm 收敛后的产品规则落成 docs/blueprint/ 蓝图文档, 把产品长什么样的真账写下来 (含规则 + 边界 + grep 锚点). 触发: brainstorm 已经收敛, 规则定下来等落地 / 蓝图首版起草 / 蓝图新模块章节落地. 反触发: brainstorm 还没定 (先走 brainstorm) / 已经定下来的蓝图小修字面 (直接 commit, 走 blueprint-iteration 的 patch 规则) / 规则反过来改 (走 blueprint-iteration 开下一版) / 实施期 spec brief / 文案锁."
version: 1.0.0
---

# Blueprint Write

`docs/blueprint/*.md` 是产品长什么样的唯一真账, 后续 PR 都要引用 §X.Y 锚点. 蓝图定下来之后, 实施跟着蓝图走, 不能反过来.

## 蓝图结构

`docs/blueprint/` 目录下放这几样:

- **README.md** — 核心规则清单 (产品规则最权威的地方, 一般 10-15 条)
- **concept-model.md** — 一等概念 (比如 org / human / agent / channel) + 概念之间怎么搭
- **<module>.md** — 每个模块的产品形状 (比如 admin-model / channel-model / agent-lifecycle / canvas-vision / plugin-protocol / realtime / auth-permissions / data-layer / client-shape)
- **onboarding-journey.md** — 用户第一次用产品的旅程

> **实战案例 (Borgee):** 11 篇蓝图 + 14 条核心规则.

## 单篇蓝图模板

```markdown
# <Module Name> (产品形状)

## §1 核心概念

### §1.1 <一等概念>
一句话定义 + 跟其他概念的关系 + 边界 (什么算这个, 什么不算).

### §1.2 ...

## §2 不变量 / 红线

5-10 条产品级红线, 任何实施都不能违反:
- 红线 1: ... (写清楚边界)
- 红线 2: ...

## §3 v0/v1 边界

### v0 (还没外部用户)
- 允许删库重建 / 不写 backfill / 直接换协议
- 实施这边自由度高

### v1 (有了第一个外部用户之后)
- forward-only schema / backup / 灰度
- 不能再删库

## §4 不在范围 (留给 v2+)
明确写清楚 v1 不做什么 (比如 CRDT / 多端协作 / 锚点对话扩展)

## §5 验收挂钩
怎么跟 acceptance template / stance checklist 对接 (引锚点)
```

## 核心规则示例

每条一句话 + 边界 + 关键场景:

> **示例 (Borgee 产品):**
> 1. **一个组织 = 一个人 + 多个 agent** (UI 上隐藏 org 概念, 用户感受到的是"我和我的 agent")
> 2. **Agent 代表自己** (不是工具 / 不是 owner 的代理 / agent ↔ agent 协作允许, 但有边界)
> 3. **沉默胜于假 loading** (§11 — 不显示 spinner, 不显示"正在思考...")
> 4. **workspace + chat 双支柱** (artifact 不放在聊天里, channel 协作不挤进 workspace)
> 5. **产品不带 runtime** (§7 — agent runtime 是 plugin 自己的事, 这边只挂一个 process descriptor)
> 6. **管控元数据可以, 看你内容必须经过你授权** (§13 — admin god-mode 边界)
> 7-14: ...

每条规则必须能写出 5-7 项反查 (`blueprintflow:milestone-fourpiece` 的 stance checklist 用得上).

## 一条规则写不出"什么算什么不算" = 这条规则不成立

实战检查: 每条规则都要能写出 "X 是, Y 不是" 两面.

> **示例 (Borgee):**
> - ✅ "Agent 代表自己" → 边界写得出: "agent 不是 owner 的代理 / agent ↔ agent 跨 owner 协作允许 / mention agent ≠ mention owner"
> - ❌ "用户体验好" → 边界写不出 → 太虚, 不能进蓝图

## 流程

### 1. 概念多轮讨论
跟 `blueprintflow:brainstorm` 配套 — Teamlead 主持, PM + Architect 谈好几轮, 每轮敲定 1-2 个概念 + 规则.

### 2. 落到蓝图 (PR)
Architect + PM 配对写 `docs/blueprint/<module>.md`, 走 PR review (Dev + QA 也参与, 规则必须 Dev / QA 也认同, 否则实施会漂).

### 3. 核心规则清单出炉
所有模块的蓝图 review 完, 把核心规则 (通常 10-15 条) 提炼到 README.md, 标 ⭐ 的是重要规则 (后续 acceptance 必查).

### 4. 蓝图定下来
定下来之后, 想改要走 PR + 4 角色 review (跟实施 PR 同样的 review 标准). 修改原因写 changelog, 影响到的 milestone 全部回查一遍.

## 反模式

- ❌ 规则写得抽象空话 (写不出"什么算什么不算" = 规则不成立)
- ❌ 跳过反查表只写主张 (规则漂的时候 acceptance 抓不出)
- ❌ 蓝图频繁改不定下来 (实施跟着抖, 规则失焦)
- ❌ 蓝图 §X.Y 锚点不规范 (PR 引用的时候 grep 不出来)

## 调用方式

概念多轮讨论敲定后:
```
follow skill blueprintflow-blueprint-write
落 docs/blueprint/<module>.md
```
