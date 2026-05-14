---
name: bf-phase-exit-gate
description: "Part of the Blueprintflow methodology. Use when all task PRs in a Phase are merged, milestone acceptance is complete, and Phase-level closure/signoff is needed."
---

# Phase Exit Gate

Phase exit = last checkpoint when finishing a Phase. Confirm everything planned actually shipped, four roles sign off, then the accepted scope can promote toward `docs/blueprint/current/`.

**Not** the same as closing a single task (that happens in its own PR) or milestone (that happens when its tasks are accepted). Phase exit is one level higher — closes a whole stretch of milestones.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Phase exit vs wave closure

| | Phase exit (this skill) | Wave closure |
|---|---|---|
| **When** | All milestone tasks merged + acceptance ✅, current promotion ready | A milestone wave inside a Phase finishes |
| **Scope** | Accepted Phase scope can promote to current | Wave's closure task/gate handles its own signoff |
| **Governed by** | This skill | `bf-milestone-progress` |

## Prerequisites

All must be true before starting the exit flow:

| Check | Requirement |
|---|---|
| `progress.md` + `milestone.md` | Every done task and milestone checked off. Confirm unchecked items one by one — fix before starting |
| Machine-checkable gates | Every `G<Phase>.<n>` is SIGNED, anchored to commit SHA |
| Carry-overs | Each carry-over anchored to a future task path or placeholder PR number in next Phase. "We'll get to it later" ≠ anchored |
| Conditionally complete | Acceptable: N gates SIGNED + M gates PARTIAL (condition + closure path) + K gates DEFERRED (locked to future task path or placeholder task PR). Announcement says "conditionally complete", not "complete" |

## Flow

Phase exit is a normal task PR, usually `task-phase-exit`, under the Phase's final milestone. One task PR, one worktree (`.worktrees/task-phase-exit/`, branch `feat/task-phase-exit`). Not four separate PRs.

### Step 1: Architect drafts

Two documents, committed together:

| Document | Content | Limit |
|---|---|---|
| `docs/tasks/phase-N-<name>/milestone-phase-exit/task-phase-exit/readiness-review.md` | Gate status (SIGNED/PARTIAL/DEFERRED) with PR anchors, final call, next-Phase prerequisites | ≤100 lines |
| `docs/tasks/phase-N-<name>/milestone-phase-exit/task-phase-exit/announcement.md` | §1 three-bucket summary, §2-§5 per-gate with PR/SHA anchors, §7 four signoff slots, §8 changelog | ≤80 lines |

### Step 2: Four-role review + signoff

| Role | Review focus |
|---|---|
| Dev | Implementation coverage — acceptance criteria maps to merged code, no gaps |
| QA | Acceptance fully flipped, REG counts add up, anchored to templates |
| PM | Product rules haven't drifted, scope boundaries held |
| Teamlead | Final signoff — all four pieces in place |

Each role commits one line into §7 (role / ✅ / date / PR anchor) in the same worktree. No separate branch or PR.

> **Detailed checklists**: see `references/dev-review.md`, `references/qa-review.md`, `references/pm-review.md`, `references/teamlead-review.md` for per-role signoff checklists. Only read your own role's file.

### Step 3: Deferred anchors exist first

DEFERRED gates' future task paths or placeholder task PRs must exist before the exit PR merges. Otherwise anchors are broken.

### Step 4: Closure + next Phase

Architect commits §9 (date, carry-over details, next Phase unblocked). Teamlead runs `bf-pr-review-flow`; merge only after green CI, required non-author reviews, and no unchecked Acceptance/Test plan items. PR title: `docs(qa): Phase N closure announcement`.

## Archiving closed tasks and milestones

After `bf-milestone-progress` reconciles accepted-task state:
- Move task folders to `docs/tasks/archived/` only when the active milestone/phase resume view no longer needs them inline.
- Confirm closed rows are already absent from Active Task Resume. Do not remove them in this skill.

## Anti-patterns

- ❌ Vague DEFERRED anchors ("same PR" / "later") instead of future task paths or real PR numbers
- ❌ Forcing every gate to strict ✅, dragging the Phase forever
- ❌ Four separate PRs for four signoffs (one event = one PR)
- ❌ Merging exit PR before deferred anchors exist
- ❌ Splitting announcement across multiple PRs

## How to invoke

```
follow skill bf-phase-exit-gate
```
