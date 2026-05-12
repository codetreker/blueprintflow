# Blueprintflow

**多 Agent 协作做产品的工作流方法论。**

从模糊概念到可发布软件，6 角色 + Teamlead 协议推进。蓝图先 freeze 再开工，立场漂移 5 层防御，一 milestone 一 PR 闭环交付。

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

- **蓝图先 freeze 再开工** — 不能边建边改图，改图走 PR + 全员 review（= 工程变更单）
- **按价值闭环分期** — Phase 0 地基 / Phase 1 主体 / Phase 2 装修，不按工种分期
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

1. **Spec grep 反查** — 每个 milestone 引蓝图 §X.Y 锚点
2. **Acceptance 反查锚** — 验收模板跟 spec 拆段 1:1 对齐
3. **Stance 黑名单 grep** — 反约束关键词机器化检查
4. **Content-lock byte-identical** — UI 文案字面锁定
5. **PR 跨文件 cross-check** — review 时 spec/stance/acceptance/实施互查

### 一 Milestone 一 PR

不拆 spec PR、stance PR、implementation PR——4 件套 + 代码在同一 worktree 叠 commit，Teamlead 唯一开 PR，一次 squash merge。好处：

- 零 PR 串行等待
- Milestone 产出是原子的——要么全进，要么全不进
- 历史干净，一个 merge commit = 一个 milestone 闭环

### 角色 ≠ 人

6 角色（Architect / PM / Dev / QA / Designer / Security）定义的是**职责边界**，不是人头。一个 agent 可以承担多个角色，3 人团队也能跑完整流程。

## 4 层结构

```
┌─ 概念层 ──────── bf-brainstorm → bf-blueprint-write
│      ↓
├─ 计划层 ──────── bf-phase-plan
│      ↓
├─ 实施层 ──────── bf-git-workflow + bf-milestone-fourpiece + bf-pr-review-flow
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
| [bf-workflow](plugins/blueprintflow/skills/bf-workflow/SKILL.md) | 起步 | 总览 + 何时用 + 角色 + 阶段索引 |
| [bf-team-roles](plugins/blueprintflow/skills/bf-team-roles/SKILL.md) | 起团 | 6 角色 prompt 模板 |
| [bf-brainstorm](plugins/blueprintflow/skills/bf-brainstorm/SKILL.md) | 讨论 | 多轮讨论锁立场 + 反约束 |
| [bf-blueprint-write](plugins/blueprintflow/skills/bf-blueprint-write/SKILL.md) | 立项 | 蓝图模板（立场 / 概念 / v0/v1 边界） |
| [bf-phase-plan](plugins/blueprintflow/skills/bf-phase-plan/SKILL.md) | 规划 | Phase 拆分 + 退出 gate |
| [bf-blueprint-iteration](plugins/blueprintflow/skills/bf-blueprint-iteration/SKILL.md) | 演进 | 蓝图首版 freeze 后的迭代 (3 状态机 + 版本号 + GitHub issues backlog) |
| [bf-milestone-fourpiece](plugins/blueprintflow/skills/bf-milestone-fourpiece/SKILL.md) | 实施 | 4 件套（spec / stance / acceptance / content-lock） |
| [bf-implementation-design](plugins/blueprintflow/skills/bf-implementation-design/SKILL.md) | 实施 | 4 件套后写代码前 Dev 出实现方案设计 + 4 角色 review |
| [bf-git-workflow](plugins/blueprintflow/skills/bf-git-workflow/SKILL.md) | 实施 | 一 milestone 一 worktree 一 PR |
| [bf-pr-review-flow](plugins/blueprintflow/skills/bf-pr-review-flow/SKILL.md) | Review | 双 review + 标准 squash merge |
| [bf-e2e-verification](plugins/blueprintflow/skills/bf-e2e-verification/SKILL.md) | Review | UI 改动的 QA 验收必须走三个角度：代码改动是否按预期工作 / 产品是否好用 / 设计是否合理 |
| [bf-teamlead-fast-cron-checkin](plugins/blueprintflow/skills/bf-teamlead-fast-cron-checkin/SKILL.md) | 巡检 | 15min idle 派活 |
| [bf-teamlead-role-reminder](plugins/blueprintflow/skills/bf-teamlead-role-reminder/SKILL.md) | 巡检 | 30min Teamlead 职责自检 |
| [bf-teamlead-slow-cron-checkin](plugins/blueprintflow/skills/bf-teamlead-slow-cron-checkin/SKILL.md) | 巡检 | 2-4h 偏差 audit |
| [bf-issue-triage](plugins/blueprintflow/skills/bf-issue-triage/SKILL.md) | 巡检 | 3h cron 扫 GitHub issues, Teamlead 先判分发到 Architect/PM/QA |
| [bf-phase-exit-gate](plugins/blueprintflow/skills/bf-phase-exit-gate/SKILL.md) | 收尾 | Phase 4 联签 + closure |
| [bf-runtime-adapter](plugins/blueprintflow/skills/bf-runtime-adapter/SKILL.md) | 起步 | 运行时适配（通讯/文件/调度的模式对照表） |
| [bf-skill-workflow](plugins/blueprintflow/skills/bf-skill-workflow/SKILL.md) | 更新 | Skill 自身的 PR 流程 |

## 起步

```
1. bf-workflow          — 看总览，决定是否适用
2. bf-runtime-adapter    — 确认运行模式
3. bf-team-roles        — spawn 角色（按需）
4. bf-brainstorm        — 多轮讨论锁立场
5. bf-blueprint-write   — 落蓝图
6. bf-phase-plan        — 拆 Phase
7. (循环) bf-milestone-fourpiece + bf-git-workflow + bf-pr-review-flow
8. (巡检) bf-teamlead-fast-cron-checkin + bf-teamlead-slow-cron-checkin
9. (收尾) bf-phase-exit-gate
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

跑出新经验？开 PR 改 SKILL.md，走 bf-skill-workflow 全员 vote。这套 skill 自己也是用 blueprintflow 方式迭代的。
