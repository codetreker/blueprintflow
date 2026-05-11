---
name: blueprintflow-blueprint-iteration
description: "Part of the Blueprintflow methodology. Use when the blueprint is already frozen and a change suggestion arrives - routes it through the 3-state machine (current / next / backlog) to evolve safely."
---

# Blueprint Iteration

The blueprint evolves after freeze through a 3-state machine. Stance reversals are never allowed on the current version — they go to `blueprint-next/`.

**When this applies**: first blueprint version frozen, at least one Phase executed. Early brainstorm + first-version write doesn't go through this skill.

## 3-state machine

| State | Where | Meaning |
|---|---|---|
| Current | `docs/blueprint/` | Frozen, versioned, every PR anchors here |
| Next-version | `docs/blueprint-next/` | Draft, four roles + user discussing |
| Backlog | GitHub issues (`backlog` label) | Unplanned, accumulates, not in current iteration |

The three states don't mix. Current allows patches (literal / anchor / constraint), **not stance reversals**.

## Backlog

GitHub issues are the backlog SSOT. Tag system (native types + status labels + priority), routing rules, and issue body requirements are defined in `blueprintflow-issue-triage` (read its `references/execution.md` for the full spec).

## Change routing

Change arrives → route per `blueprintflow-issue-triage`. Default is backlog (burden of proof sits on "this is a bug").

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

Read `references/lifecycle.md` for the full flow: current iteration passes acceptance → user opens next-version discussion → scan backlog → write blueprint-next → four-role discussion → freeze + tag + source-issues.md → relabel issues → trigger Phase N+1.

## AGENTS.md config

```yaml
blueprint-iteration:
  reminder-period: 2w  # how often to remind user when they haven't responded
```

Project-defined, not hardcoded. Version numbers live in blueprint frontmatter, not here.

## Anti-patterns

- ❌ Reversing a stance on the current blueprint (PR anchors drift)
- ❌ Opening next-version discussion without scanning `backlog` issues
- ❌ Version number in AGENTS.md (blueprint owns its frontmatter)
- ❌ Backlog in repo docs instead of GitHub issues (anti-fork-friendly)
- ❌ Auto-cleaning backlog (cleanup during human discussion only)
- ❌ Backlog issue body = title only, no "why it goes here"
- ❌ Patch PR without `Closes gh#NNN` (root-cause chain breaks)
- ❌ Stuck milestone dragging the whole iteration (kick to backlog or split)
- ❌ Treating "new stance" as "bug" (burden of proof inverted)
- ❌ Cramming many patches that are actually a stance reversal

## How to invoke

```
follow skill blueprintflow-blueprint-iteration

# Change suggestion → Architect decides bug/not-bug → route
# Current iteration done → scan backlog → open blueprint-next
# blueprint-next converges → freeze + tag + source-issues.md
```
