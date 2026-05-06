---
name: blueprintflow-brainstorm
description: "通过 Architect+PM+Teamlead 多轮讨论, 把模糊想法收敛成可以写进蓝图的核心规则. 写蓝图前必走. 触发: 用户提\"我想做 X\"但产品方向还没定 / 现有蓝图没这个模块 / 团队对方向有分歧 / 新产品起步. 反触发: typo/dep bump/lint 等机械 PR / 已有蓝图段落清楚的小补丁 / hotfix / 实施中的拆段问题 (走 phase-plan 或 4 件套)."
version: 1.0.0
---

# Brainstorm

把模糊的产品想法变成能写进蓝图的东西: 几条核心规则、概念怎么互相搭、各自的边界. Teamlead 主持, PM 和 Architect 主谈 (需要的话拉 Designer / Security 进来), 通常聊 5-15 轮, 每轮敲定 1-2 个概念.

> **实战案例 (Borgee)**: 跑了 11 轮 brainstorm, 最终定下来 14 条核心规则.

## 何时用

- 新产品起步 (跟 `blueprintflow:blueprint-write` 配套)
- 加新模块 (e.g. CV-2 加 anchor 对话)
- 现有规则出现冲突, 实施时才发现当初没说清
- 蓝图要大改之前

## 不用的场景

- 实施时的技术选型 (e.g. SQLite vs Postgres) — 这是 spec brief 的事, 不是 brainstorm
- 已经定好规则的 milestone 实施 (跟 `blueprintflow:milestone-fourpiece` 走)

## 多轮讨论结构

### 轮 1: 划范围

Teamlead 抛 3 个问题, PM + Architect 各答 ≤200 字:

- Q1: 这模块最核心的几个概念是什么? (≤3 个)
- Q2: 跟现有概念 (org / agent / channel) 怎么搭?
- Q3: 反过来想 — 什么**不算**这模块的事?

### 轮 2-N: 一条一条谈

每轮挑 1-2 条具体的规则展开. PM 从用户视角说, Architect 从能不能做、好不好做的视角说, Teamlead 仲裁:

- 这条写得清吗? (能不能补一句"什么算, 什么不算")
- 跟其他规则会不会打架? 打架了选哪个?
- 现在做到哪 (v0)? 以后做到哪 (v1)?

每轮要有产出 — 5 行以内的规则草稿. 写不出来就是这条没想清, 留给下一轮接着谈.

### 最后一轮: 收口

Teamlead 把这一轮的 5-7 条规则 + 各自边界整理出来, PM 跟 Architect 都同意后, 进 `blueprintflow:blueprint-write` 写进蓝图.

## Teamlead 怎么主持

### 不替别人答
- 把活派给 PM 或 Architect, 自己只仲裁
- 仲裁的依据: 这条会不会跟现有规则打架? v0/v1 边界清不清楚? 能不能写出"什么算什么不算"?

### 推动出东西
- 每轮必须出 ≤5 行规则草稿. 写不出来这条就不算成立, 退回去重谈
- 不允许"再等等更多信息" — 信息永远不够, 该定就定

### 收敛到 5-7 条
- 别一直加. 太多了记不住, 实施时就走样
- 整个产品 10-15 条核心规则就够; 单个模块 5-7 条已经够

## 一条规则怎么写 (硬性要求)

每条都要有:
- **一句话** (≤30 字, 别人能照着复述)
- **边界** — 什么算这条, 什么不算 (防止做着做着跑偏)
- **场景** — 一个能跑出来的具体例子
- **v0 / v1 分界** — 现在做到哪, 以后做到哪

> **示例 (沉默胜于假 loading)**:
- 一句话: 不显示 spinner / 进度条 / "正在思考..."
- 边界: agent 处理时 UI 不动, 不假装显示进度; 真做完才显示结果
- 场景: agent 编辑 artifact, 用户看不到中间状态, 直到 commit
- v0: 全静默. v1 看用户反馈, 可能加 "thinking" 提示词 (但仍然不假装进度)

## 反模式

- ❌ 第一轮就想把所有规则都定下来 (收敛不了, 拖死)
- ❌ Teamlead 替 PM 答用户视角的事 (没真过用户视角讨论, 实施时就漂)
- ❌ 每轮不出草稿 (光说不写)
- ❌ 规则写得太抽象, 写不出"什么算什么不算" (退回去重写)
- ❌ 跑偏到实施细节 (e.g. 用 SQLite 还是 Postgres) — Teamlead 必须打断, 拉回到规则层面

## 收尾 checklist

brainstorm 结束时:
- [ ] 5-7 条规则都有 "一句话 + 边界 + 场景 + v0/v1 分界"
- [ ] 边界要写得能机器查 (e.g. 写出 grep 能查的反向条件)
- [ ] PM 和 Architect 都同意
- [ ] 接 `blueprintflow:blueprint-write` 写蓝图

## 调用方式

新模块 / 新规则:
```
follow skill blueprintflow-brainstorm
开始多轮讨论 (Teamlead + PM + Architect)
```

讨论收敛后接 `blueprintflow:blueprint-write`.
