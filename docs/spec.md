---
State: Draft
---

# bf(blueprint flow) draft ideas

## Skill目录结构
```text
<root>/
  +- SKILL.md
  +- bin/
  |    +- lib/
  |    +- bf.mjs
  |    +- bf-harness.mjs
  +- packs/
  |    +- engineering/
  |    +- ...
  +- roles/
  +- ...
```

## 运行目录结构
```text
<bf-wo>/
  +- bf.md
  +- discussion.md
  +- runs/
  |    +- reviews/
  |         +- round_{N}/                // review round N
  |              +- result_{role}_{idx}.md  // {role} 的第 {idx} 个 subagent 的 review 结果
  +- <task-id>/
  |    +- runs/
  |    |    +- reviews/
  |    |    |    +- round_{N}/
  |    |    |         +- result_{role}_{idx}.md
  |    |    +- ...
  |    +- spec.md
  |    +- more files
```

## 我想到的流程 <完整流程>
每个bf的主目录：`~/.bf/projects/<project-slug>/<bf-wo>/`
我现在想到的流程：
1. `/bf brainstorming` -- 也可以这样： "/bf 我们讨论一个方案", 从模糊idea变成一个实际可落地的方案。
  - 运行`./bin/bf.mjs list-packs` 获得当前安装的所有bf pack（这个就是将来对不通的场景扩展的地方）
  - 根据输入选择最合适的bf模版
  - 开始根据模版讨论，边讨论边生成 discussion.md（直接写到 `~/.bf/projects/<project-slug>/<bf-wo>/`，crash-safe），这样可以随时恢复，在后续的所有任务中有需要都可以翻阅这个文件

2. 写spec -- 可以是LLM Agent觉得已经足够清晰了就可以开始写spec；也可以用户说"/bf 开始写spec吧" 或者直接说 "写spec吧"，但是如果还有需要澄清的，LLM需要问用户并且给出建议，如果用户接受就开始写。
  - 运行 `./bin/bf.mjs roles` 拿到所有的roles以及他们具有的capabilities，
  - 写bf.md，State=Draft
  - 每个task一个目录，在目录里拆解出清晰的任务并为每个任务生成`spec.md`（State=Draft），并指定完成这个任务最合适的capability（注意：只能填一个）
  - 如果在拆解过程中遇到问题可以继续跟用户讨论直到没有疑问。
  - 写完所有的spec以后，走Spec Review流程，直到所有的问题都解决，过程中可以要求用户补充说明。
  - 运行 `./bin/bf-harness.mjs lint <bf-wo>` 校验, 解决所有问题，
  - 等用户review方案，用户同意后运行`./bin/bf-harness.mjs accept <bf-wo>`，然后开始执行任务。
  - Accept 后，bf.md / `<task>/spec.md` 的内容被 LLM 锁定，所有 task 级联转 `Ready`；具体的状态机和 mutation 白名单见 [核心约束 → State Machine](#state-machine) 一节。

3. 执行任务 -- 写完spec后就可以开始执行任务了,
  - LLM Agent调用 `./bin/bf-harness.mjs next <bf-wo>`, 得到一组任务，然后调用subagent执行；-- 任务包含完成这个任务所有必要的信息。
  - 根据任务信息，加载对应的pack.md，按指示执行这个任务。
  - 运行 `./bin/bf-harness.mjs verify <bf-wo>/<task>`，有问题解决，直到返回 SUCCESS

bf的workflow我倾向于每次都是动态生成
* /bf brainstorming ===> 直接生成到 `~/.bf/projects/<project-slug>/<bf-wo>/`（不走 /tmp 中转，保证 crash-safe + session 重启可恢复）

## 核心约束

### Independent Verification

对每个 task，**doer role ∉ reviewer roles**。具体含义：

* `next` 返回任务时声明 `capability_required`；LLM 从提供此 capability 的 candidate_roles 里挑一个做 doer
* `start-review` 阶段，harness 把 task 关联 AC 的 capability 反查出 reviewer roles，**排除掉刚才被选为 doer 的 role**
* 一条 AC 的 reviewer 至少 1 个；当排除 doer 之后无 reviewer 候选时，lint 报错（需要扩 role 集合或重设 AC capability）

这是 BF 的核心轴 —— 做的人不验证。

### State Machine

#### bf.md

```
Draft  ────►  Accepted  ────►  Implementing  ────►  Completed
  ▲             │
  └─ Spec Review iterates here (runs/reviews/round_N/)
```

| State | 含义 |
|---|---|
| `Draft` | brainstorm + breakdown 写完；可能在做 review 轮次（review 进度在 `runs/reviews/round_N/`，state 不变） |
| `Accepted` | 用户跑了 `bf-harness accept`，contract 锁定 |
| `Implementing` | 至少有一个 task 进入 Tasking；`next` 第一次返回任务时 harness 自动转 |
| `Completed` | 所有 task 都 → Completed，且对 bf.md AC 跑了一轮 bf-level review，`verify` Mode C 全部 sign-off |

#### task spec.md

```
Draft  ────►  Ready  ────►  Tasking  ────►  Completed
                              ▲    │
                              └────┘
                          verify FAIL: 留在 Tasking
```

| State | 含义 |
|---|---|
| `Draft` | breakdown 写完，bf.md 还没 Accepted |
| `Ready` | bf.md → Accepted 时所有 task 级联转 Ready，`next` 可选 |
| `Tasking` | `next` 返回了它；verify FAIL 时留在 Tasking 直到修通，不另设 Failed 状态 |
| `Completed` | verify SUCCESS |

#### State transitions（谁触发，谁写）

| 转换 | 触发 | 由谁写 |
|---|---|---|
| bf.md `Draft` → `Accepted` | 用户 `bf-harness accept <bf-wo>` | harness |
| bf.md `Accepted` → `Implementing` | 第一次 `next` 返回任务 | harness 自动 |
| bf.md `Implementing` → `Completed` | 所有 task → Completed 之后跑 bf-level review → `verify <bf-wo>` Mode C SUCCESS | harness（Mode C 触发） |
| task `Draft` → `Ready` | bf.md → Accepted 时级联 | harness 自动 |
| task `Ready` → `Tasking` | `next` claim | harness |
| task `Tasking` → `Completed` | `verify` SUCCESS | harness |

cancel / abandon 不引入新状态：直接 `bf-harness discard <bf-wo>` 删整个 bf-wo 目录。

### discussion.md vs bf.md

两个文件不同角色：

| 文件 | 角色 | 锁定 |
|---|---|---|
| `bf.md` | **Contract** —— 结构化承诺；被 lint / accept / 状态机驱动 | Accept 后由 LLM 锁定，harness 窄通道 mutation |
| `discussion.md` | **Rationale archive** —— brainstorm/spec 阶段第一手讨论；trade-off / 被否方案 / 决策依据 | 从不锁，LLM 全程 appendable |

**派生关系**：bf.md 派生自 discussion.md。LLM 在 spec 阶段从 discussion.md 提炼出结构化的 bf.md。原则上两者不应矛盾。

**执行阶段如何使用 discussion.md**：
- 执行时遇到 bf.md / spec.md 表述模糊或不足以拍板的细节 → **回 discussion.md 找答案**
- discussion.md 也没答案 → LLM 可以 append 新的澄清条目；如果澄清涉及超出已锁 contract 的范围，停下来跟用户讨论

**冲突如何处理**：
- 如果发现 bf.md 跟 discussion.md 实质冲突（不只是 bf.md 没说清，而是说反了）：
  - 这是个**信号 —— lock 时漂了**，bf.md 当时没准确反映 discussion
  - **不能机械裁决"哪边赢"**；harness 不允许偷偷改 bf.md，LLM 也不该自动假定 discussion.md 是错的
  - 正确动作：**停下来跟用户讨论**。用户决定要么 abandon 该 bf-wo 重做，要么明确接受 bf.md 的当前承诺继续

### Accept 后允许的 Mutation 全集

LLM 不能修改 bf.md / `<task>/spec.md` 的内容。harness 有以下窄授权（白名单）：

1. AC 行上把 `[ ]` 翻成 `[x]`（`verify` 写）
2. 文件头 `Updated:` 时间戳同步（任何 mutation 时一起更新）
3. 文件头 `State:` 按上表状态机推进

其它任何 mutation 一律非法 —— 加行、删行、改字段、改 task list、改 boundary 等都不允许。

## Spec Review流程
找到match的roles 开subagent review： 每个role可以开1-3个subagent。可以视任务的复杂程度增加或者减少subagent数，但是总数最多不超过10个subagent, `<round>`从0开始：
  - 运行 `./bin/bf-harness.mjs start-review <bf-wo>`, 返回 review 输出目录（`<bf-wo>/runs/reviews/round_N/`），本轮所有 review 结果文件必须放到这个目录里
  - 该目录所有 subagent 共享，每个 subagent 写一份 `result_<role>_<idx>.md`；`<idx>` 从 1 开始递增（同一 role 多 subagent 时用 idx 区分）
  - 并行 review，如果 subagent 数撞墙了，关闭一些 stale 的，实在不行就排队
  - 运行 `./bin/bf-harness.mjs verify <bf-wo>` 拿结果，通过会返回"SUCCESS"，其他情况会返回"FAIL"以及具体的错误信息和详细文件路径

## Task Review流程

## 任务格式
每个task都是`<bf-wo>`目录里的一个子目录：
* spec.md - 本次任务的目标/验收标准/执行本次任务要求的能力

## 文件格式

具体的 frontmatter 字段、section 结构、注释规范都放在 docs/template/ 目录下，可以直接复制使用。这一节只列每个文件的角色和约束。

### bf.md —— blueprint 契约

- 位置：`~/.bf/projects/<project-slug>/<bf-wo>/bf.md`
- 角色：本次工作的结构化契约。Accept 后由 LLM 锁定，之后只有 bf-harness 可以在窄通道里改 checkbox、State、Updated。
- 模板：[`docs/template/bf.md`](./template/bf.md)
- 关键约束：State 字段只能取 Draft、Accepted、Implementing、Completed；Acceptance Criteria 每条必须带 `{id}|{capability}` marker，capability 必须能在某个 role 文件里找到。

### discussion.md —— 讨论档

- 位置：`~/.bf/projects/<project-slug>/<bf-wo>/discussion.md`
- 角色：brainstorm 和 spec 阶段的第一手讨论记录，包括决策、被否方案、trade-off。Accept 之后仍然可以 append；从不锁。
- 模板：[`docs/template/discussion.md`](./template/discussion.md)
- 跟 bf.md 的关系：bf.md 派生自 discussion.md；详见前面"核心约束 → discussion.md vs bf.md"一节。

### `<task-id>/spec.md` —— 任务契约

- 位置：`~/.bf/projects/<project-slug>/<bf-wo>/<task-id>/spec.md`
- 角色：每个 task 的契约。Accept 后由 LLM 锁定，bf-harness 同样有窄通道做 checkbox、State、Updated。
- 模板：[`docs/template/task-spec.md`](./template/task-spec.md)
- 关键约束：State 字段只能取 Draft、Ready、Tasking、Completed；Capability 字段只能填一个（执行能力）；Acceptance Criteria 每条带 `{id}|{capability}` marker（验收能力，跟执行能力区分开）。

### review_{round_N}/result_{role}_{idx}.md —— review 结果

- 位置：`<bf-wo>/runs/reviews/round_N/result_<role>_<idx>.md`（bf-wo 级 review）或 `<bf-wo>/<task>/runs/reviews/round_N/result_<role>_<idx>.md`（task 级 review）
- 角色：单个 reviewer subagent 在某一轮 review 的结果。同 round 同 role 可以有多个 subagent 并行，用 `idx`（从 1 开始）区分。
- 模板：[`docs/template/review-result.md`](./template/review-result.md)
- 关键约束：Results 必须按 severity 分组（Blocker / High / Minor / Nit）；Accepted Criteria 引用的 id 必须是 bf.md 或 task spec.md 里实际存在的 AC id。

### roles/<role>.md —— 角色定义

- 位置：repo 根的 `roles/<role>.md`（Core role）或 `packs/<pack-id>/roles/<role>.md`（pack 私有 role）
- 角色：定义一个 role 的身份和它提供的 capability 清单。
- 模板：[`docs/template/role.md`](./template/role.md)

### pack.md —— pack 描述

- 位置：`packs/<pack-id>/pack.md`
- 角色：描述一个 pack 是什么、什么时候用、各阶段的指导。
- 模板：[`docs/template/pack.md`](./template/pack.md)

## Binary files

### .bin/bf.mjs
bf的运行环境支持，运行目录是bf安装目录，支持下面这些cmd：

* list-roles: 列出所有roles，在./roles目录下：
  - 文件路径 / role id / description

* list-packs: 列出来所有安装的模版，在./packs目录下的子目录:
  - Pack ID / Desc

### .bin/bf-harness.mjs
bf执行流程控制，运行目录是`~/.bf/<project-slug>/<bf-wo>`，支持一下这些cmd：
* list: 列出这个项目的所有bf-wo，就是去 `~/.bf/projects/<project-slug>/` 列出所有任务：
  - Id / Desc / State / Time

* `lint`: 验证spec:
  - bf.md, tasks/spec.md的格式是否符合要求，各个字段是否存在，格式是否符合要求
  - bf.md里task list中的taskid是否存在
  - task之间的依赖关系是否有问题
  - **capability registry 检查**：bf.md AC 里出现的每个 `{capability}`，必须能在某个 `roles/*.md` 的 `Capabilities` 列里找到声明（隐式注册），否则报错；防 typo
  - **independent verification 可行性检查**：对每个 task，若 doer 选择被 AC 的 reviewer roles 完全覆盖，导致没有可选 doer，报错
  - State=Draft

  结果：
  - 成功返回：SUCCESS
  - 失败：返回对应的错误，LLM Agent解决后再次调用，直到返回SUCCESS

* `start-review <bf-wo>|<bf-wo>/<task>`: 开始新一轮review
  - 找到`~/.bf/projects/<project-slug>/<bf-wo>/runs/reviews/round_{N}`中当前最大的N
  - 创建目录 runs/reviews/round_{N+1}
  - 返回新创建的目录完整路径

* `next`: 获取下一组没有完成的任务(Ready|Tasking)（确保相互没有depends，且任务的depends已经完成），把任务标记为Tasking，返回内容包括：
  - 任务目录
  - spec文件路径
  - 任务描述
  - `capability_required` — 完成这个任务需要的 capability（task spec.md 的 `Capability` 字段）
  - `candidate_roles` — 提供此 capability 的所有 role（harness 扫 roles/*.md 反查），LLM 从中挑选最合适的当 doer
  - `excluded_roles` — 该 task 关联 AC 里出现的 reviewer roles；LLM 选 doer 时必须排除这些（Independent Verification 轴）
  - 完成这个任务的pack id

* `verify <bf-wo>` 或 `verify <bf-wo>/<task>`: 验证 review 结果

  按 scope + bf.md.State 分派到三种 mode：

  **Mode A：`verify <bf-wo>` 且 bf.md.State = `Draft`（Spec Review phase）**
  - 找到 `<bf-wo>/runs/reviews/round_N/` 里 N 最大的那一轮
  - 遍历所有 `result_<role>_<idx>.md`，解析 `## Results`
  - 任一份有 Blocker 或 High → FAIL；全部 clean → SUCCESS
  - **不 flip 任何 AC，不动 State** —— spec review 的产物只是"准 ready"，是否 Accept 由用户决定

  **Mode B：`verify <bf-wo>/<task>` 且 bf.md.State ∈ `{Accepted, Implementing}`（Task Verification phase）**
  - 找到 `<bf-wo>/<task>/runs/reviews/round_N/` 里 N 最大的那一轮
  - 解析所有 `result_<role>_<idx>.md` 的 `## Results` + `## Accepted Criteria`
  - 任一份有 Blocker 或 High → FAIL，**不动 state/checkbox**
  - 没有 Blocker / High 时，对每条 task AC：
    - 解 AC 的 `{capability}` → 反查 reviewer roles（排除 doer，IV 约束）
    - 若所有 required reviewer 的 `## Accepted Criteria` 都列出该 AC.id → 该 AC signed（AND 语义）
    - flip `[ ]` → `[x]`，同步 task spec.md `Updated:`
  - 任一 AC 未被全部签到 → FAIL，列出哪些 AC 缺哪些 reviewer
  - task 所有 AC 都 `[x]` → task spec.md `State: Tasking → Completed`

  **Mode C：`verify <bf-wo>` 且 bf.md.State = `Implementing` 且所有 task `Completed`（bf-wo Final Acceptance phase）**
  - 跟 Mode B 同样流程，但 scope 是 bf.md 的 AC（不是任意 task 的 AC）
  - 找到 `<bf-wo>/runs/reviews/round_N/` 里 N 最大的那一轮 —— 这一轮应该是 task 全部完成**之后**重新跑的 bf-level review（不是当年的 spec review；通过 round_N 递增区分）
  - block + sign-off 逻辑同 Mode B
  - 通过后 flip bf.md 里所有 AC 为 `[x]`，bf.md `State: Implementing → Completed`，同步 `Updated:`
  - **bf-wo 级别 review 的 IV 约束**：暂不强制（final acceptance 是 integrative 检查，做整体集成的 reviewer 跟做某条单 task 的 doer 在职责上天然不重叠；如未来发现需要严格化再加）

  **其它 scope/state 组合** → 返回 `phase mismatch: cannot verify <scope> when bf.md.State = <X>`

  **输出**：
  - 写一份 `verify-result.md` 到对应 round 目录（`<bf-wo>/runs/reviews/round_N/verify-result.md` 或 `<bf-wo>/<task>/runs/reviews/round_N/verify-result.md`）
  - stdout 只回一行：`SUCCESS <绝对文件路径>` 或 `FAIL <绝对文件路径>`
  - subagent 可以直接被指派去读这个文件，不需要把内容塞进 context

  **verify-result.md 格式（结构化 markdown）**：
  ```markdown
  ---
  Result: SUCCESS|FAIL
  Mode: A|B|C
  Scope: <bf-wo> 或 <bf-wo>/<task>
  Round: <N>
  Timestamp: <yyyy-mm-dd hh:MM>
  ---

  ## Issues
  // FAIL 时填，按 severity 分组；每条带 file:line + 描述

  ### Blocker
  ### High

  ## AC Sign-off
  // Mode B / C 才有；列出每条 AC 的状态
  - AC-1: signed (by tester, security)
  - AC-2: missing (need: security; got: tester only)
  - AC-3: blocked (Blocker raised; not yet evaluated)

  ## Flipped
  // Mode B / C；本次新翻 [x] 的 AC id 列表

  ## State Changes
  // 本次触发的 state 转换
  - task-3: Tasking → Completed
  - bf.md: Implementing → Completed
  ```

## Packs

Packs 放在仓库根目录的 `packs/` 下，是 bf core 的扩展方式。每个 pack 描述一个领域或场景的工作流模式，比如 engineering、research、incident response、content production 等。

### 目录结构

```
packs/
  +- engineering/
  |    +- pack.md           # 必需。pack 描述 + 三阶段指导。
  |    +- roles/            # 可选。pack 私有的 role。
  |        +- designer.md
  +- research/
  +- ...
```

### pack.md 的结构

每个 pack 必须有一份 `pack.md`，模板和写作规范见 [`docs/template/pack.md`](./template/pack.md)。

pack.md 包含 5 个 section，其中 `When to Use` 是必填，其它 4 个推荐填写但不强制：

1. **When to Use**（必填）—— 一到三句话，说清楚什么样的工作适合用这个 pack。LLM 在 brainstorm 阶段拿到用户输入后，靠这一节判断选哪个 pack。
2. **Domain Vocabulary** —— 此领域的关键术语和概念。帮 LLM 用对话语风格。
3. **Brainstorm Guidance** —— brainstorm 阶段问什么样的问题，blueprint 该是什么形状。
4. **Breakdown Guidance** —— 此领域里"一个 task"是什么形状，典型粒度、依赖模式。
5. **Execute Guidance** —— 做一个 task 时的通用指导，常见 pattern 和反 pattern。

### Pack 私有 role

每个 pack 可以在自己目录下放 `roles/`，role 文件跟 Core role 用同一份模板（[`docs/template/role.md`](./template/role.md)）。

合并规则：
- `bf list-roles` 输出会合并 Core roles 和当前 bf-wo 选定 pack 的 roles。
- 同名 role 时 pack 优先级高于 Core，pack 覆盖 Core 的同名 role。
- 此 pack 的 brainstorm、spec、execute 阶段都可以引用这些 role。

### 跟 bf-wo 的耦合

v1 强制约束：一个 bf-wo 只对应一个 pack（写在 bf.md frontmatter 的 Pack 字段）。跨 pack 的工作必须拆成多个 bf-wo。这个约束未来可能放宽，但 v1 不支持。

### list-packs 的容错策略

`bf list-packs` 读取 `packs/` 目录时，对每个 pack 做基本结构检查（pack.md 是否存在、frontmatter 是否完整、Id 是否跟目录名一致）。发现结构问题的 pack 会被跳过并在 stderr 输出 warning，但不会让 list-packs 失败。

理由：pack 作者的开发流程在 BF 之外，BF 只关心 pack 在运行时能不能被使用。pack 写不规范，用户从 warning 看到信息自己处理；BF 不接管 pack 开发工具链。

