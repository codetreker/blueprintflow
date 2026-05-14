# Dev Review — Phase Exit Gate

Your job: confirm that **everything the Phase promised was actually built and shipped**.

## What to check

### 1. Milestone and task coverage

Go through every milestone in the Phase. For each one:

- Are all required task PRs merged?
- Does the merged code match what the milestone and task specs described?
- Are there any acceptance criteria in the spec that don't have corresponding implementation?

If something was descoped mid-Phase, verify there's a written record (PR comment, blueprint iteration, or DEFERRED gate) — not just a verbal "we decided to skip it".

### 2. Implementation gaps

Look for things that were supposed to land but didn't:

- Features mentioned in the blueprint but missing from the code
- Edge cases called out in the spec that have no test coverage
- TODOs or FIXMEs left in the code that should have been resolved in this Phase

### 3. Technical debt anchoring

If the Phase created known technical debt (shortcuts taken to meet deadlines, hardcoded values, missing error handling), verify it's captured in a future task path or placeholder task PR for the next Phase. Undocumented debt is invisible debt.

## How to sign off

Post a PR comment with:

```
**Dev signoff**
- [ ] Every required task PR merged and matches spec
- [ ] No unanchored implementation gaps
- [ ] Technical debt captured in future task paths or placeholder task PRs
✅ / ⚠️ (with details if ⚠️)
```

Then commit your signoff line into the announcement's §7 in the worktree.
