# Blueprintflow

**多 Agent 协作做产品的工作流方法论。**

从模糊概念到可发布软件，6 角色 + Teamlead 协议推进。`current` 只放已实现且验收通过的蓝图，`next` 承载锁定/实现中的蓝图，`tasks` 先记录 Phase → Milestone 计划，再做 milestone breakdown 生成 task skeleton，一 task 一 PR 闭环交付。

一个大 iteration 通常拆成不超过 3 个有依赖顺序的 Phase；每个 Phase 通常拆成不超过 3 个 user-facing Milestone；Task 才是执行和 PR 原子。Teamlead 是流程驱动者，衡量标准是流程有没有推进、team 有没有在 runtime capacity 内被充分使用。

---

## 隐喻：城市工程

Blueprintflow 跟大型城市工程的协作模式同构——

| 城市工程 | Blueprintflow |
|---|---|
| **总工程师**出蓝图 | Architect 出 spec brief + 蓝图引用 |
| **甲方**拍立场 | PM 拍立场 + 反约束 |
| **施工队**按图施工 | Dev 按 spec 落地，不改图 |
| **质检**验收 | QA 跑 acceptance + 翻牌 |
| **总包**协调，不砌墙 | Teamlead 派活 + 守门，不写代码 |

核心思想：

- **蓝图状态分层** — `current` 是已实现验收，`next` 是待实现/实现中，`tasks` 是 next → current 的施工路径
- **按价值闭环分期** — Phase 是大 iteration 内有依赖顺序的阶段，通常不超过 3 个，不按工种分期
- **按用户可见结果拆里程碑** — 每个 Phase 通常不超过 3 个 user-facing Milestone，Task 才是 PR 原子
- **Teamlead 持续驱动** — 不等 cron；有人空闲就派活，恢复后按 notebook + source of truth 直接续推
- **阶段性验收签字** — Phase 退出 4 联签 = 阶段验收报告
- **质量门留痕** — 每个闸门有 commit SHA 锚点，可追溯
- **甲方代表全程在场** — PM 立场反查 = 不让施工偏离需求

## 设计思想

### 立场驱动，不是需求驱动

传统工作流从需求出发（PRD → 设计 → 开发）。Blueprintflow 从**立场**出发：

> 立场 = 一句话主张 + 反约束（X 是，Y 不是）+ 关键场景 + v0/v1 边界

写不出反约束的立场 = 立场不成立，不入蓝图。这保证了蓝图里每条规则都是可验证、可机器化检查的。

### 5 层漂移防御

产品开发最大的风险不是 bug，是**立场漂移**——做着做着偏离了初衷。Blueprintflow 用 5 层防线：

1. **Spec grep 反查** — 每个 task 引蓝图 §X.Y 锚点
2. **Acceptance 反查锚** — 验收模板跟 spec 拆段 1:1 对齐
3. **Stance 黑名单 grep** — 反约束关键词机器化检查
4. **Content-lock byte-identical** — UI 文案字面锁定
5. **PR 跨文件 cross-check** — review 时 spec/stance/acceptance/实施互查

### 一 Task 一 PR

不拆 spec PR、stance PR、implementation PR——task 的 4 件套 + 代码在同一 worktree 叠 commit，Teamlead 唯一开 PR，一次 squash merge。Milestone 是 task 组，不是 PR 原子。好处：

- 零 PR 串行等待
- Task 产出是原子的——要么全进，要么全不进
- 历史干净，一个 merge commit = 一个 task 闭环

### 角色 ≠ 人

6 角色（Architect / PM / Dev / QA / Designer / Security）定义的是**职责边界**，不是人头。一个 agent 可以承担多个角色，3 人团队也能跑完整流程。

## 4 层结构

```
┌─ 概念层 ──────── bf-brainstorm → bf-blueprint-write
│      ↓
├─ 计划层 ──────── bf-blueprint-iteration → bf-phase-plan → bf-milestone-breakdown
│      ↓
├─ 实施层 ──────── bf-task-execute + bf-git-workflow + bf-task-fourpiece + bf-verification + bf-pr-review-flow
│      ↓
└─ 协调层 ──────── bf-teamlead-fast-cron-checkin + bf-teamlead-slow-cron-checkin + bf-phase-exit-gate
```

## 适用场景

**适合：**
- 新产品 / 大功能 / 大 refactor，从概念开始
- 多 agent 协作（≥ 3 角色），单 agent 跑不完
- 需要立场 / 蓝图 / 实施 / 验收分轨且互锁
- 跨 milestone 漂移控制要求高

**不适合：**
- 单 agent / 小任务（overhead 太重）
- 纯 bug fix（走 PR review 即可）
- Hackathon / 一次性脚本
- 探索阶段没立场（先用 bf-brainstorm 锁立场再走这套）

## Skills 清单

| Skill | 触发 | 用途 |
|---|---|---|
| [bf-workflow](plugins/blueprintflow/skills/bf-workflow/SKILL.md) | 起步 | 入口 driver：建立 Teamlead/runtime/team 边界，然后按目标路由 |
| [bf-team-roles](plugins/blueprintflow/skills/bf-team-roles/SKILL.md) | 起团 | 6 个 role coordinator prompt 模板 + helper 边界 |
| [bf-brainstorm](plugins/blueprintflow/skills/bf-brainstorm/SKILL.md) | 讨论 | 多轮讨论锁立场 + 反约束 |
| [bf-blueprint-write](plugins/blueprintflow/skills/bf-blueprint-write/SKILL.md) | 立项 | 蓝图模板（立场 / 概念 / v0/v1 边界） |
| [bf-phase-plan](plugins/blueprintflow/skills/bf-phase-plan/SKILL.md) | 规划 | locked next anchors + fresh lock-gate evidence 拆 Phase / Milestone + 首个 task seed + 退出 gate |
| [bf-milestone-breakdown](plugins/blueprintflow/skills/bf-milestone-breakdown/SKILL.md) | 规划 | selected milestone 拆 reviewed task skeletons + `task.md` contract |
| [bf-blueprint-iteration](plugins/blueprintflow/skills/bf-blueprint-iteration/SKILL.md) | 演进 | current/next/tasks 状态推进 + backlog intake + Next lock integrity gate |
| [bf-task-state-standard](plugins/blueprintflow/skills/bf-task-state-standard/SKILL.md) | 实施 | `docs/tasks` 文件职责、resume ledger、task/milestone 状态标准 |
| [bf-task-execute](plugins/blueprintflow/skills/bf-task-execute/SKILL.md) | 实施 | 单个 task 从 ready 到 accepted 的总控 |
| [bf-task-fourpiece](plugins/blueprintflow/skills/bf-task-fourpiece/SKILL.md) | 实施 | task 4 件套（spec / stance / acceptance / content-lock） |
| [bf-implementation-design](plugins/blueprintflow/skills/bf-implementation-design/SKILL.md) | 实施 | 4 件套后写代码前 Dev 出实现方案设计 + 4 角色 review |
| [bf-git-workflow](plugins/blueprintflow/skills/bf-git-workflow/SKILL.md) | 实施 | 一 task 一 worktree 一 PR |
| [bf-current-doc-standard](plugins/blueprintflow/skills/bf-current-doc-standard/SKILL.md) | 实施/Review | `docs/current` 新建、更新、审查的当前实现文档标准 |
| [bf-pr-review-flow](plugins/blueprintflow/skills/bf-pr-review-flow/SKILL.md) | Review | 双 review + 标准 squash merge |
| [bf-verification](plugins/blueprintflow/skills/bf-verification/SKILL.md) | Review | QA 验收证据：UI/API/data/CLI/background 按对应 reference 验证；UI 保留三线 E2E 检查 |
| [bf-teamlead-fast-cron-checkin](plugins/blueprintflow/skills/bf-teamlead-fast-cron-checkin/SKILL.md) | 巡检 | 项目定义 cadence 的 active-work 派活 |
| [bf-teamlead-role-reminder](plugins/blueprintflow/skills/bf-teamlead-role-reminder/SKILL.md) | 巡检 | 项目定义 cadence 的 Teamlead 职责自检 |
| [bf-teamlead-slow-cron-checkin](plugins/blueprintflow/skills/bf-teamlead-slow-cron-checkin/SKILL.md) | 巡检 | 项目定义 cadence 的偏差 audit |
| [bf-issue-triage](plugins/blueprintflow/skills/bf-issue-triage/SKILL.md) | 巡检 | 项目定义 cadence 扫 GitHub issues, Teamlead 先判分发到 Architect/PM/QA |
| [bf-milestone-progress](plugins/blueprintflow/skills/bf-milestone-progress/SKILL.md) | 推进 | task accepted 后选下一个 task、关闭 milestone、检查 Phase exit readiness |
| [bf-phase-exit-gate](plugins/blueprintflow/skills/bf-phase-exit-gate/SKILL.md) | 收尾 | Phase 4 联签 + closure |
| [bf-runtime-adapter](plugins/blueprintflow/skills/bf-runtime-adapter/SKILL.md) | 起步 | 运行时适配（通讯/文件/调度的模式对照表） |

## 起步

```
1. bf-workflow          — 建立 Teamlead 边界，按目标路由
2. bf-runtime-adapter    — 确认运行模式
3. bf-team-roles        — 按 runtime capacity 起 role coordinators；helpers 只做 leaf work
4. bf-brainstorm        — 多轮讨论锁立场
5. bf-blueprint-write   — 落蓝图
6. bf-blueprint-iteration — 已有 accepted current 后，写 source trace、锁 next anchors、跑 Next lock integrity gate
7. bf-phase-plan        — 拆 Phase / Milestone + 首个 task seed
8. bf-milestone-breakdown — selected milestone 拆 task skeleton + review
9. (循环) bf-task-execute（内部串起 git workflow / fourpiece / design / current-doc / verification / PR review）
10. bf-milestone-progress — accepted task 后选下一个 task 或关闭 milestone
11. (巡检) bf-teamlead-fast-cron-checkin + bf-teamlead-slow-cron-checkin
12. (收尾) bf-phase-exit-gate
```

## 安装

**Claude Code（推荐）：**
```bash
# 方式 1：Plugin marketplace（推荐）
/plugin marketplace add codetreker/blueprintflow
/plugin install blueprintflow@blueprintflow

# 方式 2：手动安装
git clone https://github.com/codetreker/blueprintflow.git
ln -s $(pwd)/blueprintflow/plugins/blueprintflow/skills/* ~/.claude/skills/
```

**ClawHub：**
```bash
clawhub install bf-workflow
# 或安装全部
clawhub search blueprintflow
```

**OpenClaw / 其他框架：** 将 `plugins/blueprintflow/skills/` 下的目录复制或链接到对应的 skill 目录。

**Codex：**
```bash
codex plugin marketplace add codetreker/blueprintflow
# 然后在 Codex 的 plugin UI 中安装并启用 blueprintflow@blueprintflow。

# 本地 dogfood 时也可以在仓库根目录运行：
codex plugin marketplace add .
```

Codex marketplace 读取 `.agents/plugins/marketplace.json`，安装其中的 `./plugins/blueprintflow` 插件包；该包内含 `.codex-plugin/` 和 `skills/`，安装后加载 `blueprintflow:bf-*` skills。

安装后可验证：

```bash
codex debug prompt-input 'test' | rg 'blueprintflow:bf-'
```

安装后从 Codex 里启动：

```
Use Blueprintflow in Codex mode.
Use blueprintflow:bf-workflow, then use blueprintflow:bf-runtime-adapter with the Codex reference.
Act as Teamlead in the parent thread; run the Codex activation check before Phase or milestone work.
```

## 反馈

跑出新经验？开 PR 改 Blueprintflow 仓库，走仓库私有 skill [.claude/skills/repo-update](.claude/skills/repo-update/SKILL.md) 全员 vote；Agents 侧用 [.agents/skills/repo-update](.agents/skills/repo-update/SKILL.md) pointer 发现同一个入口。这套 skill 自己也是用 blueprintflow 方式迭代的。
