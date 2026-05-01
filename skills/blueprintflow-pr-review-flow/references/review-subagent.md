# Review Subagent 并行模式

### Review subagent 并行模式 (加速 — 推荐)

不通知 persistent 角色 (Architect/QA/PM) 而是 spawn fresh review subagent. 三个收益:

1. **不打断**: persistent 角色继续手头工作 (写 spec / acceptance / 文案锁), 不切回来 review
2. **context 干净**: subagent 只读 PR + spec + 几个 cross-ref 锚, 没 inbox 噪音
3. **可并行**: 同时派 N 个 subagent (架构 + 立场 + 文案 各一), 一波出多 LGTM

**实测**: review subagent 并行 (架构 + 立场各一) 总耗时约 1 分钟, vs persistent 角色串行 6-10min. **8x 速度提升**.

#### 派 review subagent 模板

```
Agent({
 description: "Parallel <视角> review #<N>",
 subagent_type: "general-purpose",
 run_in_background: true,
 prompt: `
你是 codetreker/<repo> 项目的临时 reviewer (subagent, fresh context, 不是 persistent 角色).

任务: review **PR #<N> <题目>** (<author> author).
视角: **<架构 | 立场 + 文案 | acceptance + 反查锚>** 角度.

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
