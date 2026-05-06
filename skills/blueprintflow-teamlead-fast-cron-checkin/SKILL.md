---
name: blueprintflow-teamlead-fast-cron-checkin
description: "Part of the Blueprintflow methodology. Use on 15-min cron tick or when a role goes idle - Teamlead dispatches idle roles, clears stuck PRs, and runs the three-signoff merge gate."
version: 1.1.0
---

# Teamlead fast-cron check-in

The cron is not a status report. It is a forward-motion action. Every check-in must hand out new work to every idle role; otherwise you've failed the job.

## Core rules

### 1. The cron must ACT, not just audit
Every idle role must walk away with new work. Only two exceptions:
- They are waiting on a specific blocker (write down the PR # / dependency).
- Their current in-flight task hasn't been wrapped up yet.

### 2. When "waiting on X" counts as legitimate idle

**Legitimate**: the agent is genuinely in a wait state (continuously listening for task completion / continuously polling PR CI status), not just having said something and stopped.

**Not legitimate**: the agent sent one message and went idle without actually waiting for anything. Kick them with new work.

How to tell: if an agent has had no new output for 5+ minutes, it has most likely just stopped after speaking. Hand it new work. While the merge agent is running, everyone else can work in parallel:
- Dev → start implementing the next milestone (a temporary clone won't conflict with the main worktree)
- Architect → next batch of spec briefs / blueprint patches / reviewing older PRs
- PM → next batch of stance cross-checks / content lock / demo screenshots
- QA → next batch of acceptance templates / REG flips / e2e flake fixes

### 3. Pick-1-of-4 dispatch priority
Look for new work in this order:
- a) **unblock**: there's a concrete blocker holding other people up — fix that first
- b) **follow-up**: an issue exposed by the last merged PR, or a flip that was left as carry-over
- c) **forward**: the next milestone (spec / acceptance / implementation / stance)
- d) **maintenance**: REG audit / docs lint / out-of-date blueprint

### 4. cron output format
- One sentence reporting current forward motion (PR # + one-line goal).
- Hard blockers (PR check failing for too long / review unanswered for too long) listed separately with details.

### 5. When to merge — look at task completion, not just the green CI

**Merge gate** (under the "one milestone, one PR" protocol):

CI green + LGTMs collected ≠ ready to merge. **You must check that the milestone's actual work is done** — every item under Acceptance / Test plan in the PR body is checked off. Only then do you merge.

**What "actually done" means** (by milestone type):

| Milestone type | "Done" criteria |
|---|---|
| Schema + server + client end-to-end | schema migration + server endpoint + client UI + e2e + docs/current sync + REG flipped to green + acceptance template ⚪→✅ + PROGRESS [x] **all in place** |
| Spec / four-piece set | The four-piece set is committed to the worktree by every owner (Architect spec / QA acceptance / PM stance + content-lock), not just one piece |
| Closure / status flip | Lands in the same PR as the implementation, not in a follow-up |

**Read the PR body's Acceptance + Test plan**. Required. Any remaining `[ ]` item = **do not merge**, even with green CI and double LGTM. Send it back to the author / role to commit the missing piece.

**Anti-examples (never do)**:
- "CI is green and we have two LGTMs, just squash" — you didn't check that Acceptance still has 4 unticked items.
- "Almost done, let's merge first and follow up later" — under "one milestone, one PR" there is no room for follow-ups.
- "The review subagent reported LGTM, merge now" — a subagent doesn't check task completion. The Teamlead must read the PR body in person.

**Correct flow**:
1. CI fully green (never admin / ruleset bypass — see `pr-review-flow`).
2. ≥1 non-author LGTM.
3. **Teamlead reads the PR body's Acceptance + Test plan; merge only when every item is ticked.**
4. If any `[ ]` remains → ping the matching role to commit; do not merge.
5. All ticked + steps 1+2 → standard squash merge.

## Default dispatch list (per role)

**Dev**: split N+1 of the current milestone / firefighting bugs exposed by the last PR / schema spike for the next milestone.
**Architect**: review queue / next spec brief / patches to older blueprints.
**PM**: stance cross-check sheet / demo screenshot copy / README / onboarding content lock.
**QA**: acceptance template / REG flip / e2e flake fix.
**Designer**: visual spec / component library / writing the visual lock that pairs with PM's content lock.
**Security**: review of sensitive PRs / privacy stance / audit log review.

## PR BLOCKED routing

When a PR is blocked, **look at the type of block first**, then decide who to assign it to:

| Block type | Assign to | Why |
|---|---|---|
| **rebase / merge conflict** (DIRTY) | **subagent** | Cross-PR work; the author can't see the accumulated conflicts. A subagent batch-handles them quickly. |
| **CI fail** (cov / test / e2e / lint) | **author** | The author understands their own milestone's stance and implementation best. A fresh-context subagent is more likely to break the byte-identical lock chain. |
| **PR body missing a section** (mechanical N/A fillers, etc.) | **subagent** | Pure mechanical work (PATCH the body + empty commit + re-lint). |
| **review pending > 1h** | **ping the reviewer** | Not a block; just nudge the reviewing role. |

> **Note on flaky CI:** if a CI fail is unrelated to this PR's changes (a flaky signal), it doesn't block the PR, but you must open an issue to track it. See `blueprintflow-pr-review-flow`, "Flaky test" section.

**Right examples:**
- 10 PRs hit main and went DIRTY at the same time → batch rebase subagent (resolve in one go).
- 7 PRs are missing the N/A section in PR-lint → subagent mechanically fills + pushes empty commit.
- Author A's PR is at 83.9% cov → assign author A to add unit tests.
- Author B's PR has a test violation → assign author B to fix.

**Wrong examples:**
- See cov fail and dispatch a subagent to add unit tests — the author knows where coverage is low; send it back to the author.
- See a test violation and dispatch a subagent — the author wrote the mock; send it back to the author.
- See a real e2e bug and dispatch a subagent — the author wrote the spec and the implementation; send it back to the author.
- See a merge conflict and dispatch the author — this is cross-PR work; a batch subagent is faster.

## Anti-patterns

- Outputting "everyone is idle waiting on merge" without dispatching any work (even if waiting, the idle ones must be doing something else).
- Using "waiting for review feedback" as an idle excuse (the waiter who isn't in a wait state needs new work).
- Treating audit as forward motion (audit + dispatch is forward motion).
- Assuming "parallel will conflict" and refusing to parallelize (under the new protocol — one milestone, one worktree — multiple milestones run in parallel naturally).
- **"CI is green so merge"** — you must first read the PR body's Acceptance / Test plan and confirm every item is ticked (see §5).
- **"subagent LGTM = merge signal"** — a subagent doesn't audit task completion. The Teamlead reads the PR body in person.
- **CI fail → grab a subagent** — the author knows their own milestone best. Send it back to the author (see "PR BLOCKED routing").
- Treating the review dispatch as the only merge gate — review is a quality check; **task completion + CI + LGTM is the three-way signoff that lets you merge**.

## How to invoke

Set the cron prompt to:
```
[auto check-in · 15 min]
follow skill blueprintflow-teamlead-fast-cron-checkin
```

## Companion

- The slow-paced drift audit goes through `blueprintflow:teamlead-slow-cron-checkin`. The two don't overlap.
