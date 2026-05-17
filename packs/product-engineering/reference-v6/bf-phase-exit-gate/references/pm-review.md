# PM Review — Phase Exit Gate

Your job: confirm that **the product stayed true to its rules** — scope didn't quietly expand or contract, and the boundaries defined in the blueprint held.

## What to check

### 1. Product rules cross-check

Pull up the blueprint's rules section (the "what we will NOT do" and "what we insist on" lists). For each rule:

- Was the rule respected throughout the Phase?
- If any rule was bent or broken, is there a documented decision (blueprint iteration, PR discussion) explaining why?
- Rules that were explicitly changed via blueprint iteration are fine — rules that were silently ignored are not

### 2. Scope boundaries

Compare what the Phase planned to deliver (from the phase plan) with what actually shipped:

- Were features added that weren't in the plan? If so, was there a decision trail?
- Were features cut? If so, are they captured as DEFERRED gates with future task paths or placeholder task PRs?
- Did the product's positioning shift during the Phase? If so, does the blueprint reflect the new position?

### 3. User-facing promises

If the Phase had external-facing deliverables (documentation, API contracts, UI changes):

- Do they match what was promised?
- Are there any inconsistencies between what the code does and what the docs say?

## How to sign off

Post a PR comment with:

```
**PM signoff**
- [ ] Product rules held or changes documented
- [ ] Scope matches plan (additions/cuts have decision trail)
- [ ] User-facing deliverables match promises
✅ / ⚠️ (with details if ⚠️)
```

Then commit your signoff line into the announcement's §7 in the worktree.
