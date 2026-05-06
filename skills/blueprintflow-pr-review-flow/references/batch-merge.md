## Batch mode (acceleration — multiple PRs in one go, still standard squash)

Instead of dispatching 1 merge agent per PR, dispatch 1 agent to handle N PRs. It shares lint / PR template knowledge and doesn't repeat checks. **Batch is also standard squash — no admin, no ruleset disable**.

**Measured**: 8 PRs in one batch take 5min, vs single-PR/single-agent ~5min × 8 = 40min. **8x speedup**.

#### Dispatching a batch merge agent — template

```
Agent({
 description: "Batch merge N PRs (squash, no admin)",
 subagent_type: "general-purpose",
 run_in_background: true,
 prompt: `
repo: codetreker/<repo>. batch merge multiple PRs (order-independent, concurrent):

| PR | content | LGTM |
|---|---|---|
| #N1 | <content> | <reviewer1> + <reviewer2> ✅ |
| #N2 | <content> | <reviewer1> ✅ (waiting on <reviewer2>, report back, don't merge) |
...

**Protocol red line**:
- Absolutely no \`--admin\` flag
- Absolutely no ruleset disable / PUT enforcement=disabled
- Any CI failure → don't merge, send back to author to fix

Order:
1. Handle the ones already with ≥1 non-author LGTM + CI all green + mergeable=CLEAN first
2. Report back the ones that don't qualify; don't force merge

For each:
- \`gh pr view <N> --json statusCheckRollup,mergeStateStatus,reviews\`
- PR template lint fail → patch body via gh api PATCH + close+reopen (don't bypass lint)
- CI all green + CLEAN + ≥1 non-author LGTM → \`gh pr merge <N> --squash --delete-branch\`
- Report SHA + time, ≤80 chars each

Total report ≤300 chars listing each PR's status (merged or skipped waiting LGTM/CI). The report must not contain the words admin/ruleset/bypass.
`
})
```

#### Trigger signals

- A reviewer drops LGTM on multiple PRs in one wave (e.g. "double LGTM signal: PR-A + PR-B") → batch agent
- A wave of four-piece acceptance lands across multiple PRs (e.g. multiple milestones land together) → batch agent

#### Anti-patterns

- ❌ Batch contains a NOT-LGTM PR (mixed review state, the agent doesn't know whether to stop or skip)
- ❌ Batch contains stacked PRs with cross-base dependencies (order lock requires sequential, can't run concurrent)
- ❌ Batch agent count > 5 (one agent tracking too many PRs invites confusion)
- ❌ Batch agent prompt containing `--admin` / ruleset disable instructions — **permanently forbidden**
