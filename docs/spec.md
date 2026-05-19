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
  +- bf-truth.md
  +- runs/
  |    +- reviews/
  |         +- round_{N}/  // review round N
  |              +- result_{role}.md // {role} review result
  +- <task-id>/
  |    +- runs/
  |    |    +- reviews/
  |    |    |    +- round_{N}/
  |    |    |         +- result_{N}.md
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
  - 开始根据模版讨论，边讨论边生成bf-truth.md，这样可以随时crash恢复，在后续的所有任务中有需要都可以翻阅这个文件

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
* /bf brainstorming ===> 生成到 /tmp/bf/<bf-taskname>

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
| `Completed` | 所有 task 都 → Completed 且 AC 全打 `[x]`，`verify` 自动转 |

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
| bf.md `Implementing` → `Completed` | 所有 task → Completed 且所有 AC 已 `[x]` | harness 自动（在 `verify` 里检测） |
| task `Draft` → `Ready` | bf.md → Accepted 时级联 | harness 自动 |
| task `Ready` → `Tasking` | `next` claim | harness |
| task `Tasking` → `Completed` | `verify` SUCCESS | harness |

cancel / abandon 不引入新状态：直接 `bf-harness discard <bf-wo>` 删整个 bf-wo 目录。

### Accept 后允许的 Mutation 全集

LLM 不能修改 bf.md / `<task>/spec.md` 的内容。harness 有以下窄授权（白名单）：

1. AC 行上把 `[ ]` 翻成 `[x]`（`verify` 写）
2. 文件头 `Updated:` 时间戳同步（任何 mutation 时一起更新）
3. 文件头 `State:` 按上表状态机推进

其它任何 mutation 一律非法 —— 加行、删行、改字段、改 task list、改 boundary 等都不允许。

## Spec Review流程
找到match的roles 开subagent revieww： 每个role可以开1-3个subagent。可以视任务的复杂程度增加或者减少subagent数，但是总数最多不超过10个subagent, `<round>`从0开始：
  - 运行 `./bin/bf-harness.mjs start-review <bf-wo>`, 返回review output dir，本轮review的result必须放到这个目录里
  - 创建 `runs` 目录，为每个role创建独立的目录 `review_<round>`
  - 并行review，如果subagent数撞墙了，关闭一些stale的，实在不行就排队。
  - 运行 `./bin/bf-harness.mjs verify <bf-wo>` 拿结果，通过会返回"SUCCESS", 其他情况会返回"FAIL"以及具体的错误信息和详细文件路径。

## Task Review流程

## 任务格式
每个task都是`<bf-wo>`目录里的一个子目录：
* spec.md - 本次任务的目标/验收标准/执行本次任务要求的能力

## 文件格式

### bf-truth.md - blueprint的source of truth
```markdown
---
Pack: <bf-pack-id>
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---
// context在compact或session重启后会丢失信息，这个文件里记录了这个任务的详细信息，包括但不限于：
// * 讨论后决定的设计方案
// * 重要的决定
// * Trade offs
// * 讨论过程
//
// 这里记录的是第一手的原始资料，如果后续任务有任何疑惑或者不清楚的，可以来这里寻找答案
```

### bf.md -- blueprint 核心文件
```markdown
---
Id: <可读的任务id>
Desc: <一句话任务描述>
Pack: <bf-pack-id>
State: Draft|Accepted|Implementing|Completed
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

# Goal
// 这里写本次的目标是什么，尽量简短

## Requirement
// 这个任务的要求有哪些，明确必须达成的目标

## Acceptance Criteria
// 任务的验收标准，必须是 bullet list，`[ ]` - 未完成； `[x]` - 已完成, 这个标记由 bf-harness.mjs verify来更新，LLM不能改。
// `{capability}` = 验收这条 AC 需要的能力。harness 反查所有 roles/*.md 里声明此 capability 的 role，
// 在 review 阶段全部派为 reviewer。LLM 不能在 contract 里硬编码 role 名字。
- [ ] {id1}|{capability}: criteria 1
- [ ] {id2}|{capability}: criteria 2

## Boundary
// Non Goals，本次任务的边界，明确不做的，防止breakdown的时候跑偏。

## Task List
// 任务列表，按执行先后顺序列, 以及依赖关系
- task-id-1
- task-id-2
- task-id-3: task-id-1,task-id-2  // depends on task 1&2
- ...
```

### `<task-id>/spec.md` - 这是唯一在bf core层面上定义的task文件，如何执行这个task由执行者来决定
```markdown
---
State: Draft|Ready|Tasking|Completed
Capability: <capatility>
Pack: <bf-pack-id>
Desc：<任务的一句话描述>
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---
// 这个task的spec文件，需要确保任务明确，有边界，有验收标准

# Task
// 详细task描述

## Requirements
- Requirement 1
- Requirement 2
- ...

## Acceptance Criteria
// 唯一id + 验收标准
- {id1}: criteria 1
- {id2}: criteria 1

## Boundary
// Non Goals，本次任务的边界，明确不做的，防止执行的时候跑偏。

```

### review_{round N}/result_{role}.md
Review 的结果文件, 格式必须满足如下要求：
```markdown
# Desc
// 本次review的范围

## Results

### Blocker
// Blocker issues

### High
// High risk issues

### Minor
// Minor issues

### Nit
// Suggestions

## Accepted Criteria
- {id1}: ...
- {id2}: ...

```

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

* `verify <bf-wo|task>`: 验证task的acceptance criteria是否已经满足
  - 找到runs目录里的的最新一轮revieww
  - 遍历所有的

## Packs
packs放在仓库的根目录，是bf核心的扩展方式.
目录格式：
```
packs
  +- <engineering>
  |     +- pack.md
  |     +- ...
  +- <research>
  +- <designer>
  +- ...
```

### Files

pack.md -- 这个pack的描述文件，LLM agent读取这个文件来理解这个pack的功能, 执行流程
```markdown
---
Id: <pack id> // 跟目录名一致
Desc: "..."  // Pack Desc, 跟Skill的描述类似，主要主要用来告诉LLM什么时候用这个pack
---

// Pack主体

```
