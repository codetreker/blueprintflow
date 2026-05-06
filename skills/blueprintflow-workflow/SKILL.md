---
name: blueprintflow-workflow
description: "Blueprintflow 多 agent 协作做产品的工作流方法论入口, 覆盖概念→蓝图→Phase→milestone→PR→检查点全生命周期, 是其他 blueprintflow skill 的导航. 触发: 新产品启动 / 大功能起步 / 团队第一次接入 blueprintflow / 不确定该走哪个具体 skill. 反触发: 已经在 milestone 实施中按 4 件套或 implementation design 推进 / 单文件 typo / dep bump / hotfix 紧急路径 / 已经明确知道走哪个具体 skill."
version: 1.0.0
---

# Blueprintflow Workflow

多 agent 协作工作流, 适合**做产品**: 从模糊概念到能发布的软件, 6 角色 + Teamlead 协议推进.

## 心智模型: 城市工程

这套 skill 是给**大需求 / 长周期项目**用的 — 跟大型城市工程的协作模式同构:

| 城市工程 | blueprintflow 角色 |
|---|---|
| 总工程师 | Architect (架构) — 出蓝图 + spec brief |
| 甲方 | PM (产品) — 定规则 + 边界 |
| 施工队 | Dev (开发) — 按 spec 落地, 不改图 |
| 质检 | QA — acceptance 验收 |
| 设计 / 安全 | Designer / Security (装修 / 消防) |
| 总包 | Teamlead — 协调, 不下场砌墙 |

工程方法对应:
- **蓝图先定下来再开工** — 不能边建边改图, 改图走 PR + 4 角色 review (相当于工程变更单)
- **按用户能用的事分期** (Phase 0 地基 / Phase 1 主体 / Phase 2 装修) — 不按工种分期
- **阶段性验收签字** (Phase 退出 4 联签 = 阶段验收报告 + 留账检查点)
- **质量门留痕** (规则 6 / migration v 号串行 = 工程档案)
- **甲方代表全程在场** (PM 反查规则 = 不让施工偏离需求)

### 不适用场景

- Hackathon / 一次性脚本 / 单 PR fix — 蓝图 + brainstorm + Phase 退出 gate 是重型基建, 短任务用不上
- 单人快速迭代 — 4 件套 + 双 review 路径假设有多人协作
- 探索阶段还没规则 — 先用 `blueprintflow:brainstorm` 把规则定下来再走这套

## 何时用

适合:
- 新产品 / 大功能 / 大 refactor 从概念开始
- 多 agent 协作 (≥3 角色), 单 agent 跑不完
- 需要规则 / 蓝图 / 实施 / 验收 分轨且互锁的场景
- 跨 milestone 漂移控制要求高 (规则不能跟着实施漂)

不适合:
- 单 agent / 小任务 (overhead 太重)
- 纯 bug fix (走 PR review + 标准 squash merge 就行, 永远不 admin/ruleset bypass)
- 已有产品的运维 / oncall

## 4 层结构

```
┌─ 概念层 (蓝图) ───────── blueprintflow:brainstorm + blueprintflow:blueprint-write
│      ↓
├─ 计划层 (Phase 拆) ──── blueprintflow:phase-plan
│      ↓
├─ milestone 层 (实施) ── blueprintflow:milestone-fourpiece + blueprintflow:pr-review-flow
│      ↓
└─ 协调层 (持续推进) ──── blueprintflow:teamlead-fast-cron-checkin (15min idle)
                          blueprintflow:teamlead-slow-cron-checkin (2-4h audit)
                          blueprintflow:phase-exit-gate (Phase 收尾)
```

## 6 角色 + Teamlead

| 代号 | 中文 | 职责 |
|---|---|---|
| **Teamlead** | 协调 | facilitator, 派活 / 监督 / 守协议, 不写代码 |
| **Architect** | 架构师 (Architect) | spec brief / 蓝图引用 / 检查点 1+2 (模板自检 + grep 锚点) / PR 架构 review |
| **PM** | 产品 (PM) | 规则反查表 / 文案锁 / 检查点 3 反查表 / 检查点 4 标志性 milestone 签字 |
| **Dev** | 开发 (Developer) | 实施代码 / migration / 单测 / 主 worktree (一次只做一个 in-flight) |
| **QA** | 测试 (QA) | acceptance template / E2E + 行为不变量单测 / current 同步审 / 检查点 4 跑 acceptance |
| **Designer** | 设计 (Designer) | UI/UX/视觉, milestone 涉及 client UI 时拉进来 (跟 PM 文案锁互锁) |
| **Security** | 安全 (Security) | auth / privacy / admin god-mode / cross-org 路径 review, 涉及敏感写动作时拉进来 |

完整角色 prompt 模板见 `blueprintflow:team-roles`.

## 阶段 + Skill 索引

### 阶段 1: 概念定下来
**目标**: 模糊 idea → 能写进蓝图的核心规则 + 概念模型 + 边界

1. **blueprintflow:brainstorm** — Teamlead 主持多轮讨论 (PM + Architect 主谈), 定规则 / 概念 / 边界
2. **blueprintflow:blueprint-write** — Architect + PM 落 `docs/blueprint/*.md`

产出: `docs/blueprint/` 就绪, 概念定下来, 后续 PR 都要引 §X.Y

### 阶段 2: 实施计划
**目标**: 蓝图 → Phase 拆 + 退出 gate + 4 道防跑偏检查点

3. **blueprintflow:phase-plan** — Architect 主, 落 `docs/implementation/PROGRESS.md` + execution-plan + Phase 退出 gate

产出: PROGRESS.md 就绪, Phase 1/2/3+ 拆段清晰

### 阶段 3: milestone 实施 (主要场景)
**目标**: 一个 milestone 一个 worktree + 一个 branch + 一个 PR — Teamlead 创 worktree, 全员叠 commit, Teamlead 唯一开 PR, merged 后 Teamlead 删 worktree

4. **blueprintflow:git-workflow** — git 协议: 一个 milestone 一个 worktree, 角色不开 PR, Teamlead 唯一开 PR
5. **blueprintflow:milestone-fourpiece** — 4 件套全员同一个 worktree 叠 commit (spec / stance / acceptance / content-lock 都进同一个 PR)
6. **blueprintflow:implementation-design** — 4 件套之后写代码之前, Dev 主写实现方案设计, Architect / PM / Security / QA 4 角色 review 全 ✅ 才放行写代码
7. **blueprintflow:pr-review-flow** — PR (Teamlead 开) 之后双 review + Security checklist + 标准 squash merge (永远不 admin / ruleset bypass)

产出: milestone 全 merged + acceptance template ⚪→🟢 翻状态 + REG-* 留痕

### 阶段 4: 持续推进 + Phase 退出
**目标**: idle 派活 + 偏差纠正 + issue 分类 + Phase 退出 gate

8. **blueprintflow:teamlead-fast-cron-checkin** — 15 min cron, idle 角色派活 (PR 维度)
9. **blueprintflow:teamlead-slow-cron-checkin** — 2-4h cron, 偏差 audit (蓝图偏差维度)
10. **blueprintflow:issue-triage** — 3h cron, 扫 GitHub issues, Teamlead 先判分发给 Architect / PM / QA (issue 维度, 跟 fast/slow cron 平行不重叠)
11. **blueprintflow:phase-exit-gate** — Phase 收尾联签 + closure announcement

### 阶段 5: 蓝图迭代 (Phase 都过完之后)
**目标**: 当前蓝图验收过 → 演进到下一版蓝图 (3 状态机 + 版本号管理)

12. **blueprintflow:blueprint-iteration** — 3 状态机 (current / next / GitHub issues backlog) + major / minor 版本号 + 变更怎么走 (真 bug 进当前 patch / 不是 bug 进 backlog) + 定下来 + tag 切版

产出: 新版蓝图定下来 + 旧版 git tag 留历史 + source-issues.md 留来源

## 起团窗格排版 (仅 tmux 环境)

> 下面这部分只在有 tmux 的环境下适用. 其他环境的起团方式见 `blueprintflow-runtime-adapter`.

用 tmux 起团时, 窗格排版要合理化 — 不能全堆一行扁条, 一眼看不出谁在干什么.

### 推荐布局 (6 角色团 + Teamlead)

```
┌─────────────────┬──────────────┬──────────────┐
│                 │  Architect   │  PM          │
│   Teamlead      ├──────────────┼──────────────┤
│   (顶部宽窗)    │  Dev-A       │  Dev-B/C     │
│                 ├──────────────┼──────────────┤
│                 │  QA          │  Designer    │
└─────────────────┴──────────────┴──────────────┘
```

- **Teamlead 占左半屏整列** (协调主线, 视野最大)
- **6 角色右侧 2x3 网格** (每格高度均等, 名字一眼能看见)
- Security 必备独立角色, 必须占一格 (不允许 Architect 兼任); Designer 按项目需要追加, 没视觉新组件可以不占格

### 起团命令骨架

> 前置: settings.json 开 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. tmux session 内 `teammateMode` 默认 auto = split-pane.

```bash
# 1. 起 tmux 画布, 切好 2x3 网格
SESSION=blueprintflow
tmux new-session -d -s $SESSION -x 220 -y 60
tmux split-window -h -p 60 -t $SESSION:0
tmux split-window -v -p 66 -t $SESSION:0.1
tmux split-window -v -p 50 -t $SESSION:0.2
tmux split-window -h -t $SESSION:0.1
tmux split-window -h -t $SESSION:0.3
tmux split-window -h -t $SESSION:0.5

# 2. 给 pane 命名 (status line 显示)
tmux set-option -t $SESSION pane-border-status top
tmux select-pane -t $SESSION:0.0 -T 'teamlead'
tmux select-pane -t $SESSION:0.1 -T 'architect'
# ... pm / dev-a / dev-b / qa / security 等

# 3. 只在 Teamlead pane 起 claude
tmux send-keys -t $SESSION:0 'claude' Enter
tmux attach -t $SESSION
```

进 Teamlead session 后, lead 用 team mode 工具建 team + spawn 角色 — 不用手动给每个 pane 起 claude. Claude Code 会自己起 child claude 进程把剩余 pane 填上. 通讯走 mailbox 通知 (具体命令见 `blueprintflow-runtime-adapter` → `references/claude-code.md`).

### 窗格反模式

- ❌ 全部左右切 (7 列扁条, 内容看不全)
- ❌ Teamlead 跟角色混排 (协调主线被淹没)
- ❌ pane 不命名 (status line 全是 `bash`, 找不到谁是谁)
- ❌ 一个会话开一个窗口 (跨窗口切换慢, 一屏看不到全貌)

## 关键协议

- **Git workflow** (见 `blueprintflow-git-workflow`): Teamlead 唯一创建 `.worktrees/<milestone>` + branch `feat/<milestone>`, 全员同一个 worktree 叠 commit, **角色不开 PR, Teamlead 唯一开 PR**, PR merged 后 Teamlead 删 worktree.
- **一个 milestone 一个 PR**: 4 件套 + 三段实施 + e2e + docs/current sync + REG flip + acceptance ⚪→✅ + PROGRESS [x] **全在同一个 PR**, 不拆多个 PR. 不开 closure follow-up.
- **PR 合并永远不 admin bypass / 不 ruleset disable** (硬红线, 见 pr-review-flow): CI 必须真过, flaky 真修不绕 (包括 PR template lint 误报 / e2e flaky / coverage 卡线 — 都是修不绕)
- **PR template 顶部 4 行裸 metadata**: `Blueprint: §X.Y` / `Touches:` / `Current 同步:` / `Stage: v0|v1` (或者 h2 章节式)
- **Migration v 号串行发号** (如适用): 分配前先 grep 确认
- **规则 6 (current 同步)**: 代码改了 → docs/current 必须同步, PR 级 lint 强制
- **规则漂移 5 层防御**: spec grep + acceptance 反查锚点 + stance 黑名单 + content-lock 字面一致 + PR 跨文件 cross-check
- **author=lead-agent 不能 self-approve**: 用 `gh pr comment <num> --body "LGTM"` 等同批准

## 反模式

- ❌ 跳过 4 件套直接实施 (规则漂移抓不出来)
- ❌ 一个角色多个 milestone 并行 (worktree 冲突)
- ❌ 把 audit 当成推进 (audit + 派活才算推进)
- ❌ **任何形式的 admin merge / ruleset disable / 绕过 required CI** (永久禁, 不接受"临时"/"兜底"借口)
- ❌ idle 不派活 (cron 必须 ACT)

## 起步

```
1. blueprintflow:team-roles      — spawn 6 角色 (按需)
2. blueprintflow:brainstorm      — 定概念 + 规则
3. blueprintflow:blueprint-write — 落蓝图
4. blueprintflow:phase-plan      — 拆 Phase
5. (循环) blueprintflow:milestone-fourpiece + blueprintflow:pr-review-flow + blueprintflow:teamlead-fast-cron-checkin
6. (定期) blueprintflow:teamlead-slow-cron-checkin
7. (Phase 收尾) blueprintflow:phase-exit-gate
```

## 激活协议 (必须启 cron)

**workflow 一激活, Teamlead 必须启动 fast + slow 两个 cron**:

```
启动巡检 (具体命令见 blueprintflow-runtime-adapter 对照表):
  频率: 每 15 分钟
  内容: "[自动巡检 · 15 min] Phase 进展 + idle 派活检查 (按 blueprintflow-teamlead-fast-cron-checkin 走)"

启动巡检 (具体命令见 blueprintflow-runtime-adapter 对照表):
  频率: 每 2 小时
  内容: "[偏差 audit · 2 小时] 蓝图 / docs/current / 翻牌延迟检查 (按 blueprintflow-teamlead-slow-cron-checkin 走)"
```

**为什么必须启**:
- agent 不会主动打卡, **没 cron 推就 idle**, 长项目主动检查频次会降到 0
- 大需求长周期下, 不主动派活 = 隐形拖延 (用户问"为什么停下了"= 这条触发)
- fast cron 看 PR 队列 + idle 派活, slow cron 看蓝图 / PROGRESS / 翻牌延迟, 双轨覆盖

**关停**:
- workflow session 结束 → durable: false 自动消失
- 如果要暂停巡检 (比如 brainstorm 期间不派活) → `CronDelete` 显式删, 别让它无脑派

**反模式**:
- ❌ 只启 fast cron 不启 slow → 长期偏差累积没人 audit
- ❌ 启 cron 但 prompt 不引 `blueprintflow:teamlead-{fast,slow}-cron-checkin` → cron 行为不可控
- ❌ durable: true 没用户拍板 → 跨 session 残留, 别项目误派

## 跨项目使用

虽然叫 `blueprintflow:`, 这套 workflow 是通用的:
- 角色名默认用英文 (Architect/PM/Dev/QA/Designer/Security), 也可以用自定义别名
- 路径 / 文档结构 (`docs/blueprint/`, `docs/implementation/`, `docs/qa/`) 是约定俗成, 项目可以调
- worktree / migration / lint 协议是核心, 不动
