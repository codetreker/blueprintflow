---
name: bf-phase-exit-gate
description: "Part of the Blueprintflow methodology. Use when all milestone PRs in a Phase are merged, acceptance is complete, and Phase-level closure/signoff is needed."
---

# Phase Exit Gate

Phase exit = last checkpoint when finishing a Phase. Confirm everything planned actually shipped, four roles sign off, then move to next Phase.

**Not** the same as closing a single milestone (that happens in its own PR). Phase exit is one level higher — closes a whole stretch of milestones.

## Phase exit vs wave closure

| | Phase exit (this skill) | Wave closure |
|---|---|---|
| **When** | All milestones merged + acceptance ✅, next blueprint version ready | A milestone wave inside a Phase finishes |
| **Scope** | Transitions between Phases / blueprint versions | Wave's closure milestone handles its own signoff |
| **Governed by** | This skill | `bf-phase-plan` |

## Prerequisites

All must be true before starting the exit flow:

| Check | Requirement |
|---|---|
| PROGRESS.md | Every done milestone checked off. Confirm unchecked items one by one — fix before starting |
| Machine-checkable gates | Every `G<Phase>.<n>` is SIGNED, anchored to commit SHA |
| Carry-overs | Each carry-over anchored to a **placeholder PR number** in next Phase. "We'll get to it later" ≠ anchored |
| Conditionally complete | Acceptable: N gates SIGNED + M gates PARTIAL (condition + closure path) + K gates DEFERRED (locked to placeholder PR). Announcement says "conditionally complete", not "complete" |

## Flow

One PR, one worktree (`.worktrees/phase-N-exit/`, branch `docs/phase-N-exit`). Not four separate PRs.

### Step 1: Architect drafts

Two documents, committed together:

| Document | Content | Limit |
|---|---|---|
| `docs/tasks/phase-N-exit/readiness-review.md` | Gate status (SIGNED/PARTIAL/DEFERRED) with PR anchors, final call, next-Phase prerequisites | ≤100 lines |
| `docs/tasks/phase-N-exit/announcement.md` | §1 three-bucket summary, §2-§5 per-gate with PR/SHA anchors, §7 four signoff slots, §8 changelog | ≤80 lines |

### Step 2: Four-role review + signoff

| Role | Review focus |
|---|---|
| Dev | Implementation coverage — acceptance criteria maps to merged code, no gaps |
| QA | Acceptance fully flipped, REG counts add up, anchored to templates |
| PM | Product rules haven't drifted, scope boundaries held |
| Teamlead | Final signoff — all four pieces in place |

Each role commits one line into §7 (role / ✅ / date / PR anchor) in the same worktree. No separate branch or PR.

> **Detailed checklists**: see `references/dev-review.md`, `references/qa-review.md`, `references/pm-review.md`, `references/teamlead-review.md` for per-role signoff checklists. Only read your own role's file.

### Step 3: Placeholder PRs land first

DEFERRED gates' placeholder PRs must merge before the exit PR. Otherwise anchors are broken.

### Step 4: Closure + next Phase

Architect commits §9 (date, carry-over details, next Phase unblocked). Teamlead squash merges. PR title: `docs(qa): Phase N closure announcement`.

## Archiving closed milestones

After a milestone's PR merges and acceptance is ✅:
- `git mv docs/tasks/<milestone-or-issue> docs/tasks/archived/<milestone-or-issue>` (in closure PR or chore PR within 24h)
- Update `docs/tasks/README.md` — remove from "Currently in flight"

## Anti-patterns

- ❌ Vague DEFERRED anchors ("same PR" / "later") instead of real PR numbers
- ❌ Forcing every gate to strict ✅, dragging the Phase forever
- ❌ Four separate PRs for four signoffs (one event = one PR)
- ❌ Merging exit PR before placeholder PRs land
- ❌ Splitting announcement across multiple PRs

## How to invoke

```
follow skill bf-phase-exit-gate
```
