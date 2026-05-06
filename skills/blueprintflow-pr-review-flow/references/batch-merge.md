## Batch 模式 (加速 — 多 PR 一波, 仍然是标准 squash)

不是派 1 个 merge agent 处理 1 个 PR, 而是 1 个 agent 接 N 个 PR. 共享 lint / PR template 知识, 不重复检查. **batch 也是标准 squash, 不 admin / 不 ruleset disable**.

**实测**: 8 个 PR 一波 5min, 对比单 PR 单 agent ~5min × 8 = 40min. **8x 速度提升**.

#### 派 batch merge agent 模板

```
Agent({
 description: "Batch merge N PRs (squash, 不 admin)",
 subagent_type: "general-purpose",
 run_in_background: true,
 prompt: `
repo: codetreker/<repo>. batch merge 多个 PR (顺序无关并发):

| PR | 内容 | LGTM |
|---|---|---|
| #N1 | <内容> | <reviewer1> + <reviewer2> ✅ |
| #N2 | <内容> | <reviewer1> ✅ (待 <reviewer2>, 报回不 merge) |
...

**协议硬红线**:
- 绝对不 \`--admin\` flag
- 绝对不 ruleset disable / PUT enforcement=disabled
- CI 任何 fail → 不合, 退给 author 修

执行顺序:
1. 先处理已经 ≥1 个非 author LGTM + CI 真全绿 + mergeable=CLEAN 的
2. 不达标的报回, 不强行 merge

每个:
- \`gh pr view <N> --json statusCheckRollup,mergeStateStatus,reviews\`
- PR template lint fail → patch body via gh api PATCH + close+reopen (不 bypass lint)
- CI 全绿 + CLEAN + ≥1 个非 author LGTM → \`gh pr merge <N> --squash --delete-branch\`
- 报回 SHA + 时间 ≤80 字 each

总报告 ≤300 字, 列每个 PR 状态 (merged 或者待 LGTM / CI 跳过). 报告里禁止出现 admin / ruleset / bypass 字眼.
`
})
```

#### 触发信号

- reviewer 一波给多个 PR LGTM (比如 "双批 LGTM 信号: PR-A + PR-B") → batch agent
- 4 件套 acceptance 一波交多个 PR (比如多 milestone 一波交) → batch agent

#### 反模式

- ❌ batch 里含 NOT-LGTM 的 PR (混 review 状态, agent 不知道该停还是跳过)
- ❌ batch 里含跨 base 互相依赖的 stacked PR (顺序锁要 sequential, 不能并发)
- ❌ batch agent 数 > 5 (一个 agent 跟踪多个 PR 容易错乱)
- ❌ batch agent prompt 含 `--admin` / ruleset disable 任何指令 — **永久禁**
