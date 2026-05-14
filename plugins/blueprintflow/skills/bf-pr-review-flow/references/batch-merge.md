# Batch Merge Mode

One agent handles N PRs instead of N agents × 1 PR. Shares lint/template knowledge, doesn't repeat checks. **Still standard squash — no admin, no ruleset disable.** Measured: 8 PRs in 5min vs 40min single.

## Template

```
Agent({
 description: "Batch merge N PRs (squash, no admin)",
 subagent_type: "general-purpose",
 run_in_background: true,
 prompt: `
repo: codetreker/<repo>. Batch merge (order-independent, concurrent):

| PR | content | LGTM |
|---|---|---|
| #N1 | <content> | <reviewer1> + <reviewer2> ✅ |
| #N2 | <content> | waiting on <reviewer2> — report back, don't merge |

**Red line**: no --admin, no ruleset disable, CI failure → don't merge.

Order:
1. All required non-author LGTMs for the task content + CI green + CLEAN → merge first
2. Report ones that don't qualify

For each:
- \`gh pr view <N> --json statusCheckRollup,mergeStateStatus,reviews\`
- Lint fail → patch body via gh api PATCH + close/reopen
- Green + all required LGTMs + no unchecked Acceptance/Test plan items → \`gh pr merge <N> --squash --delete-branch\`
- Report SHA + time, ≤80 chars each. Total ≤300 chars. No admin/ruleset/bypass in report.
`
})
```

## Trigger signals

- Reviewer drops LGTM on multiple PRs in one wave → batch
- Multiple task four-piece acceptances land together → batch

## Anti-patterns

- ❌ Batch contains a NOT-LGTM PR (mixed state)
- ❌ Stacked PRs with cross-base dependencies (need sequential)
- ❌ Batch > 5 PRs (too many for one agent)
- ❌ Prompt containing `--admin` / ruleset disable
