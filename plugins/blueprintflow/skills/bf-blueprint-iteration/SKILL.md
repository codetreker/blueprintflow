---
name: bf-blueprint-iteration
description: "Part of the Blueprintflow methodology. Use when selecting backlog issues for the next blueprint, locking next-blueprint scope, resuming blueprint discussion, or promoting accepted work into current."
---

# Blueprint Iteration

Blueprintflow separates implemented truth, planned work, execution path, and issue intake. Do not treat blueprint lock as implementation acceptance.

**When this applies**: a project already has an implemented-and-accepted `docs/blueprint/current/`, and the team is selecting or advancing the next body of work. Early brainstorm + first-version write doesn't go through this skill.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

If this skill is invoked without a concrete objective, enter standby: do not inspect GitHub issues, blueprint files, task docs, git history, PRs, or worktrees. State what this skill coordinates and ask which objective to run.

Concrete objectives include:

- Patch current blueprint for an accepted implementation fact.
- Select GitHub `backlog` issues for the next blueprint discussion.
- Open or resume `docs/blueprint/next/` with status anchors.
- Lock selected next-blueprint anchors for execution.
- Promote accepted next work into current after coding and acceptance are complete.
- Repair or review blueprint/task state before resuming interrupted execution.

Standby response:

```text
bf-blueprint-iteration loaded. This skill coordinates implemented-current patches, backlog-to-next selection, next status tracking, next-scope locking, and accepted-work promotion into current.
No issues, blueprint files, task docs, PRs, git history, or worktrees have been inspected yet.
Tell me which blueprint iteration objective to coordinate.
```

## Blueprint state model

| State | Where | Meaning |
|---|---|---|
| Current | `docs/blueprint/current/` | Implemented, coding complete, accepted, and user-verifiable |
| Next | `docs/blueprint/next/` | Locked or in-discussion blueprint work that is not yet accepted into current |
| Tasks | `docs/tasks/` | The execution path from next to current: Phase -> Milestone plan, reviewed task skeletons, task execution, milestone progress |
| Backlog intake | GitHub issues with `backlog` label | Input scanned only when opening a next selection round |

The states do not mix. `current` is never a plan. `next` is where not-yet-accepted blueprint work lives. `tasks` records how locked `next` anchors become accepted `current` behavior. GitHub backlog issues are intake records, not the ongoing workflow state after selection. Cross-version metadata and traceability files live in `docs/blueprint/_meta/`.

## Next status ledger

`docs/blueprint/next/README.md` is the coarse resume index for next-blueprint anchors. It tracks stable anchors from next-blueprint files with two independent statuses:

| Axis | Values | Meaning |
|---|---|---|
| Decision | `OPEN` / `LOCKED` / `REOPENED` | Whether the blueprint stance is still being discussed or approved for this version |
| Work | `PENDING` / `IMPLEMENTING` / `COMPLETED` | Whether the anchor is waiting, active in `docs/tasks`, or accepted/current-ready |

Work transition criteria:

| Status | Checkable meaning |
|---|---|
| `PENDING` | No active execution is happening for this anchor. Discussion, lock, Phase/Milestone planning, or ready-but-not-started work may exist. Details live in `docs/tasks` if a milestone path exists |
| `IMPLEMENTING` | The anchor has active planning, breakdown, task execution, review, acceptance, or Phase gate work in `docs/tasks` |
| `COMPLETED` | The accepted scope is ready for current promotion or has already been reflected in `docs/blueprint/current/` |

Rules:
- Only `LOCKED` anchors may be planned into `docs/tasks/`.
- `OPEN` or `REOPENED` anchors stay in discussion and cannot start implementation.
- If one topic is half decided, split it into smaller anchors so the locked parts can move while open questions remain visible.
- Blueprint lock does not require a complete task split. It locks the Phase/Milestone plan and enough first-milestone task seed to prove executability.
- `bf-milestone-breakdown` creates reviewed task skeleton folders and `task.md` contracts before concrete task work starts.
- Skeleton task folders do not mean task execution has started; task-level state lives in `docs/tasks/README.md`, `milestone.md`, and task folders.
- Each resulting task still owns one worktree, one branch, and one PR when that task starts.
- `COMPLETED` means code is complete, acceptance passed, and required milestone, wave, or Phase gates are recorded; only then may the accepted scope be promoted to `current`.

## Version numbers

The implemented version lives in `docs/blueprint/current/` frontmatter (`accepted: <date>`, `prev: vN.M-1`). A planned target version may be named in `docs/blueprint/next/README.md`, but it does not become current until accepted. Version traceability lives under `docs/blueprint/_meta/`.

| Bump | When | Example |
|---|---|---|
| **Major** (vN → v(N+1).0) | Stance reversal / rename / module removal / direction shift | "local-first" → "server-first" |
| **Minor** (vN.M → vN.(M+1)) | New requirements added, no old stance reversed | Module D added; A/B/C unchanged |
| **Patch** (no bump) | Literal / anchor / accepted constraint fix. Just commit | Accepted anchor +1 line |

**Rule of thumb**: if someone reading vN talks to someone who read v(N-1), will they misunderstand each other? Yes → major. No, just don't know the new thing → minor. Doesn't affect understanding → patch.

## Current-blueprint patch rules

- ✅ Patches allowed only for accepted implementation facts — literal / anchor / constraint, no version bump, just commit
- ❌ Stance reversals or new requirements → must go through `docs/blueprint/next/`, then `docs/tasks/`, then acceptance before current changes
- Patch / bugfix PRs must link `Closes gh#NNN` (root-cause traceability)
- Too many patches = probably a stance reversal → immediately open `docs/blueprint/next/`

## Iteration lifecycle

When the current implemented work passes acceptance, the next selection round can open. Its intake is **GitHub issues labeled `backlog`** — scan them once to decide what gets pulled into `docs/blueprint/next/`. After selection, ongoing state lives in `next` and `tasks`, not issue labels.

After the user names a concrete iteration objective, read `references/lifecycle.md` for the full flow: scan backlog → write/resume `docs/blueprint/next/` with a status ledger → lock anchors → plan `docs/tasks` as Phase -> Milestone with first-milestone task seed → run `bf-milestone-breakdown` for reviewed task skeletons → run `bf-task-execute` one task per PR → run `bf-milestone-progress` after accepted tasks → promote accepted scope into `docs/blueprint/current/`. Use [references/promotion-checklist.md](references/promotion-checklist.md) for accepted-scope promotion. Reminder period is project-defined in `AGENTS.md`.

## Anti-patterns

- ❌ Version number in AGENTS.md (blueprint owns its frontmatter)
- ❌ Patch PR without `Closes gh#NNN` (root-cause chain breaks)
- ❌ Moving unimplemented or unaccepted work into `docs/blueprint/current/`
- ❌ Using GitHub `current-iteration` / `next-iteration` labels as the ongoing workflow state after selection
- ❌ Stuck task dragging the whole milestone or Phase (split it or reopen the anchor)
- ❌ Cramming many current patches that are actually a new next-blueprint stance
- ❌ Opening next selection without scanning `backlog` issues first (cleanup window missed)

## How to invoke

```
follow skill bf-blueprint-iteration

# No objective named → standby, ask which iteration objective to coordinate
# Current accepted → scan backlog → open/resume docs/blueprint/next/
# docs/blueprint/next/ anchors lock → plan docs/tasks/ Phase -> Milestone + task seed
# selected milestone → bf-milestone-breakdown creates reviewed task skeletons
# task starts → one task = one worktree + one branch + one PR
# accepted task/phase scope → promote to docs/blueprint/current/ + tag/meta
```
