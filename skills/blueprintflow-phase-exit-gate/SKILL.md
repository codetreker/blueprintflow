---
name: blueprintflow-phase-exit-gate
description: "The final gate when wrapping up a Phase. Confirms every milestone in the Phase is finished and gets four roles to sign off before the project moves to the next Phase."
version: 1.0.0
---

# Phase Exit Gate

Phase exit is the last checkpoint when finishing a Phase. You confirm everything that was supposed to happen actually happened, four roles sign off, and only then can the project move into the next Phase.

This is **not** the same as wrapping up a single milestone. A milestone wraps up inside its own PR. Phase exit is one level higher — it closes a whole stretch of work made up of multiple milestones.

## Before starting the exit flow

Make sure these are all in place first:

### 1. PROGRESS.md is honest

Every milestone that's done should be checked off. For anything not checked, confirm one by one: was it actually done and someone forgot to flip the status, or is it really not done? Fix PROGRESS first, then start the exit flow. Don't carry inconsistencies into the gate.

### 2. Machine-checkable gates all green

Every strict check in the Phase (the `G<Phase>.<n>` ones) is SIGNED, anchored to a commit SHA.

### 3. Carry-overs are properly anchored

It's OK if some things in the Phase didn't get fully done — but **every carry-over must be anchored to a placeholder PR number in the next Phase** (rule 6). Vague language like "we'll get to it later" doesn't count. If there's no placeholder PR yet, open one before running the exit flow.

### 4. "Conditionally complete" is fine

You don't have to wait for every gate to be strictly ✅. This combination is acceptable:

- N gates strictly ✅
- M gates PARTIAL (with a condition signoff and a closure path attached)
- K gates DEFERRED (locked to a placeholder PR in the next Phase)

The announcement title says "conditionally complete", not "complete". This is honesty, not slack.

> **Real example (Borgee):** Phase 2 exit was 5 SIGNED + 3 PARTIAL + 2 DEFERRED → "conditionally complete".

## How it works

The whole Phase exit goes through **one** PR — not four separate PRs for the four signoffs (that would conflict with the "one milestone, one PR" rule). All four roles commit and review inside the same worktree, just like a regular milestone PR.

worktree: `.worktrees/phase-N-exit/`. branch: `docs/phase-N-exit`.

### Step 1: Architect drafts

The Architect writes two documents in the worktree and commits them together:

- `docs/qa/phase-N-readiness-review.md` (≤100 lines) — "Is the Phase ready to exit?"
  - Status of each gate: SIGNED / PARTIAL / DEFERRED, with PR anchors
  - Final call: ✅ ready or ⚠️ still has blockers
  - Prerequisites for the next Phase, plus any handoff points

- `docs/qa/phase-N-exit-announcement.md` (≤80 lines) — the closure announcement
  - §1 Three sections (SIGNED / PARTIAL / DEFERRED) listing what's in each
  - §2-§5 Each gate, anchored to PR # / commit SHA + acceptance template
  - §7 Four signoff slots (placeholder, waiting for the four roles)
  - §8 Changelog v1.0

### Step 2: Four-role review and signoff

Reviews go through PR comments — same pattern as a milestone PR. No new branches, no new PRs.

- **Architect**: LGTM their own readiness review in the PR comments
- **QA**: Verify acceptance is fully flipped, REG counts add up, anchored to acceptance templates
- **PM**: Verify product rules haven't drifted, scope boundaries held, anchored to the rules cross-check table
- **Teamlead**: Final signoff (coordination + confirmation that all four pieces are in place)

After approving, each role **commits a single line into the announcement's §7** (their role / ✅ / date / PR anchor) directly in the same worktree. No separate branch, no separate PR.

### Step 3: Placeholder PRs land first

If any DEFERRED gate is anchored to a placeholder PR in the next Phase, those placeholder PRs must be merged before merging the Phase exit PR. Otherwise the announcement references PRs that don't exist yet, and the anchors are broken.

### Step 4: Announcement closes + next Phase starts

Once all four roles have signed and all placeholder PRs are merged, the Architect commits one more section into the same PR — §9 Closure Announcement:

- Date
- Carry-over details (where each DEFERRED gate is anchored)
- Signal that the next Phase is unblocked

Then the Teamlead squash merges the whole PR, removes the worktree, and deletes the branch.

PR title: `docs(qa): Phase N closure announcement`

## Anti-patterns

- ❌ Vague language for DEFERRED gates ("same PR" or "later") instead of a real PR number
- ❌ Forcing every gate to be strictly ✅ before allowing exit, dragging the Phase forever — "conditionally complete" is honest, not slack
- ❌ Four separate PRs, one per role signoff — conflicts with "one milestone, one PR"; Phase exit is one event, one PR
- ❌ Merging the Phase exit PR before placeholder PRs land (anchored PRs don't exist, broken references)
- ❌ Splitting the announcement into v1 / v2 across two PRs (same root cause as the "four PRs" anti-pattern: one event, fragmented commits)

## How to invoke

When the Phase enters its wrap-up window (all strict gates ✅, carry-overs anchored to placeholder PRs):

```
follow skill blueprintflow-phase-exit-gate
Architect drafts readiness review + announcement →
four roles review in PR comments and commit their signoff lines →
all placeholder PRs merge →
Architect commits §9 closure →
Teamlead squash merges
```
