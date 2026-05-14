# Teamlead Review — Phase Exit Gate

Your job: confirm that **the exit process itself is complete and correct** — all roles have signed, all anchors resolve, and the project is genuinely ready to move on.

## What to check

### 1. All signoffs collected

- Dev signoff: ✅ posted and committed to §7?
- QA signoff: ✅ posted and committed to §7?
- PM signoff: ✅ posted and committed to §7?
- If any role flagged ⚠️, have the concerns been resolved or acknowledged?

### 2. Anchor integrity

- Every PR number referenced in the announcement actually exists; merged-work PRs are merged, and deferred anchors point to a future task path or real placeholder task PR for the next Phase
- Every commit SHA referenced is reachable from main
- No broken links, no "TBD" placeholders left

### 3. Deferred anchors exist

- All DEFERRED gates have future task paths or placeholder task PRs before you merge the exit PR
- The exit announcement's carry-over section accurately reflects what's deferred and where

### 4. Next Phase readiness

- Prerequisites for the next Phase (from the readiness review) are met
- No unresolved blockers that would immediately stall Phase N+1
- The "unblocked" signal in §9 is honest

## How to sign off

After confirming all of the above, run `bf-pr-review-flow` and merge only when its task-PR gates pass:

1. Verify all four signoff lines are in the announcement §7
2. Verify §9 (closure announcement) is committed by the Architect
3. Verify green CI, required non-author reviews, and no unchecked Acceptance/Test plan items
4. Squash merge the PR
5. Remove the worktree, delete the branch
6. Announce in the project channel that the Phase is closed
