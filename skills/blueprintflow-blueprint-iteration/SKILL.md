---
name: blueprintflow-blueprint-iteration
description: "Rules for evolving the blueprint after the first version is frozen — 3-state machine, version numbers, change routing, freeze and version cut. Use this skill whenever the current iteration has passed acceptance and the next-version discussion is opening, a change suggestion comes in and someone needs to decide bug vs not-bug, or blueprint-next has converged and is ready to freeze. Don't use when drafting the first version of the blueprint (use blueprint-write), when splitting a milestone during execution, or for a literal typo on the current blueprint (just commit)."
version: 1.0.0
---

# Blueprint Iteration

The blueprint isn't frozen once and never touched again, but you also can't reverse a stance directly on the current version. This skill defines how the blueprint evolves after it's been written down: a 3-state machine, version numbers, and how change suggestions are routed.

When this applies: the first version of the blueprint is already frozen and at least one Phase has been executed. The early brainstorm + first-version blueprint-write stage doesn't go through this skill.

## 3-state machine

| State | Where it lives | Meaning |
|-------|----------------|---------|
| Current blueprint | `docs/blueprint/` (in repo) | Frozen, carries a version number, every execution PR anchors here |
| Next-version blueprint | `docs/blueprint-next/` (in repo) | Draft state, four roles + Teamlead/user discussing |
| Backlog | **GitHub issues** (label `backlog`) | Unplanned, accumulates over time, not in the current iteration |

The three states are independent and don't mix. The current blueprint allows patches (literal / anchor / constraint), but **stance reversals are not allowed** — those go to `blueprint-next/`.

> **Why the backlog lives in GitHub issues:**
> - **Fork-friendly**: GitHub issues stay with the origin repo and don't pollute forks. A fork gets a clean blueprint plus implementation code; upstream internal discussion (noise / sensitive material) stays at origin.
> - **Native collaboration**: comments / labels / assignees / linked PRs are all GitHub-native, no need to reinvent.
> - **Searchable / linkable**: PRs use `Closes gh#NNN` to link directly to the root cause, instead of hand-written cross references.

## Backlog: GitHub issues as SSOT

The backlog's source of truth is GitHub issues, marked with the `backlog` label.

### Tag system (3 dimensions)

Each issue must carry at least one type label and one status label. Priority labels are project-optional.

**Type** (required, pick one):
- `type:bug` — current blueprint says X but execution drifted / blueprint typo / constraint anchor missing
- `type:feature` — new stance / new module / new requirement
- `type:question` — unsure whether bug or feature, needs Architect / Teamlead to call
- `type:tech-debt` — technical debt accrued during execution (refactor / test coverage / docs lagging)

**Status** (required, pick one):
- `backlog` — unplanned, waiting for the next-version discussion to pick it up
- `current-iteration` — pulled into the current iteration (bugfix / patch milestone)
- `next-iteration` — pulled into the next-version blueprint (blueprint-next stage)
- `archived` — kept for history, not handled (context value)
- `wont-fix` — evaluated and decided not to do, closed

**Priority (project-optional)**:
- `p0-blocker` / `p1-high` / `p2-normal` / `p3-low`

### Issue routing rules

New issues come in through **the entry-point triage**, which is `blueprintflow-issue-triage` (cron scan + Teamlead first call + Architect/PM/QA role classification + `triaged` label). This skill governs the **state-machine routing after triage**:

```
issue triaged (label applied) → state-machine routing:
  ├── type:bug + covered by current blueprint → label `current-iteration` + assign patch / bugfix milestone
  ├── type:feature / type:tech-debt → label `backlog`, wait for next version
  └── type:question → escalate to Teamlead + user calls

Next-version discussion opens → scan all `backlog` issues (review one by one):
  ├── Pulled in → move label from `backlog` → `next-iteration`
  ├── Rejected → label `wont-fix` + close
  └── Kept → keep `backlog` (but update issue body with "why still kept")
```

### Required fields in a backlog issue body

Every backlog issue body must contain (against "the title alone isn't enough"):

- **Source**: who proposed it / which PR # triggered it / which discussion
- **Why it goes here**: the real reason it isn't a bug — new stance / new module / low priority / not yet sure
- **Out of scope**: the boundary against the current iteration (so it doesn't get mistakenly stuffed back in)

### Constraints

- Every issue dropped into the backlog must explain "why it goes here"; the body can't be just a title
- **No automatic cleanup**, but **manually scan all `backlog` issues** every time a next-version discussion opens (miss this window and the backlog piles up)
- A bugfix issue must link to the current iteration's patch / bugfix milestone (issue and PR are bidirectionally traceable)

## Version numbers (the blueprint carries them, not AGENTS.md)

The blueprint version number lives in the frontmatter under `docs/blueprint/`:

```yaml
---
version: vN.M.0
frozen: <YYYY-MM-DD>
prev: vN.M-1
---
```

### Major bump (vN.M → v(N+1).0)

Stance reversal / rename / module removal / direction shift.

Example: original blueprint was "local-first, no server" → changed to "server-first with local cache".

### Minor bump (vN.M → vN.(M+1))

A batch of new requirements added without reversing any old stance.

Example: original blueprint had modules A/B/C; module D is added; A/B/C don't change.

### Patch (no version number)

Literal / anchor / constraint patches. Just commit. No upper limit, no version bump.

Example: spec brief grep anchor adds one line / a constraint gains another sentence / typo / §X.Y reference fix-up.

### Rule of thumb (Architect's one-liner)

> If someone reading this version of the blueprint talks to someone who read v(N-1), will they **misunderstand each other**?
>
> - Yes → **major** (stances conflict, communication collides)
> - No, they just don't know about the new thing → **minor** (additive, the old still holds)
> - Doesn't affect understanding → **patch** (filling gaps, no version bump)

## Change-routing decision (Architect's one-liner)

For every change suggestion (issue / PR comment / user request), the Architect decides first:

- **Real bug** (current blueprint says X but execution drifted / blueprint typo / constraint anchor missing) → goes into the **current iteration** as a patch or bugfix milestone, issue labeled `current-iteration` + `type:bug`
- **Not a bug** (new stance / new module / stance reversal) → goes into the **backlog**, issue labeled `backlog` + `type:feature` or `type:tech-debt`
- Unsure → label `type:question` + escalate to Teamlead

**Default is backlog.** The burden of proof sits on "this is a bug", to push back against "stuff everything into the current iteration" and stall execution.

## Current-blueprint patch rules

- ✅ Patches allowed — literal / anchor fix-ups / constraints / typos, no version bump, just commit, no upper limit
- ❌ Stance reversals not allowed — must go through `blueprint-next/` and be cut over at freeze time

Failure case: you've written so many patches you realize this is actually a stance reversal → immediately pull a `blueprint-next/` and back out the patches.

### Patch / bugfix milestone PRs must link the root cause

Patch / bugfix milestone PR bodies use GitHub's `Closes gh#NNN` syntax to link the originating issue:

```
## Summary
Fix §X.Y stance drift (root cause reported in the issue)

Closes gh#NNN
```

Effects:
- The issue closes automatically when merged
- The blueprint iteration's root cause stays traceable (PR ↔ issue bidirectional link)
- After a backlog issue moves to `current-iteration` and the work lands, the loop is closed and recorded

## Backlog scan (when the next-version discussion opens)

`gh issue list -l backlog --limit 1000` pulls every backlog issue. Go through them one by one:

- Pulled in → change label to `next-iteration`, remove `backlog`
- Rejected → add `wont-fix`, close
- Kept → keep `backlog`, but update the issue body with "why still kept"

This is the moment for backlog cleanup; miss it and it piles up.

## Iteration lifecycle

```
Current iteration passes acceptance
   ↓
Teamlead reminds the user "next-version discussion can open"
   ↓
User doesn't respond → AGENTS.md reminder-period repeats the reminder
   ↓
User says go
   ↓
Scan GitHub issues with label `backlog` (clean up + pick, move to `next-iteration`) + brainstorm
   ↓
Write docs/blueprint-next/ + migration analysis
   ↓
Four roles + Teamlead/user discuss
   ↓
User signs off (or user authorizes Teamlead to sign off)
   ↓
Freeze:
  - blueprint-next/ → blueprint/ replacement
  - Old version gets a git tag (blueprint-vN.M) for history
  - Write docs/blueprint/<version>/source-issues.md (link issue # that were pulled in; don't list those that weren't; forks can trace back)
  - Issues pulled in change label from `next-iteration` to `current-iteration`, then get assigned milestones for execution
  - Issues kept at `backlog` are untouched (still pending)
  - Create an empty blueprint-next/ to open the entry point for the next-version discussion
```

### source-issues.md trail

At freeze time, list the picked-in issue # in `docs/blueprint/<version>/source-issues.md`:

```markdown
# Source issues for blueprint vN.M

The issues this version of the blueprint draws from (grouped by topic):

## Module X
- gh#123 — title, one sentence on what this version delivers
- gh#125 — title, one sentence on what this version delivers

## Module Y
- gh#127 — ...
```

Effects:
- Fork users can trace where this version of the blueprint came from (even if the fork can't see upstream issue history, they can see the original numbers and look them up upstream)
- Issues that weren't picked aren't listed (noise — leave them in the GitHub backlog)
- Frozen together with the blueprint version, immutable

### Stuck-milestone safety net

If a single milestone is stuck for ≥2 weeks → Architect + PM evaluate, kick it back to backlog or split it; don't drag the whole iteration.

## AGENTS.md config (project-defined, not in the blueprint)

```yaml
blueprint-iteration:
  reminder-period: 2w  # how often to remind the user when they haven't responded
```

`reminder-period` is project-defined (e.g. 2w / 1m), not hardcoded. Version-number rules are **not written here** — they live in the blueprint frontmatter.

## Anti-patterns

- ❌ Reversing a stance directly on the current blueprint (execution PR anchors drift, history gets polluted)
- ❌ Opening the next-version discussion without scanning GitHub `backlog` issues (cleanup window missed, backlog grows)
- ❌ Writing the version number in AGENTS.md (the blueprint owns its frontmatter, same source of truth)
- ❌ Keeping the backlog in repo docs instead of GitHub issues (anti-fork-friendly, upstream noise follows the fork)
- ❌ Auto-cleaning backlog issues (cleanup happens during human discussion, against "accidentally deleting a real user need")
- ❌ Backlog issue body has only a title, no "why it goes here" (later scans can't judge it)
- ❌ Patch / bugfix milestone PR doesn't link `Closes gh#NNN` (root-cause chain breaks)
- ❌ A single stuck milestone drags the whole iteration (kick it back to a backlog issue or split it; don't lock up)
- ❌ Treating "a new stance" as "a bug" and stuffing it into the current iteration (burden of proof inverted, execution stalls)
- ❌ Writing many patches, realizing it's a stance reversal, and still cramming into the current version (immediately open next, don't cram)

## How to invoke

After the first blueprint version is frozen and at least one Phase has been executed:

```
follow skill blueprintflow-blueprint-iteration

# Scenario 1: change suggestion comes in (issue / PR comment / user)
Architect decides bug / not-bug → label issue + current-iteration patch / backlog

# Scenario 2: current iteration passes acceptance
Teamlead reminds user → user says go → scan GitHub `backlog` issues + open blueprint-next/

# Scenario 3: blueprint-next/ discussion converges
Four roles + user sign off → freeze + tag + write source-issues.md + relabel current-iteration
```
