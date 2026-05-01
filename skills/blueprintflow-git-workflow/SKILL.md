---
name: blueprintflow-git-workflow
description: Blueprintflow 的 git 协作规范：一 milestone 一 worktree 一 branch，全员同 worktree 叠 commit，teamlead 唯一开 PR。前提：项目已采用 blueprintflow 工作流。触发词：git worktree、开 branch、milestone 分支。触发场景：milestone 启动创建 worktree 时。
version: 1.0.0
---

# Git Workflow (Milestone 协议)

用户 2026-04-29 拍板的硬规范. 跟 `blueprintflow-pr-review-flow` (合并红线) + `blueprintflow-milestone-fourpiece` (4 件套并入实施 PR) 配套.

## 🔒 硬规范 (不可商量)

### 规则 1: 一 milestone 一 worktree 一 branch

每个 milestone 起步时, **teamlead** (唯一) 创建:

```bash
cd <repo-root>
git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main
```

- 路径: `.worktrees/<milestone>` (repo 根的 `.worktrees/` 下, 不在 `/tmp/`)
- 分支: `feat/<milestone>` (e.g. `feat/<milestone-a>` / `feat/<milestone-b>` / `feat/<milestone-c>`)
- base: `origin/main` (rebase 时也 rebase main, 不 stack 别 milestone)
- 一个 milestone 整个生命周期 **复用同一 worktree + 同一 branch**

### 规则 2: 全员同 worktree 干活

milestone 涉及的所有角色 (Dev/Architect/QA/PM/Designer/Security) **在同一 worktree 叠 commit**:

| 角色 | 在 worktree 里做的事 |
|---|---|
| Dev | 写代码 (server-go / client / e2e) + 单测 + 截屏 |
| Architect | 写 spec brief (`docs/implementation/modules/<milestone>-spec.md`) |
| QA | 写 acceptance template (`docs/qa/acceptance-templates/<milestone>.md`) + acceptance 验收翻 ⚪→✅ |
| PM | 写 stance checklist + content lock (`docs/qa/<milestone>-{stance,content-lock}.md`) + 立场反查 |
| Designer (UI) | 视觉对照 + design system 锚 |
| Security | auth/admin/cross-org 路径 review (作为 commit) |

**全员可以 commit + push 到 `feat/<milestone>` 分支**. 不需要起子 branch / 不需要 stash / 不需要 cherry-pick. 互相能看到对方 commit, 跟跨角色 review 同步进行.

### 规则 3: 角色不开 PR

**任何角色** (包括 Dev) **绝对不能** `gh pr create`. 永久禁:

```bash
# ❌ Dev 不开
gh pr create --title "feat(<milestone>.1): schema"

# ❌ Architect 不开
gh pr create --title "docs(<milestone>): spec brief v0"

# ❌ QA 不开
gh pr create --title "docs(qa): <milestone> acceptance template"

# ❌ PM 不开
gh pr create --title "chore(<milestone>): stance + content-lock"
```

PR 是 milestone 完整产物的入口, 不是单角色的产物. 角色单独开 PR 会:
- 拆碎 milestone (违反 一 milestone 一 PR)
- 制造 §5 totals / acceptance template / PROGRESS.md 多 PR 串行写竞争
- 制造 closure follow-up 拖尾

### 规则 4: PR 由 teamlead 唯一创建

milestone 全员工作都 commit 完 + push 完 + 自检过后, **teamlead** 唯一开 PR:

```bash
cd <repo-root>/.worktrees/<milestone>
gh pr create --title "feat(<milestone>): <summary>" --body "..."
```

PR body 必须装齐 4 件套全部内容 + 三段实施 + e2e + closure (REG flip / acceptance ⚪→✅ / PROGRESS [x]) — 对应 `blueprintflow-milestone-fourpiece` 协议.

teamlead 开 PR 时心智:
- 全员都 commit 进 `feat/<milestone>` 了吗? (Dev 代码 + Architect spec + QA acceptance + PM stance/content-lock 全齐)
- docs/current sync 跟代码同步了吗?
- regression-registry §5 totals 数学闭吗?
- PROGRESS.md `[x]` 翻牌了吗?

任一不全, 不开 PR — 派回缺的角色补 commit.

### 规则 5: PR merged 后 teamlead 删 worktree

```bash
cd <repo-root>
git worktree remove .worktrees/<milestone>
git branch -d feat/<milestone>  # 如未自动 prune
```

worktree 生命周期完全由 teamlead 管. 角色不动 worktree (不删 / 不切 branch / 不创新 worktree).

## 工作流时序图

```
teamlead                角色 (Dev+Architect+QA+PM+...)         GitHub
   │                            │                                │
   │── git worktree add ──────► │                                │
   │   .worktrees/<milestone>   │                                │
   │   -b feat/<milestone>      │                                │
   │                            │                                │
   │── 派活给角色 (在 worktree 里干) ►│                          │
   │                            │── commit + push ──────────────►│
   │                            │    (Dev 代码 / Architect spec /        │
   │                            │      QA acceptance / PM stance) │
   │                            │── 跨角色 review (commit 评论 + │
   │                            │   通知) ─────────────── │
   │                            │── 全员自检 + commit 完成      │
   │ ◄──────── 全员就绪信号 ──── │                                │
   │                                                             │
   │── gh pr create ──────────────────────────────────────────►│
   │                                                             │
   │── 派 review subagent (双角度) ────────────────────────────►│
   │                                                             │
   │── 标准 squash merge (CI 真过) ────────────────────────────►│
   │   (永远不 admin / 不 ruleset bypass — 见 pr-review-flow)    │
   │                                                             │
   │── git worktree remove ──── 清理                              │
```

## 反模式

### ❌ 角色自己开 PR
任何角色 `gh pr create` 都是越权. 历史血账:
- Architect单开 spec brief PR → 制造 4 件套串行
- QA单开 acceptance template PR → 拆碎 milestone
- Dev拆 .1 schema / .2 server / .3 client / .4 closure 多 PR → 撞车 + rebase 噩梦

### ❌ 不同 milestone 用同 worktree
worktree 跟 milestone 1:1 绑定. 不允许:
- 一个 worktree 装两个 milestone (e.g. `.worktrees/<milestone-a>` 里夹 <milestone-b> commit)
- 跨 milestone branch (e.g. `feat/<milestone-a>-and-<milestone-b>`)
- worktree 复用 (e.g. `.worktrees/<milestone-c>.2` 里干 <milestone-c> 下一版 — 应该删旧 worktree 起新的, 或同 branch 同 worktree 走完)

### ❌ closure follow-up PR / spec 漂移 follow-up PR
新协议下不存在 follow-up PR. 翻牌 / 字面 sync / closure 全在主 PR 里搞定. 主 PR merged 后发现漂 → 下一个 milestone PR 顺手补, 不开独立 follow-up.

例外 (谨慎): 真硬 bug fix 可独立 PR (e.g. `fix/ci-flaky-xyz`), 但**不算 milestone PR**, teamlead 也不当 milestone follow-up.

### ❌ teamlead 替角色写代码
teamlead 创 worktree + 派活 + 监督 + 开 PR + 删 worktree, **不下场写代码 / spec / acceptance / 文案锁**. 写就是越权 (跟 city engineer 总包不砌墙同).

### ❌ worktree 复用相同路径不同 branch
dev-d 派 <milestone-d> 起 `.worktrees/<milestone-d>` + branch `feat/<milestone-d>-server-client`, 之后 dev-e 同路径起 branch `feat/<milestone-d>` — 撞车直接覆盖 dev-e 工作. **同一 worktree path 同时只能由 teamlead 创建一次, 同时只能一个 branch**. 角色不动 worktree.

### ❌ /tmp/ 临时 clone
`/tmp/<role>-<topic>-work` clone 模式已弃用. 全部 `.worktrees/<milestone>` 走.

## 跟其他 skill 配套

- `blueprintflow-milestone-fourpiece` — 4 件套并入实施 PR (一 milestone 一 PR), 写 4 件套也是在 worktree 里 commit, 不单独开 PR
- `blueprintflow-pr-review-flow` — PR 由 teamlead 开后走双 review + 标准 squash (永远不 admin/ruleset bypass)
- `blueprintflow-workflow` — 顶层时序: 概念 → Phase → milestone (走本 skill) → 退出 gate

## 跨 milestone 并行

N 个 milestone 同时跑 = N 个 worktree + N 个 branch. teamlead 各自创/各自删. 角色按派活分到不同 worktree 干活:

```
.worktrees/<milestone-a>    ← teamlead create, dev-c + Architect spec + QA acceptance commit
.worktrees/<milestone-b>    ← teamlead create, dev-d + Architect + QA + PM commit
.worktrees/<milestone-c>     ← teamlead create, dev-a + ...
.worktrees/<milestone-d>    ← teamlead create, dev-b + ...
```

同一Dev一次只能在一个 worktree 干 (worktree 隔离, 不允许同时双 in-flight). 不同Dev并行 N milestone OK.

## 调用方式

milestone 启动时:
```
follow skill blueprintflow-git-workflow
teamlead 创建 .worktrees/<milestone> + feat/<milestone>
派活给角色, 全员同 worktree 叠 commit
全员就绪 → teamlead 开 PR → merged → teamlead 删 worktree
```
