# Review Subagent Parallel Mode

Spawn fresh review subagents instead of pinging persistent roles — no interruption, clean context, parallelizable. **Measured: 8x speedup** (1 min parallel vs 6-10 min series).

## Template

```
Agent({
 description: "Parallel <lens> review #<N>",
 subagent_type: "general-purpose",
 run_in_background: true,
 prompt: `
You are a temporary reviewer (subagent, fresh context) on codetreker/<repo>.

Task: review PR #<N> <title> (<author>).
Lens: <architecture | stance + content lock | acceptance + reverse-grep anchors>.

## Anchors
1. \`gh pr view <N>\` — body + diff
2. \`gh pr diff <N>\` — actual change
3. <spec / content lock / acceptance / cross-ref PRs>

## Checklist
- [ ] Section breakdown 1:1 with spec brief
- [ ] Counts add up
- [ ] Byte-identical anchors to sources (PR # / SHA)
- [ ] Anti-constraint grep (list pattern)

## Output
- Pass: \`gh pr comment <N> --body "LGTM (<lens>). [summary]"\`
- NOT-LGTM: don't comment; report issues + quotes + fixes. ≤200 words.
`
})
```

## Scope

| Applies | Doesn't apply |
|---|---|
| Routine four-piece review (byte-identical / grep / 1:1) | Architectural judgment / drift arbitration |
| Acceptance / stance / content lock review | Spec brief authorship (creative work) |
| Count math / REG flip | NOT-LGTM arbitration (escalate to persistent) |

## Protocol

1. PR open → dispatch N review subagents (parallel)
2. All LGTM + CI passes → standard merge (never admin-bypass)
3. NOT-LGTM or cross-PR drift → escalate to persistent role
4. Persistent roles keep: authoring + drift arbitration + cross-milestone judgment

## Anti-patterns

- ❌ Subagent replacing persistent-role authoring (read-only, doesn't write spec/content-lock)
- ❌ NOT-LGTM arbitrated by subagent (escalate to persistent)
- ❌ Prompt missing cross-ref PR # / SHA (loses byte-identical verification)
