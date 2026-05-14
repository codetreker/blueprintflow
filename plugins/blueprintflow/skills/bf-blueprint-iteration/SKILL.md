---
name: bf-blueprint-iteration
description: "Part of the Blueprintflow methodology. Use when selecting backlog issues for the next blueprint, locking next-blueprint scope, resuming blueprint discussion, or promoting accepted work into current."
---

# Blueprint Iteration

Blueprintflow separates implemented truth, planned work, execution path, and issue intake. Do not treat blueprint lock as implementation acceptance.

**When this applies**: a project already has an implemented-and-accepted `docs/blueprint/current/`, and the team is selecting or advancing the next body of work. Early brainstorm + first-version write doesn't go through this skill.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

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
- Blueprint lock does not require Phase/Milestone planning or task split. It locks selected next anchors; `bf-phase-plan` creates the Phase/Milestone path and first-milestone task seed after the lock gate passes.
- Blueprint lock requires the Next lock integrity gate below. Do not treat the README ledger alone as proof of lock.
- `bf-milestone-breakdown` creates reviewed task skeleton folders and `task.md` contracts before concrete task work starts.
- Skeleton task folders do not mean task execution has started; task-level state lives in `docs/tasks/README.md`, `milestone.md`, and task folders.
- Each resulting task still owns one worktree, one branch, and one PR when that task starts.
- `COMPLETED` means code is complete, acceptance passed, and required milestone, wave, or Phase gates are recorded; only then may the accepted scope be promoted to `current`.

## Next Lock Integrity Gate

Architect owns this gate. Run it after source trace exists and before marking selected anchors ready for `bf-phase-plan`. Rerun it before resuming an existing Phase plan or starting `bf-milestone-breakdown`.

| Check | Required action |
|---|---|
| Source trace | Verify `docs/blueprint/_meta/<target-version>/source-issues.md` lists picked backlog issues, or `docs/blueprint/_meta/<target-version>/source-notes.md` records the non-issue source. |
| Ledger row | Verify every selected `LOCKED` anchor appears in `docs/blueprint/next/README.md` with Decision, Work, and Next action. Allow `Milestone path` to be `-` before `bf-phase-plan`; require the milestone folder path after planning exists. |
| Detail anchor | Verify every selected `LOCKED` anchor has a stable `§X.Y` heading, slug anchor, or explicit anchor ID in detailed `docs/blueprint/next/` files. |
| Ledger-to-detail link | Replace whole-doc references with section-level references. Each README row must point to the exact detail anchor it locks. |
| Split topics | If one topic splits into locked and open parts, create separate anchors. Keep locked scope and open blockers separate in README and detail docs. |
| Blocker coverage | Record every blocker that prevents execution in the detail docs and summarize it in the README row or linked open anchor. |
| Reverse trace | For each selected anchor, verify source issue or source note -> README row -> detail anchor can be followed without guessing. |
| Phase-plan handoff | If a Phase plan or milestone already exists, verify README `Milestone path` -> `phase-plan.md` / `milestone.md` -> cited next anchor -> source trace. |
| Freshness | Treat evidence as stale if selected anchors, README rows, detail anchors, blockers/open anchors, source issue/note trace, milestone paths, `phase-plan.md`, or `milestone.md` changed after the recorded gate result. |

Required reviewers: Architect + PM + QA + Security. Dev joins when executability, sandbox, migration, or integration blockers affect the lock.

Record the gate result in `docs/blueprint/_meta/<target-version>/next-lock-integrity.md` under `## Gate result`. Link that section from the lock PR body or a PR comment. Include base commit or PR head SHA, checked anchors, source trace artifact, README rows, detail files, milestone paths when present, reviewer decisions, unresolved open anchors, and freshness decision.

When resuming after merge, read `docs/blueprint/_meta/<target-version>/next-lock-integrity.md` first. If the file or `## Gate result` section is missing, treat evidence as missing.

If the gate is missing, stale, or failed, STOP. Architect routes repair through `docs/blueprint/next`, source trace, or `docs/tasks` as needed, reruns role review, and records a fresh gate result before Phase/Milestone planning or milestone breakdown continues.

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

After the user names a concrete iteration objective, read `references/lifecycle.md` for the full flow: scan backlog → write source trace → write/resume `docs/blueprint/next/` with a status ledger → lock anchors → run the Next lock integrity gate → plan `docs/tasks` as Phase -> Milestone with first-milestone task seed → run `bf-milestone-breakdown` for reviewed task skeletons → run `bf-task-execute` one task per PR → run `bf-milestone-progress` after accepted tasks → promote accepted scope into `docs/blueprint/current/`. Use [references/promotion-checklist.md](references/promotion-checklist.md) for accepted-scope promotion. Reminder period is project-defined in `AGENTS.md`.

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
# docs/blueprint/next/ anchors lock → run Next lock integrity gate → plan docs/tasks/ Phase -> Milestone + task seed
# selected milestone → bf-milestone-breakdown creates reviewed task skeletons
# task starts → one task = one worktree + one branch + one PR
# accepted task/phase scope → promote to docs/blueprint/current/ + tag/meta
```
