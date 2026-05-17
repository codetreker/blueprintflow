# BF 分层原则

Companion to [../2026-05-16-bf-fork-design.md](../2026-05-16-bf-fork-design.md).

本文记录"BF Core 与 Pack 之间如何分层"的设计原则。不是字段表,是判断依据。回顾 spec 时若忘了"当初为什么这么分",读这一份。

---

## 0. BF 公理(10 条)

这 10 条是 BF 设计的不变量。所有 Core / Pack / 运行时决定都不应违反它们。后续章节(§1-§10)是基于这些公理的具体设计判断。

1. **BF does not execute Raw Input directly.** Raw input is vague intent; not directly runnable.
2. **Raw Input must be shaped into a Work Object.** Shaping is the precondition for execution.
3. **Work Object is the basic unit of BF.** What is being advanced; the primary citizen.
4. **Every state transition needs artifacts or evidence.** No state advances without evidence backing it.
5. **Producer cannot be the sole verifier of their own output.** Independence axiom; review nodes need ≥2 distinct agents.
6. **Gate decides route.** Verdict is mechanical, not LLM-judgement; verdict drives transition.
7. **State and evidence must be recorded.** State lives in the WO's `wo.md` `runtime` block; evidence lives under `runs/` (handshakes + node artifacts). Earlier drafts called this combined storage "Ledger"; v0.2 replaced it with **WO Home** (see §6 of [core-contracts.md](./core-contracts.md)), but the axiom — state and evidence must exist somewhere persistent enough to gate transitions — is unchanged.
8. **A flow output can become another flow input.** Flows compose; recursion is allowed and expected.
9. **BF Core is domain-general.** Core does not encode any specific domain's vocabulary or workflow.
10. **Product-engineering Blueprintflow is a pack, not the boundary of BF.** The original BF is the first pack of a more general framework.

---

## 1. 三层结构

```
┌───────────────────────────┐
│ Runtime (borrowed)        │   有向图执行器(vendored from OPC)
│   bf-harness + lib        │   纯机械:跑节点、收证据、判 gate、防震荡
└────────────┬──────────────┘
             │ invokes
             ▼
┌───────────────────────────┐
│ BF Core (invented)        │   通用契约 + 通用角色 + 公理化保障
│   contracts + Core roles  │   只装"BF 公理化要求",不装领域细节
└────────────┬──────────────┘
             │ consumes
             ▼
┌───────────────────────────┐
│ Pack (plural)             │   一种领域怎么用 BF 的完整说明书
│   schemas + flows + ...   │   product-engineering / research / incident / ...
└───────────────────────────┘
```

- **Runtime** 不发明任何东西,只执行
- **BF Core** 发明抽象与公理,不绑定领域
- **Pack** 把领域形状声明出来,不写运行时代码

### 1.1 最小 Core 循环(4 步)

BF Core 只认四种 flow,对应 Work Object 从"raw input"到"done"的四步:

```
brainstorm  →  breakdown  →  loop  →  close
模糊想法       拆成子 WO     跑完所有子    收尾,
落成 WO        + 各自验收    + 各自验收    WO 走
```

- `brainstorm` 流入 raw input,流出 shaped WO(criteria 齐全)
- `breakdown` 把 WO 拆出 N 个子 WO,各自 shaped。叶子 WO 跳过此步
- `loop` 对所有子 WO 递归 execute,聚合结果。叶子 WO 跳过此步
- `close` 整体验收,标记 WO done

任何深度的 WO 都用这 4 个之一。Pack 实例化具体节点(用什么 role、什么 protocol),但**不能新增第五种 flow 类型**。这是 §5 通用结构模式在 flow 维度的应用。

### 1.2 WO 是递归目录结构

WO 的父子关系**不靠字段、不靠数据库,靠文件系统**:

```
~/.bf/wo/auth-v1/
├── wo.md                          ← 这个目录是 WO
├── runs/
└── login/
    ├── wo.md                      ← 这也是 WO,父是 auth-v1
    ├── runs/
    └── login-form/
        ├── wo.md                  ← 父是 login
        └── runs/
```

**规则**:目录里有 `wo.md` → 它是 WO;它的父 = 最近的有 `wo.md` 的祖先目录。

好处:
- `breakdown` 物理化 = 在父目录下 `mkdir` + 写子 `wo.md`
- `loop` 物理化 = 扫父目录,对每个有 `wo.md` 的子目录递归 execute
- 任意深度自然支持;Core 不在乎 phase / milestone / task 几层
- 用户用 `ls` / `cd` / 任何文件浏览器都能看任务结构
- WO export = `cp -r <wo-dir>`,移动 = `mv`,丢弃 = `rm -rf`

phase / milestone / task **退化为深度命名约定**(由 Pack 决定),不是 Core 概念。Core 看到的全都是 "WO",只在乎"是不是叶子"(没有子目录含 wo.md)。

---

## 2. Pack 装什么

Pack 是"一个领域怎么用 BF 的完整说明书"。包含 5 类东西,全部声明式,无可执行代码。

| 类别 | 文件 | 作用 |
|---|---|---|
| 清单 | `pack.json` | Pack 身份证(id / version / bf_compat / 引用清单 / 默认 routing) |
| Work Object 形状 | `schemas/*.json` | 本 Pack 有哪些 Work Object 类型、各自 state 枚举与字段 |
| 推进路径 | `flows/*.json` | Work Object 在哪种 state 下能用哪个 flow |
| 领域角色 | `roles/*.md` | review / build 节点要派谁去(领域特化角色) |
| 节点执行说明 + shaping 指引 | `protocols/*.md` | flow 走到某节点时实际要做什么;shaping 阶段问什么问题来生成好的 acceptance_criteria |

**Pack 不带运行时**。运行时是 `plugins/bf/` 的事;Pack 只是告诉 bf-run 和 bf-harness:"在本领域,按这套形状跑就对了"。

**Pack 不规定工作产物去哪**(见 §9)。产物住在它的自然栖息地;Pack 只通过 shaping protocol 帮用户写出好的 `acceptance_criteria`,让产物的存在可被验证。

### 各 Pack 举例

| Pack | schemas | 典型 flows | 领域 roles |
|---|---|---|---|
| product-engineering | blueprint / phase / milestone / task | brainstorm / blueprint-iteration / phase-plan / milestone-breakdown / task-execute / phase-exit-gate | pm / designer / frontend / backend / new-user |
| research(未来) | research-question / hypothesis / finding | question-shaping / hypothesis-testing / synthesis | research-lead / domain-expert / methodologist |
| incident(未来) | incident / hypothesis / mitigation | impact-triage / root-cause / mitigation-verify | incident-commander / on-call-engineer |

---

## 3. Pack 是独立 plugin 还是 bf 的子目录

### 决定:**v1 内嵌**,设计上为外置预留口子

```
plugins/
└── bf/
    ├── core/
    ├── runtime/
    ├── roles/                       ← Core roles
    ├── skills/bf-run/
    └── packs/                       ← 内嵌 Pack
        ├── product-engineering/
        │   ├── pack.json
        │   ├── schemas/
        │   ├── flows/
        │   ├── roles/               ← Pack roles
        │   └── protocols/
        └── (future) research/
```

`.claude-plugin/marketplace.json` 只注册一个 `bf` plugin。

未来若有第三方 Pack 或第一方 Pack 需要独立发版:bf-run 的 Pack 发现机制加一行"扫 `plugins/bf-pack-*`",架构无需重构。

### 候选方案与对比

| 方案 | 形态 | 适用阶段 |
|---|---|---|
| A. 每 Pack 独立 plugin | `plugins/bf/` + `plugins/blueprintflow/` 平级 | 多 Pack 阶段、社区贡献活跃后 |
| B. 全部内嵌 bf 子目录 | `plugins/bf/packs/*` | **v1 阶段(当前)** |
| C. 混合:第一方内嵌,第三方独立 | `plugins/bf/packs/*` + `plugins/bf-pack-*` | 长期形态;v1 实现 B 部分,留发现机制扩展位 |

### 选 B 的理由

1. **v1 只有 1 个 Pack**。拆独立 plugin 现阶段只是给 bf-run 加跨 plugin 扫描和版本依赖的复杂度。
2. **product-engineering Pack 与 BF Core 短期同节奏迭代**。Stage 3 的迁移探针就是用 Pack 反过来压测 Core,Pack 改一行 Core 也可能改一行;锁同一 plugin 更顺手。
3. **扩展成 C 是 1 小时的加法**,不是架构改造。

### 选 B 的代价

- Pack 与 bf 版本绑定发布,不能独立 hot fix(v1 不痛)
- 第三方 Pack 写不进 bf 仓库要等 C 阶段(v1 不需要)

---

## 4. roles 的同构分层

roles 与 Pack 一样,天然分两层。

| 层 | 例子 | 位置 |
|---|---|---|
| Core roles | planner / architect / tester / security / a11y / compliance / devil-advocate / skeptic-owner / user-simulator | `plugins/bf/roles/` |
| Pack roles | pm / designer / frontend / backend / devops / mobile / new-user / active-user / churned-user | `plugins/bf/packs/<pack-id>/roles/` |
| Flow 覆盖 | 某次 review 临时换"严苛版 architect" | 由该 flow 的 `rolesDir` 提供 |
| Dynamic | 运行时即兴造的"区块链安全审查" | `.bf/run-<id>/nodes/<node>/dynamic-role-*.md` |

前两层**安装时存在**,后两层**运行时产生**。

### 判断"Core 还是 Pack"的唯一标准

> **换一个 Pack,这个 role 还说得通吗?**

| Role | 换 Pack 还说得通? | 归属 |
|---|---|---|
| tester | research 验证假设、incident 验证 mitigation 都需要独立验证 → 是 | Core |
| security | research 数据合规、ops 安全审查都需要 → 是 | Core |
| devil-advocate | 任何决策都可能需要反向挑战 → 是 | Core |
| frontend | 只有写前端代码时存在 → 否 | Pack(product-eng) |
| pm | 只有产品工程有"产品经理"角色 → 否 | Pack(product-eng) |
| new-user | 产品工程有,research 的"受众"叫法不同 → 当前否,未来可能抽 | Pack(product-eng) |

**经验法则**:若一个 role 对应 BF 公理(§0 的 10 条),它就是 Core。如:
- tester ↔ 公理 5(producer 不能是 sole verifier)
- devil-advocate ↔ 对抗审查
- skeptic-owner ↔ 立场守门

这些 role 是 BF **能力面的化身**,不是某个 Pack 的私货。

### 三件机制

1. **优先级**:同名时,**Pack role 覆盖 Core role**;flow rolesDir 又覆盖 Pack。(沿用 OPC 现成机制。)
2. **借用 vs 特化**:
   - **借用** = Pack 不写 architect.md,直接用 Core 版
   - **特化** = Pack 写自己的 architect.md(如想要更"软件 architect"口味的版本)
3. **不支持显式 exclude**:Pack 不能屏蔽 Core role。不想要就在 flow 选 role 时不选,不需要配置项禁用。

---

## 5. 通用结构模式:不止 roles

Pack 设计的"通用层 / Pack 层"分法,不是只对 roles 有效,而是一种**反复出现的结构模式**。

| 维度 | 通用层(Core) | Pack 层 |
|---|---|---|
| roles | 通用角色 | 领域角色 |
| protocols | 节点级协议(gate-protocol、review-independence、handshake) | 领域协议(task-fourpiece、blueprint-write、verification) |
| flows | **不提供 flow**(flow 是 Pack 的事) | Pack 自己的 flow |
| schemas | **不提供具体 schema**(只提供 Work Object 元 schema) | Pack 的 Work Object schemas |
| WO Home 字段 | 强制 `wo.md`(YAML head + markdown body)以及 `runs/` 目录约定 | (无;WO Home 是 Core 的事) |
| 命令面(bf-run 动词) | **拥有动词集合**(create / execute / review / pass / stop / ...) | 不能新增动词;Pack 通过扩 schema + flow 让现有动词作用于新对象 |
| 工作产物存档 | **不管**(产物住在它的自然栖息地,见 §9) | **不管**(同上);Pack 只通过 shaping protocol 帮用户写好 acceptance_criteria |

### 决定 X 该 Core 还是 Pack 的原则

> **Core 装"BF 的公理化要求",Pack 装"领域的具体形状"。**

Core 不会因为"两个 Pack 都用了 X"就把 X 抽上来 — 必须 **X 在 BF 公理层面就该存在**,才是 Core 的事。

这样 Core 才不会膨胀,Pack 才有自治空间。

### 反例

- ❌ "product-eng 和 research 都用了 acceptance.md 这个文件名,把它放 Core" — 这是巧合,不是公理
- ❌ "三个 Pack 都需要 reviewer / verifier 区分,把这些 role 都放 Core" — 看具体 role 是否对应公理,不看出现频率
- ❌ "product-eng 想要一个 `/bf-run merge-pr` 动词,把它加进 Pack" — Pack 不能扩动词;要么 Core 加 `merge` 通用动词,要么 product-eng 的 `task-execute` flow 里包含 PR 合并节点(不暴露为顶层动词)
- ✅ "Gate 必须机械化、不靠 LLM 判断" — 这是公理 6,放 Core
- ✅ "review 节点必须 ≥2 独立 eval" — 这是公理 5,放 Core(Runtime 层强制)
- ✅ "tester 是独立验证的化身" — 公理 5 的角色具现,放 Core
- ✅ "create / execute / review / pass / stop 这些动词是 BF 工作循环的语义化身" — 放 Core(命令面公理化)

---

## 6. 这个分层对 Core 的约束

- **Core 没有 flow**。一个 BF Core 安装,不附带任何具体 flow。flow 是 Pack 的事。
- **Core 没有具体 schema**。Core 只有 Work Object 这个元 schema,不规定"task 长什么样"。
- **Core 角色不超过 10 个**(参考值,非硬性)。超过这个数,大概率有 Pack-private 的 role 混进来了。
- **Core 文档不举产品工程例子**。Core 文档里的例子要么用纯抽象,要么轮流用 product-engineering / research / incident 各一个,避免读者以为 Core 是产品工程框架。

---

## 7. 这个原则的复用条件

未来加新维度(比如 metrics、reports、dashboards)时,沿用本文判断:

1. 列出**所有可能的 Pack** 是否都需要这个东西
2. 找它对应的**BF 公理**(§0 的 10 条)
3. 公理对应到 → Core;不对应 → Pack;两者都有 → Core 提供基底接口,Pack 各自实现具体形态

这就是为什么 BF 能保持通用而不变成"产品工程框架改名版"。

---

## 8. 外部 skill 集成

BF 跑 flow 时可以借用项目里已装的其他 skill(例如 superpowers)。沿用 OPC 的两种机制,不发明新东西。

### 两种集成形态

| 形态 | 机制 | 何时用 |
|---|---|---|
| **节点委派** | flow.json 的 `unitHandlers` 把某个 unit type 映射到外部 skill。bf-harness 见到 unit 命中时,把 handler 信息返给 bf-run,后者调用该 skill。 | 整个节点的工作可以交给一个成熟 skill。例:`implement` 节点委派给 `superpowers:subagent-driven-development`。 |
| **协议软引用** | protocol.md 用条件句引用:"如果项目装了 X,可以用 X;否则按本协议手动跑"。 | 节点工作的某个子步骤有成熟工具。例:fourpiece 节点提到"shaping 子步骤可用 superpowers:brainstorming"。 |

### 核心约束

> **外部 skill 是加速器,不是必需品。Flow 必须能在"只有 BF 自己"的环境下完成。**

具体规则:

- `unitHandlers` 委派**必须有手动 fallback**。fallback 在 flow 对应的 protocol.md 里描述。handler 缺失时,bf-run 走 protocol 的手动路径,而不是报错终止。
- Protocol 软引用必须用**条件式语言**("如果...否则...")。不能写成"必须用 superpowers"。
- **不引入"Pack 级 skill 依赖"机制**(v1 范围)。如果一个 Pack 想表达"我推荐装这些 skill",写在 Pack 的 README 里;不进 Pack 契约。

### 为什么这条规则重要

1. **可移植性** — Pack 不能绑死外部 skill 生态。外部 skill 改名或废弃,Pack 仍要能跑。
2. **可审计性** — review 节点不能把判定外包给 BF 控制范围外的 skill,否则 review 独立性公理(§5)有漏洞。
3. **教学价值** — BF 的 protocol 自己描述"该怎么做"。全部委派出去,BF 退化成调度器,失去方法论本身。

### 对应反例

- ❌ "fourpiece 节点 unitHandler 设为 superpowers:brainstorming,没装就跑不了" — 缺 fallback,违反核心约束
- ❌ "Pack 的 pack.json 加 `requires_skills: [superpowers]`,强制安装" — v1 不做此机制
- ✅ "fourpiece 节点没有 unitHandler;protocol.md 说 '如果装了 superpowers,可以用 brainstorming 加速 shaping 子步骤'" — 软引用 + 手动 fallback
- ✅ "implement 节点 unitHandler 委派给 superpowers:subagent-driven-development;protocol.md 在 'Manual execution' 一节描述了没装时该怎么手工跑" — 委派 + fallback 都在

---

## 9. BF 不跟踪工作产物

这是 BF 概念边界的关键一刀。**BF 跟踪过程,不跟踪产物。**

### 含义

- BF 知道:Work Object 走到了哪个 state、要走到哪个 desired_state、过程中产出了哪些 artifact(eval、screenshot、test-result 等过程证据)
- BF **不知道**:工作产出长什么样、放在哪里、什么格式
- 工作产出(代码改动、PR、报告 markdown、设计文档、配置变更、行为改变)**住在它该住的地方**(git 工作树、远程 PR 系统、用户的笔记系统、配置目录等),从生成那一刻就在那里,**不经过 BF**
- BF 通过 `acceptance_criteria` **断言**产物存在 — 判定是分布式的:criteria-lint 保证 criteria 可验证,execute / verify 节点产 evidence(测试、截图、PR/CI),review 角色拿 criteria + evidence 写 eval(标 🔴🟡🔵),gate 机械计数 emoji 出 verdict。详见 [acceptance-judgement.md](./acceptance-judgement.md)。

### 为什么这样

1. **产物形态太多样,无法形式化** — 代码是跨文件改动,bug 修复是几行,文档是新文件,重构是多 PR 串,行为变更连文件都没有
2. **产物已有最好的存储系统** — git + GitHub 是史上最好的产物档案系统;让 BF 再发明一套等于浪费
3. **WO 半持久能成立的前提** — 如果 WO 持有产物指针,WO 扔了产物就成孤儿;让 acceptance_criteria 直接描述世界状态,WO 扔了产物依然存在
4. **acceptance_criteria 本来就够用** — 用户描述"做完是什么样",自然涵盖了"产物在哪里";硬塞一个 output_target 字段是冗余

### 反例

- ❌ "WO 字段 `output_target: 'docs/research/foo.md'`" — Core 不持产物路径;criterion 说"`docs/research/foo.md` 存在且涵盖 A/B/C"
- ❌ "Pack 字段 `product_form: git-changeset-with-pr`" — 产物形态不形式化;criterion 说"PR 已开 + CI 绿"
- ❌ "Artifact `ledger_target: 'docs/tasks/x/diff.patch'`" — 过程产物 promote 到产物位置;若 diff 是产物,implementer 直接写到目标位置,acceptance criterion 检查
- ✅ "acceptance_criteria 列 `'PR URL X 已开,CI 绿'` `'session 跨刷新保留'`" — 任务级表达,execute / verify 节点产 evidence,review 角色判定
- ✅ "Pack 的 shaping protocol 引导用户写出好的 acceptance_criteria(问环境、问目标位置、问验证方式)" — 帮用户表达,不替用户存

### 这一条与其它原则的关系

- 与 §5 通用结构模式一致:Core 装公理化能力(机械门、独立验证、过程追踪),Pack 装领域形状(state 枚举、role、protocol);**产物存档**两者都不装,因为产物天然存档在它的自然栖息地
- 与 §6 Core 约束一致:Core 不举产物落地的例子,因为这件事根本不在 Core 范围内

---

## 10. 相关文件

- [core-contracts.md](./core-contracts.md) — 6 个契约的字段
- [opc-role-mapping.md](./opc-role-mapping.md) — OPC 21 个 role 的去留
- [bf-skill-migration.md](./bf-skill-migration.md) — 现有 bf-* skill → Pack 的迁移
- [bf-run-commands.md](./bf-run-commands.md) — bf-run 的动词集合与解析规则
- [acceptance-judgement.md](./acceptance-judgement.md) — acceptance_criteria 的分布式判定机制
