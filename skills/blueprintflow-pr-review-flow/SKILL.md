---
name: blueprintflow-pr-review-flow
description: "PR open 到 merged 的标准流程: 双 review 路径 (Architect 架构 + QA acceptance + 涉敏感加 Security) + Security checklist (12 类 lazy reference) + 三联签 merge gate (CI + LGTM + 任务完成度) + 标准 squash, 永不 admin/ruleset bypass。触发: PR open 后派 review / 收 LGTM 后 merge / merge 前 CI fail 处理。反触发: PR 还未 open (走 milestone-fourpiece + implementation-design) / 实施未完 (走 4 件套 / design review) / draft PR 未 ready / 蓝图层立场审查 (走 brainstorm)。"
version: 1.0.0
---

# PR Review Flow

PR open 后到 merged 的标准流程.

## PR 出之前: implementation design 4 ✅ 必备

milestone PR 开之前, 涉及代码的 milestone **必须**已通过 implementation design 4 角色 review:

- 设计文档: `docs/implementation/design/<milestone>.md` (Dev 主写)
- 4 角色 ✅: Architect (架构 + 立场) / PM (用户价值 + UX) / Security (鉴权 / 数据隔离 / cross-org) / QA (可测性 + 边界 case)
- review 走 worktree 内通讯 / PR comment, 不开独立 PR
- 任一 ❌ 阻塞 — 不允许开 milestone PR

完整规格见 `blueprintflow-implementation-design`。

非代码 milestone (docs-only / config-only / 字面调整) 可跳此步, 直接进 PR review。

## Security review 走清单 (lazy reference)

Security 角色做 PR review 时, 引 `references/security-checklist.md` 走 12 类清单 (鉴权/输入验证/敏感数据/会话凭证/rate limit/依赖/配置部署/业务逻辑等)。

- 清单**不进 SKILL.md 主体** — 节省主流程 context
- Security review 时按 PR 改动范围挑相关条目查
- LGTM 评论必引具体清单条目 (e.g. "§1 鉴权 ✅, §8 IDOR 见 line 42 已防"), 反 "笼统过审"

详见 `references/security-checklist.md` (12 类, 每类 bullet + "为什么 + 怎么验")。

## 🚫 永久禁 (硬红线 — 不可商量)

以下手段**永远禁用**, 任何场景任何理由都不允许. 这是用户 2026-04-29 拍板的硬红线, 不接受 "临时" / "兜底" / "flaky" / "急" 任何借口:

1. **`gh pr merge --admin`** — 任何形式的 admin bypass flag
2. **Ruleset disable / restore** — 哪怕 "≤10s 暴露" 也不行
3. **任何绕过 required CI checks 的方式** — 改 ruleset 移除 check / 改 branch protection / 关 required reviewers / 给自己加 admin role 等等

**为什么是硬红线**:
- admin bypass 掩盖 bug — flaky 后面是真 bug 的概率比表面看高
- 让 "CI 真过" 协议失效, 团队信号噪音化
- 历史血账: e2e fail bypass 进 main 多次, 每次都得 hotfix 善后

**反模式 (永久)**:
- ❌ `gh pr merge --admin` 任何场景
- ❌ `gh api -X PUT /rulesets/<id> -f enforcement=disabled` 任何场景
- ❌ 派 "admin merge agent" / "batch admin merge agent" — agent 名字本身已弃用
- ❌ "ruleset 兜底" / "临时过渡" 这类话术 — 不存在临时, 临时就是永久的开始

## PR template 必备

顶部 4 行裸 metadata + 2 段 H2:

```
Blueprint: blueprint/<file>.md §X.Y
Touches: <packages or docs>
Current 同步: <说明 or N/A — 理由>
Stage: v0|v1

## Summary
...

## Acceptance
- [x] ...

## Test plan
- [x] ...
```

PR template lint 5 字段缺任一 → 红, 走 lint patch 流程修 (修 body / 修 lint regex, **不绕**).

## Flaky test 处理

**Flaky test 信号识别**:
- PR 没改相关代码，但 CI case fail 了 → flaky 信号
- 同一 case 在不同 PR 随机 fail → flaky 信号
- main 上已经偶尔 fail → flaky 信号（不是借口，是更需要修的理由）

**Flaky test 处理原则：修，不是 rerun**:
- 发现 flaky → 立即修根因，不是 rerun 碰运气
- 真 flaky → 真修根因（竞态、时序、环境依赖）
- lint 误报 → 修 lint 规则
- coverage 卡线 → 真补 test 提覆盖率
- e2e 真 fail → 退给 author 修 bug
- 任何场景下, **"等我修完再合"** 是唯一答案, 不存在 "先合进去再说" 选项

**Flaky 反模式**:
- ❌ **rerun 碰运气** — flaky 不会自己好，rerun 绿了只是运气好，下次还会 fail
- ❌ **"不是我改的，main 上就存在"** — 至少开 issue 跟踪，最好顺手修。不 block 当前 PR，但不能假装没看见
- ❌ **"先合进去，后面再修 flaky"** — 进了 main 就没人修了，flaky 只会越积越多
- ❌ **rerun 3 次绿了就当过了** — 3 次里 1 次 fail = 33% 失败率，这不是"偶尔"，是真 bug

## 双 review 路径

每 PR 立即派双 review:

| PR 类型 | reviewer 1 | reviewer 2 | reviewer 3 (可选) |
|---|---|---|---|
| Dev实施 PR | Architect (架构) | QA (acceptance) | — |
| Architect spec brief PR | Dev (实施视角) | QA (acceptance 可机器化) | PM (立场) |
| PM stance / content-lock PR | Architect (架构) | QA (acceptance) | — |
| QA acceptance template / 翻牌 PR | Architect (架构) | PM (立场, 仅 v0 立场相关时) | — |
| 涉敏感写动作 (auth/admin) PR | + Security (security) | | |

LGTM 命令 (author 不能 self-approve):
```
gh pr comment <num> --body "LGTM (理由 ≤30字)"
```

review 内容必须包含锚 (跟 spec/stance/acceptance 字面 cross-check):
- 跟 #<other-PR> 字面对得上吗?
- §X.Y 反约束守住吗?
- 跟 byte-identical 模板 (e.g. 跨 milestone 共享结构体模板) 一致吗?

**Merge 三联签** (CI + LGTM + 任务完成度):
- ① CI 真过 (statusCheckRollup 全 SUCCESS, 永远不 admin/ruleset bypass)
- ② ≥1 non-author LGTM (gh pr review --approve OR LGTM 评论 from 不同 reviewer 身份)
- ③ **teamlead 审 PR body Acceptance + Test plan 全勾** (`gh pr view <N> --json body | jq -r .body | grep -cE "^- \[ \]"` 必须 == 0)

三联签全过 → 标准 squash merge. 任一缺 → 不合.

详细 merge gate 协议见 `blueprintflow-teamlead-fast-cron-checkin §5`. 任务完成度判据 (一 milestone 一 PR 协议下) 在那里展开.

> Review subagent 并行模板见 `references/review-subagent.md`。

## 必读锚
1. \`gh pr view <N>\` — PR body + diff
2. \`gh pr diff <N>\` — 看具体改动
3. <spec brief / 文案锁 / acceptance template / 既有 cross-ref PR>
4. (可选) PR # 既有 LGTM 评论 — 已覆盖角度你不重复

## review 检查清单 (机器化反查)
- [ ] 拆段 1:1 跟 spec brief 对齐
- [ ] count 数学正确 (e.g. 26 项 = 5+7+7+7)
- [ ] byte-identical 锚跟 N 源对齐 (列出具体 PR # / commit SHA)
- [ ] 反约束 grep N 行强类型 (列出具体 grep pattern)

## 输出
- 全过: \`gh pr comment <N> --body "LGTM (<视角> review subagent). [一句话总结校验点]"\` — 落 GitHub
- NOT-LGTM: 不 comment, 报回具体问题点 + 引文 + 建议改法.

报告 ≤200 字.
`
})
```

#### 适用 vs 不适用

| 适用 | 不适用 |
|---|---|
| 4 件套例行 review (byte-identical / 反约束 grep / 拆段 1:1) | 架构判断 / drift 综合仲裁 (e.g. envelope 9 vs 10 字段算不算 drift) |
| acceptance template / stance / 文案锁 review | spec brief 真写 (创造性工作) |
| count 数学对账 / REG 占号翻牌 | NOT-LGTM 仲裁 (升级 persistent 角色) |

#### 混合模式协议

1. PR open → 派 review subagent (N 角度并行) 跑机器化校验
2. 全 LGTM + CI 真过 → 标准 merge (见下方 Merge 段, **永远不 admin/ruleset bypass**)
3. NOT-LGTM 或跨 PR drift 嫌疑 → 升级给 persistent 角色仲裁
4. persistent 角色保留: spec brief / stance / acceptance / 文案锁 author 工作 + drift 仲裁 + 跨 milestone 综合判断

#### 反模式

- ❌ subagent review 替 persistent 角色 author 工作 (subagent 只读不写 spec brief / 文案锁)
- ❌ NOT-LGTM 由 subagent 自己仲裁 (升级 persistent)
- ❌ subagent prompt 不带具体 cross-ref PR # / commit SHA (review 失去 byte-identical 验证能力)

## Merge (标准 squash, 永远不 admin)

派 general-purpose agent (background) 跑. **绝对不 admin / 不 ruleset disable / 不 bypass 任何 required check**:

```
Merge PR #<N>:

1. gh pr view <N> --json statusCheckRollup,mergeStateStatus,reviews,body
2. 检查 ≥1 non-author LGTM (gh pr review --approve OR LGTM 评论 from 不同 agent role)
3. 如 PR template lint 缺字段:
   patch body via gh api -X PATCH /repos/<owner>/<repo>/pulls/<N> --input <(jq ...)
   close+reopen 触发 lint rerun (修 body, **不**修 lint enforcement)
4. CI 真过 (statusCheckRollup 全 SUCCESS) + mergeable=CLEAN + ≥1 non-author LGTM
   → gh pr merge <N> --squash --delete-branch
   (注意: 命令里**不允许**带 --admin)
5. 任何 fail 场景退给 author 修, 不 bypass:
   - go-test/client-vitest/e2e/bpp-envelope-lint/coverage/build/typecheck FAILURE → author 修
   - PR template lint regex 误报 → 修 lint regex 让真合规 body 过, 不 bypass
   - DIRTY → author rebase main
   - 真 flaky → 重 trigger CI 重跑, 仍 fail 退 author 修根因
6. 报 merge time + SHA. 报告里**禁止**出现 "admin" / "ruleset disable" / "bypass" 任何字眼
```

注: `gh pr edit --body` 在某些环境不生效, 用 `gh api PATCH` 直 patch JSON.

#> Batch merge 模式详见 `references/batch-merge.md`。

## 跨 review 例子: 立场漂移抓出

> **实战案例（Borgee）：** QA review acceptance 时自检, 发现字段名跟Architect spec brief 不一致 (字段改名未同步), 当场 patch 修齐。

这就是双轨 review 起作用 — spec 写 A 形态, acceptance 自然按 A 写, drift 可以发现。

## 反模式 (汇总)

**永久禁 (硬红线, 已在文首单列)**:
- ❌ `gh pr merge --admin` 任何场景
- ❌ ruleset disable/restore 任何场景
- ❌ 任何绕过 required CI check 的方式
- ❌ "ruleset 兜底" / "admin merge agent" / "临时过渡" 话术

**Review 正模式**:
- ✅ 先通读完整文件，再看 diff
- ✅ 换位思考：“我是第一次读这个 skill 的 agent，读到这段会困惑吗？”
- ✅ 每个角色 review 角度必须不同：
  - **Architect**：架构一致性 + 成本合理性 + 跨 skill 矛盾
  - **PM**：用户体验 + 认知负担 + 新团队读得懂吗
  - **Dev**：可执行性 + 有歧义吗 + 按这个干活会不会卡住
  - **QA**：可验证性 + 怎么知道做对了 + 示例够不够
  - **Security**：代码漏洞（注入/XSS/SSRF）+ auth/权限最小化 + 敏感数据处理 + 依赖安全
  - **Performance**：算法复杂度 + 热路径性能 + 不必要的 IO/网络调用 + 内存/并发
- ✅ LGTM 前先找 3 个可以质疑的点，找不到再 LGTM
- ✅ 技术细节（命令、API、参数）必须查文档验证，不能信作者
- ✅ 检查有没有引入额外副作用——批量替换误伤格式、删改一处导致另一处断裂、改名导致引用失效
- ✅ 新增/修改代码后检查有没有破坏现有逻辑——回归思维，不只看新加的对不对，也看旧的还能不能跑
- ✅ 翻牌 (acceptance ⚪→✅ / REG flip / PROGRESS [x]) 跟实施代码在同一 milestone PR 内完成，不开 follow-up PR
- ❌ 跳过 PR template 5 字段 (lint 拒, 不要走 ## H2 重复 metadata 绕过)
- ❌ merge agent 报告里出现 admin/ruleset/bypass 字眼 (透明度 + 红线警报)
- ❌ self-LGTM 算双批 (同 GH 账号多 agent 评论 LGTM 不算 ≥1 non-author, 必须真 reviewer 不同身份)

**操作反模式**:
- ❌ LGTM 不读 PR 内容, 模板字面套话 (失去 cross-check 价值)
- ❌ 只看 diff 不看整体——漏掉上下文断裂、逻辑矛盾
- ❌ 没明显 bug 就 LGTM——review 不是“没错”就行，是“够好”才行
- ❌ 不质疑设计合理性——“规则上说得通”不等于“实际合理”（token 成本、用户体验、认知负担）
- ❌ 作者写什么信什么——技术细节必须验证（如命令、API、参数）

## 调用方式

PR open 后:
```
follow skill blueprintflow-pr-review-flow
派 review for PR #<N>
```
