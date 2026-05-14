---
name: bf-milestone-fourpiece
description: "Part of the Blueprintflow methodology. Use when a task under a Phase/Milestone starts, code has not begun, and the spec/stance/content-lock/acceptance baseline docs need to be created."
---

# Task 4 Pieces

Compatibility note: the skill name says `milestone-fourpiece`, but the PR atom is now the **Task**. A Milestone groups tasks under a capability objective; it is not itself a PR atom.

Each task = **one PR, merged once**. The 4 pieces + implementation + e2e + `docs/current` sync + REG flip + acceptance ⚪→✅ + PROGRESS [x] all land in that task PR.

**Git workflow**: Teamlead creates `.worktrees/<task>` + branch. 4-piece authors stack commits in the same worktree. Teamlead is the sole PR opener. See `bf-git-workflow`.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Doc layout

This skill runs after a milestone is selected for execution and a concrete task is being started. It is not part of blueprint freeze/lock; `bf-phase-plan` owns Phase/Milestone planning and task seed.

Task artifacts live under Phase -> Milestone -> Task:

```
docs/tasks/phase-N-<name>/
├── phase-plan.md
└── milestone-<n>-<name>/
    ├── milestone.md
    └── task-<n>-<name>/
        ├── spec.md           # Architect spec brief §0-§4
        ├── stance.md         # PM stance checklist
        ├── content-lock.md   # PM content lock (UI tasks only)
        ├── acceptance.md     # QA acceptance template
        ├── design.md         # Dev implementation design
        └── progress.md       # per-task progress
```

Ad-hoc issue tasks may use a compact path when no Phase exists yet:

```
docs/tasks/<issue#>-<short-slug>/
├── spec.md           # Architect spec brief §0-§4
├── stance.md         # PM stance checklist
├── content-lock.md   # PM content lock (UI tasks only)
├── acceptance.md     # QA acceptance template
├── design.md         # Dev implementation design
└── progress.md       # per-task progress
```

Other locations in `docs/tasks/`:
- Phase exit task artifacts: `docs/tasks/phase-N-<name>/milestone-phase-exit/task-phase-exit/` (readiness-review.md / announcement.md)
- Cross-Phase/Milestone/Task index: `docs/tasks/README.md`

When a task fully closes (acceptance ✅ + REG flipped + PROGRESS [x]), the task folder can move to `docs/tasks/archived/` after its milestone/phase no longer needs it in the active resume view.

## Naming convention

| Folder type | Name format | Example |
|---|---|---|
| Phase container | `phase-N-<name>` | `phase-5-multi-host` |
| Milestone container | `milestone-N-<name>` | `milestone-2-web-configure` |
| Task leaf | `task-N-<name>` | `task-1-configure-job-api` |
| Ad-hoc GitHub issue task | `<issue#>-<short-slug>` | `698-agent-config-form-overlap` |

Anti-pattern: `m698-*` / `gh698-*` prefixes. Folder name describes the work and level.

Container folders hold `phase-plan.md` or `milestone.md` plus task leaf subfolders. See `bf-phase-plan` references/phase-vs-wave.md for container vs leaf details.

**Index rule**: `docs/tasks/README.md` lists active Phases and the current resume focus. `phase-plan.md` lists milestones. `milestone.md` lists tasks. Do not duplicate every task row in every parent file.

## The 4 pieces

| # | Piece | Owner | Path | Length |
|---|---|---|---|---|
| 1 | Spec brief | Architect | `spec.md` | ≤80 lines, §0-§4 only |
| 2 | Stance checklist | PM | `stance.md` | ≤80 lines |
| 3 | Acceptance template | QA | `acceptance.md` | ≤50 lines |
| 4 | Content lock | PM | `content-lock.md` | ≤40 lines, UI tasks only |

**Spec brief** (§0-§4): key constraints / segmentation ≤3 segments / carry-over boundary / reverse-check grep / not in scope. **§5+ (dispatch / self-review / changelog) not allowed.**

**Stance checklist**: 5-7 stances anchored to §X.Y + constraint (X is, Y isn't) + v0/v1 + blacklist grep.

**Acceptance template**: 1:1 aligned with segmentation + acceptance four-choice (E2E / blueprint behavior / data contract / behavior invariants) + REG placeholders.

**Content lock**: DOM literal lock + synonym blacklist + reverse grep + demo screenshot path.

## Step 5: implementation design

After 4 pieces, before code, Dev writes `design.md`. Four-role review (Architect / PM / Security / QA) must all ✅ before coding starts. Same task worktree, same task PR. Full spec in `bf-implementation-design`.

## Literal consistency

The 4 pieces cite each other's §X.Y anchors. Drift gets caught during cross-review.

## Dispatch

```
1. Teamlead creates .worktrees/<task> + feat/<task>
2. Architect → spec brief (commit + push, no PR)
3. PM → stance + content lock (commit + push, no PR)
4. QA → acceptance template (commit + push, no PR)
5. Dev → implementation design (commit + push)
6. Four-role design review → all ✅
7. Dev → execution segments + e2e + current-doc sync + flips (commit + push)
8. Everyone ready → Teamlead opens PR
9. Merged → Teamlead removes worktree
```

## Segmented execution

All segments committed sequentially in the same task worktree/branch:

| Segment | Owner | Content |
|---|---|---|
| 1.1 Schema | Dev | Migration + tables + drift test |
| 1.2 Server | Dev | API + business logic + reverse-assertion test |
| 1.3 Client | Dev | UI + e2e |
| 1.4 Current docs | Dev | `docs/current` changes follow `bf-current-doc-standard` |
| 1.5 Flips | QA/Dev | REG 🟢 + acceptance ✅ + PROGRESS [x] |
| Pre-work | Arch/PM/QA | Four pieces already committed before implementation |

Closure (acceptance / REG / PROGRESS) lands in the same PR. **No follow-up PR.**

## File-naming convention

| ✅ Good | ❌ Bad | Why |
|---|---|---|
| `agent_status.go` | `al_1b_2_status.go` | Milestone numbers don't belong in filenames |
| `canvas_renderers_test.ts` | `cv_3_3_renderers_test.ts` | Names should be self-explanatory |
| `privacy_promise.tsx` | `cm5stance/` | Cite milestones in PR descriptions, not filenames |

## Anti-patterns

- ❌ Skipping 4 pieces → stance drift uncatchable
- ❌ Splitting one task into multiple PRs (actually slower)
- ❌ Treating a milestone as one giant PR when it should be split into tasks
- ❌ Execution PR doesn't cite spec § anchors
- ❌ `/tmp/<work>` clone instead of `.worktrees/`
- ❌ One task on multiple branches
- ❌ Spec brief writing §5+ (dispatch/changelog — info is in PR body + git log)
- ❌ Content lock written without cross-grepping existing code (orphan drift)

## How to invoke

```
follow skill bf-milestone-fourpiece
```
