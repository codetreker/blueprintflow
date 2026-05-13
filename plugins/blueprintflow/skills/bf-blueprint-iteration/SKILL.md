---
name: bf-blueprint-iteration
description: "Part of the Blueprintflow methodology. Use when changing a frozen blueprint, routing backlog items, preparing the next blueprint version, or handling post-freeze product-shape drift."
---

# Blueprint Iteration

The blueprint evolves after freeze through a 3-state machine. Stance reversals are never allowed on the current version — they go to `blueprint-next/`.

**When this applies**: first blueprint version frozen, at least one Phase executed. Early brainstorm + first-version write doesn't go through this skill.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

If this skill is invoked without a concrete objective, enter standby: do not inspect GitHub issues, blueprint files, task docs, git history, PRs, or worktrees. State what this skill coordinates and ask which objective to run.

Concrete objectives include:

- Patch current blueprint for `gh#NNN`.
- Triage backlog issues for the next blueprint version.
- Open a next-version draft.
- Review or freeze the next-version draft.
- Cut over next-version to current after approval.

Standby response:

```text
bf-blueprint-iteration loaded. This skill coordinates blueprint changes after freeze: current patches, backlog-to-next selection, next-version drafting, review/freeze, and cutover.
No issues, blueprint files, task docs, PRs, git history, or worktrees have been inspected yet.
Tell me which blueprint iteration objective to coordinate.
```

## 3-state machine

| State | Where | Meaning |
|---|---|---|
| Current | `docs/blueprint/` | Frozen, versioned, every PR anchors here |
| Next-version | `docs/blueprint-next/` | Draft, four roles + user discussing |
| Backlog | GitHub issues (`backlog` label) | Unplanned, accumulates, not in current iteration |

The three states don't mix. Current allows patches (literal / anchor / constraint), **not stance reversals**. Change suggestions enter these states via `bf-issue-triage`.

## Version numbers

Version lives in `docs/blueprint/` frontmatter (`frozen: <date>`, `prev: vN.M-1`).

| Bump | When | Example |
|---|---|---|
| **Major** (vN → v(N+1).0) | Stance reversal / rename / module removal / direction shift | "local-first" → "server-first" |
| **Minor** (vN.M → vN.(M+1)) | New requirements added, no old stance reversed | Module D added; A/B/C unchanged |
| **Patch** (no bump) | Literal / anchor / constraint fix. Just commit | Spec brief anchor +1 line |

**Rule of thumb**: if someone reading vN talks to someone who read v(N-1), will they misunderstand each other? Yes → major. No, just don't know the new thing → minor. Doesn't affect understanding → patch.

## Current-blueprint patch rules

- ✅ Patches allowed — literal / anchor / constraint, no version bump, just commit
- ❌ Stance reversals → must go through `blueprint-next/` and freeze cutover
- Patch / bugfix PRs must link `Closes gh#NNN` (root-cause traceability)
- Too many patches = probably a stance reversal → immediately open `blueprint-next/`

## Iteration lifecycle

When the current iteration passes acceptance, the next-version discussion opens. Its primary input is **GitHub issues labeled `backlog`** — these are scanned one by one to decide what gets pulled into the next blueprint version.

After the user names a concrete iteration objective, read `references/lifecycle.md` for the full flow: scan backlog → write blueprint-next → four-role discussion → freeze + tag + source-issues.md → relabel issues → trigger Phase N+1. Reminder period is project-defined in AGENTS.md (`reminder-period: 2w` default).

## Anti-patterns

- ❌ Version number in AGENTS.md (blueprint owns its frontmatter)
- ❌ Patch PR without `Closes gh#NNN` (root-cause chain breaks)
- ❌ Stuck milestone dragging the whole iteration (kick to backlog or split)
- ❌ Cramming many patches that are actually a stance reversal
- ❌ Opening next-version discussion without scanning `backlog` issues first (cleanup window missed)

## How to invoke

```
follow skill bf-blueprint-iteration

# No objective named → standby, ask which iteration objective to coordinate
# Current iteration done → scan backlog → open blueprint-next
# blueprint-next converges → freeze + tag + source-issues.md
```
