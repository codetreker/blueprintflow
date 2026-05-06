---
name: blueprintflow-milestone-fourpiece
description: "Milestone 实施前先建立 4 件基线文档 (Architect spec brief / PM stance + content lock / QA acceptance template), 把规则定下来 + 拆段 + 验收 + 文案, 跟 implementation design + 实施 + e2e + closure 全在同一个 milestone PR 内. 触发: Phase plan 拆完 milestone, 启动具体 milestone / Teamlead 唯一创建 .worktrees/<milestone> 派活给 Architect/PM/QA. 反触发: 蓝图层规则还没定 (走 brainstorm / blueprint-write) / Phase 拆段 (走 phase-plan) / 已经有 4 件套进 implementation design (走 implementation-design) / docs-only / hotfix 紧急路径."
version: 1.0.0
---

# Milestone 4 件套

每个 milestone **一个 PR 一次合**: 4 件套 + 三段实施 + e2e + docs/current sync + REG flip + acceptance ⚪→✅ + PROGRESS [x] **全在同一个 PR** 里. 不再拆 spec / acceptance / 文案锁 / stance 4 个独立 docs PR, 也不拆 schema / server / client 三个实施 PR.

**git workflow 配套** (见 `blueprintflow-git-workflow`):
- Teamlead 创建 `.worktrees/<milestone>` + branch `feat/<milestone>`
- 4 件套作者 (Architect / QA / PM) **不单独开 PR** — 全员在同一个 worktree 叠 commit
- 全员 commit 完 → Teamlead 唯一开 PR

**反例 (旧做法)**: 一个 milestone 拆 8-10 个 PR, 每个都要双 review + CI + rebase + §5 totals 串行写竞争 + closure follow-up 拖尾. 实际比"一 PR 整 milestone"慢得多.

## 4 件套

### 1. Architect spec brief
**Path**: `docs/implementation/modules/<milestone>-spec.md` (≤80 行)

> **注**: spec brief 只写 §0-§4, 不允许 §5+ 派活 / 自审 / 更新日志段 (见反模式).

结构:
- §0 关键约束 (3 条规则)
- §1 拆段 ≤3 PR (schema / server / client)
- §2 留账边界 (跟其他 milestone 接口)
- §3 反查 grep 锚点 (含边界)
- §4 不在范围 (留 v2+)

> **实战案例 (Borgee):** spec brief 实例参考 RT-1 / CHN-1 / AL-3 / CV-1 / AL-4, 每篇 50-80 行, 含 schema + server + client 拆段.

### 2. PM stance checklist
**Path**: `docs/qa/<milestone>-stance-checklist.md` (≤80 行)

结构:
- 5-7 条规则, 每条一句话锚 §X.Y + 边界 (X 是, Y 不是) + v0/v1
- 黑名单 grep + 不在范围 + 验收挂钩
- v0/v1 transition criteria (如果需要, 按 v1 transition 同样的 PR # 锁规则)

### 3. QA acceptance template
**Path**: `docs/qa/acceptance-templates/<milestone>.md` (≤50 行)

结构:
- 跟拆段 1:1 对齐 (§1 schema / §2 server / §3 client)
- 验收四选一: E2E / 蓝图行为对照 / 数据契约 / 行为不变量
- REG-* 寄存器占位 (留 ⚪ 等实施翻 🟢)
- 反查锚点 + 退出条件

### 4. PM content lock (只有 client UI milestone 必备)
**Path**: `docs/qa/<milestone>-content-lock.md` (≤40 行)

结构:
- DOM 字面锁 (data-* attr / 文案字面一致)
- 边界: 同义词禁词 + 反向 grep
- demo 截屏路径预备

如果 milestone 涉及视觉新组件, 跟 Designer design system 联动 (未来扩展).

## 步 5: 写代码之前 Dev 出 Implementation Design

4 件套就位之后、拆段实施之前, Dev 主写一份实现方案设计文档 (`docs/implementation/design/<milestone>.md`), 由 Architect / PM / Security / QA 4 角色 review, **全 ✅ 才放行写代码**.

适用范围:
- ✅ 涉及代码的 milestone **必走** (schema / server / client 任一改动)
- ❌ 非代码 milestone (docs-only / config-only / 字面调整) 可以跳

PR 协议:
- 设计文档**不是独立 PR** — 跟 4 件套同一个 worktree 叠 commit, 全在 milestone PR 里 (守"一个 milestone 一个 PR"铁律)
- review 走 worktree 内通讯 / PR comment, 不靠开独立 PR

完整规格见 `blueprintflow-implementation-design`.

## 4 件套之间字面一致硬条件

spec / stance / acceptance / content-lock 互相引 §X.Y 锚点, 任一漂移其他 review 时抓得出来 (跨 PR drift 抓得到).

> **实战案例 (Borgee):** QA 自查发现 acceptance template 字段名跟 spec brief drift (字段改名没同步), 当场 patch 修齐 (双轨 review 起作用).

## 派活模板

milestone 启动时 (**Teamlead 唯一**创建 worktree + 派活):

```bash
# 1. teamlead 创建 worktree (一个 milestone 一个 worktree)
cd <repo-root>
git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main
```

```
2. 派 Architect (在 .worktrees/<milestone> 里): spec brief, commit + push, 不开 PR
3. 派 PM (同一个 worktree): stance checklist + content lock, commit + push, 不开 PR
4. 派 QA (同一个 worktree): acceptance template, commit + push, 不开 PR
5. 派 Dev (同一个 worktree): 写 implementation design (docs/implementation/design/<milestone>.md), commit + push
6. 派 Architect / PM / Security / QA review design, 全 ✅ 才放行
7. 派 Dev (同一个 worktree): 三段实施 + e2e + docs/current sync + REG / acceptance / PROGRESS 状态翻, commit + push, 不开 PR
8. 全员就绪 → teamlead 唯一开 PR (gh pr create)
9. PR merged → teamlead 删 worktree
```

详细 git 协议见 `blueprintflow-git-workflow` (角色不开 PR / teamlead 唯一开 PR / 一个 worktree 一个 milestone).

## 拆段实施 (在同一个 PR 里顺序提交)

全员在**同一个 worktree + 同一个 branch** 里叠 commit (角色都不开 PR, teamlead 最后开):
- 1.1 schema (migration v=N + 表 + drift test) — Dev
- 1.2 server (API + 业务逻辑 + 反向断言 test) — Dev
- 1.3 client (UI + e2e) — Dev
- 1.4 docs/current sync (server / client docs) — Dev
- 1.5 REG-* 翻 🟢 + acceptance template ⚪→✅ + PROGRESS [x] — QA / Dev
- (并行) spec brief — Architect
- (并行) stance + content lock — PM
- (并行) acceptance template — QA

worktree 协议:

```bash
# teamlead 创建 (唯一)
cd <repo-root>
git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main

# 角色干活 (多人多 commit OK, 全员 push 同一个 branch)
cd .worktrees/<milestone>
# ... 干活 ...
git push origin feat/<milestone>

# teamlead 唯一开 PR (所有角色就绪之后)
gh pr create --title "feat(<milestone>): ..." --body "..."

# PR merge 之后 teamlead 删 worktree (唯一)
cd <repo-root>
git worktree remove .worktrees/<milestone>
```

## Closure 在 PR 内一次落, 不开 follow-up

acceptance ⚪→✅ + REG-* + PROGRESS [x] 都在实施 PR 里同一个 commit 落. **不开 closure follow-up PR**.

## 文件命名规范

代码文件按**实际功能**命名, 不按 milestone 编号.

**正模式:**
- `agent_status.go` — 一看就知道是 agent 状态相关
- `canvas_renderers_test.ts` — 一看就知道测的是 canvas 渲染器
- `privacy_promise.tsx` — 一看就知道是隐私承诺组件

**反模式:**
- ❌ `al_1b_2_status.go` — 半年后没人记得 `al_1b` 是什么 milestone
- ❌ `cv_3_3_renderers_test.ts` — 要先查 `cv-3-3` 是哪个 milestone 才知道测什么
- ❌ `cm5stance/` — 目录名是 milestone 编号的拼接, 应该叫 `stance_checklist/`

**原则:** milestone 编号是项目管理概念, 不该出现在文件名里. 文件名是给人和代码工具看的, 要一看就懂. 在 PR description 和 commit message 里引 milestone 编号就够了.

## 反模式

- ❌ 跳过 4 件套直接实施 (规则漂移抓不出来)
- ❌ 拆成多个 PR (spec / schema / server / client / closure 各自一个 PR, 反而慢)
- ❌ 实施 PR 不引 spec § 锚点 (跨 PR drift 抓不出来)
- ❌ 用 `/tmp/<work>` 临时 clone (改用 `.worktrees/<milestone>`)
- ❌ 一个 milestone 多个 branch (撞车 + 历史脏)
- ❌ **spec brief 写 §5/§6/§7 (派活 / Architect 自审 / 更新日志) 段**

 **背景**: 末段信息全是重复 — 派活记录在 PR body + 通讯历史已有, Architect 自审走 PR review comment, 更新日志 git log + git blame 自带; 而且末段 narrative changelog 是 docs 撞冲突的主因 (共享 changelog / closure 段 / spec brief 末尾几行被多个 wave 并行状态翻全堵在这里).

 > **实战案例 (Borgee):** 60+ 篇 spec brief 都中招, 末段 narrative changelog 集中撞 `phase-4.md` / `closure §1` / spec brief 末尾几行.

 **如何应用**: spec brief ≤80 行只保 §0-§4 (关键约束 / 拆段 / 留账 / 反查 grep / 不在范围). 派活走通知 / Task, 自审走 PR review comment, 更新日志走 git log + PR body, 不在 spec brief 末尾叠 narrative changelog.

- ❌ **文案锁早于实施太久, 不跟既有实施 cross-grep**

 **背景**: 文案锁草稿期写的字面跟既有实施对不上, 文案锁字面没跟既有实施 cross-grep, 后续实施对齐了既有代码 (合理), 文案锁文档变孤儿.

 **如何应用**: 写文案锁之前必跑 grep 反查既有实施: `grep -rnE "<候选字面>" <client-package>/ <server-package>/`. 如果有命中既有字面, 文案锁字面跟它对齐, 不要按草稿臆想字面写; 如果既有实施跟规则冲突, 应该同步改实施 + 文案锁两边字面一致.
