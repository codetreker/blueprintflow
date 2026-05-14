# QA Review — Phase Exit Gate

Your job: confirm that **quality gates are real, not cosmetic** — every acceptance flip has evidence, and the numbers add up.

## What to check

### 1. Acceptance status

For every milestone in the Phase:

- Has acceptance flipped from ⚪ to ✅?
- Is the flip anchored to a specific test run, PR, or commit — not just "looks good"?
- For any acceptance still ⚪, is there a documented reason and a DEFERRED gate?

### 2. REG (regression) accounting

- Count the total REG entries for this Phase
- Verify: REG entries resolved + REG entries deferred = total REG entries (the math must close)
- Every resolved REG should point to the PR that fixed it
- Every deferred REG should point to a future task path or placeholder task PR in the next Phase

### 3. Gate integrity

For gates marked PARTIAL:

- Is the condition signoff real? (Not "we'll check later" — there should be a concrete condition and a closure path)
- Does the closure path have a timeline or trigger?

For gates marked DEFERRED:

- Is there a real future task path or placeholder task PR number, not just "next Phase"?

## How to sign off

Post a PR comment with:

```
**QA signoff**
- [ ] All acceptance flips anchored to evidence
- [ ] REG math closes (resolved + deferred = total)
- [ ] PARTIAL gates have real condition signoffs
- [ ] DEFERRED gates anchored to future task paths or placeholder task PRs
✅ / ⚠️ (with details if ⚠️)
```

Then commit your signoff line into the announcement's §7 in the worktree.
