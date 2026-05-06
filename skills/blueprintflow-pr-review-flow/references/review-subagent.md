# Review Subagent Parallel Mode

### Review subagent parallel mode (acceleration — recommended)

Instead of pinging persistent roles (Architect/QA/PM), spawn fresh review subagents. Three benefits:

1. **No interruption**: persistent roles keep working on what they were doing (writing spec / acceptance / content lock) without context-switching to review
2. **Clean context**: the subagent only reads the PR + spec + a few cross-ref anchors, no inbox noise
3. **Parallelizable**: dispatch N subagents at once (architecture + stance + content lock, one each), get multiple LGTMs in one wave

**Measured**: review subagents in parallel (architecture + stance, one each) take about 1 minute total, vs persistent roles in series taking 6-10min. **8x speedup**.

#### Dispatching a review subagent — template

```
Agent({
 description: "Parallel <lens> review #<N>",
 subagent_type: "general-purpose",
 run_in_background: true,
 prompt: `
You are a temporary reviewer (subagent, fresh context, not a persistent role) on the codetreker/<repo> project.

Task: review **PR #<N> <title>** (<author> author).
Lens: **<architecture | stance + content lock | acceptance + reverse-grep anchors>**.

## Required anchors
1. \`gh pr view <N>\` — PR body + diff
2. \`gh pr diff <N>\` — see the actual change
3. <spec brief / content lock / acceptance template / existing cross-ref PRs>
4. (optional) Existing LGTM comments on the PR — angles already covered, don't repeat

## Review checklist (machine-checkable)
- [ ] Section breakdown lines up 1:1 with the spec brief
- [ ] Counts add up (e.g. 26 items = 5+7+7+7)
- [ ] Byte-identical anchors aligned to N sources (list specific PR # / commit SHA)
- [ ] Anti-constraint grep N-line strong-typed (list specific grep pattern)

## Output
- All pass: \`gh pr comment <N> --body "LGTM (<lens> review subagent). [one-line summary of checks]"\` — land it on GitHub
- NOT-LGTM: don't comment; report back specific issues + quotes + suggested fixes.

Report ≤200 words.
`
})
```

#### When it applies vs when it doesn't

| Applies | Doesn't apply |
|---|---|
| Routine four-piece review (byte-identical / anti-constraint grep / 1:1 breakdown) | Architectural judgment / drift arbitration (e.g. "is envelope going from 9 to 10 fields drift?") |
| Acceptance template / stance / content lock review | Spec brief authorship (creative work) |
| Count math reconciliation / REG flip | NOT-LGTM arbitration (escalate to persistent role) |

#### Hybrid protocol

1. PR open → dispatch review subagents (N angles in parallel) for machine-checkable verification
2. All LGTM + CI really passes → standard merge (see Merge section below — **never admin/ruleset bypass**)
3. NOT-LGTM or suspected cross-PR drift → escalate to persistent role for arbitration
4. Persistent roles keep: spec brief / stance / acceptance / content lock authorship + drift arbitration + cross-milestone judgment

#### Anti-patterns

- ❌ Subagent review replacing persistent-role authoring (subagent is read-only, doesn't write spec brief / content lock)
- ❌ NOT-LGTM arbitrated by the subagent itself (escalate to persistent)
- ❌ Subagent prompt missing specific cross-ref PR # / commit SHA (review loses byte-identical verification)
