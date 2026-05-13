---
name: bf-milestone-fourpiece
description: "Part of the Blueprintflow methodology. Use when a milestone starts and code has not begun - establishes the 4 baseline docs (spec brief, stance, content lock, acceptance template) inside one milestone PR."
---

# Milestone 4 pieces

Each milestone = **one PR, merged once**. The 4 pieces + implementation + e2e + `docs/current` sync + REG flip + acceptance ⚪→✅ + PROGRESS [x] all in the same PR.

**Git workflow**: Teamlead creates `.worktrees/<milestone-or-issue>` + branch. 4-piece authors stack commits in the same worktree. Teamlead is the sole PR opener. See `bf-git-workflow`.

## Doc layout

All milestone artifacts in one folder:

```
docs/tasks/<milestone-or-issue>/
├── spec.md           # Architect spec brief §0-§4
├── stance.md         # PM stance checklist
├── content-lock.md   # PM content lock (UI milestones only)
├── acceptance.md     # QA acceptance template
├── design.md         # Dev implementation design
└── progress.md       # per-milestone progress
```

Other locations in `docs/tasks/`:
- Phase exit artifacts: `docs/tasks/phase-N-exit/` (readiness-review.md / announcement.md)
- Cross-milestone index: `docs/tasks/README.md`

When a milestone fully closes (acceptance ✅ + REG flipped + PROGRESS [x]), the whole folder moves to `docs/tasks/archived/`.

## Naming convention

| Folder type | Name format | Example |
|---|---|---|
| Blueprint milestone | Blueprint code | `al-2a-content-lock` |
| GitHub issue | `<issue#>-<short-slug>` | `698-agent-config-form-overlap` |
| Phase container | `phase-N-{name}` | `phase-5-multi-host` |
| Wave container | Descriptive name | `helper-v1-release` |

Anti-pattern: `m698-*` / `gh698-*` prefixes. Folder name describes the work, not the milestone code.

Container folders hold `phase-plan.md` + leaf subfolders. See `bf-phase-plan` references/phase-vs-wave.md for container vs leaf details.

**Two-level index**: `docs/tasks/README.md` lists top-level entries (non-recursive). `<container>/phase-plan.md` lists milestones inside that container. README references containers by name, doesn't duplicate their milestone list.

## The 4 pieces

| # | Piece | Owner | Path | Length |
|---|---|---|---|---|
| 1 | Spec brief | Architect | `spec.md` | ≤80 lines, §0-§4 only |
| 2 | Stance checklist | PM | `stance.md` | ≤80 lines |
| 3 | Acceptance template | QA | `acceptance.md` | ≤50 lines |
| 4 | Content lock | PM | `content-lock.md` | ≤40 lines, UI milestones only |

**Spec brief** (§0-§4): key constraints / segmentation ≤3 segments / carry-over boundary / reverse-check grep / not in scope. **§5+ (dispatch / self-review / changelog) not allowed.**

**Stance checklist**: 5-7 stances anchored to §X.Y + constraint (X is, Y isn't) + v0/v1 + blacklist grep.

**Acceptance template**: 1:1 aligned with segmentation + acceptance four-choice (E2E / blueprint behavior / data contract / behavior invariants) + REG placeholders.

**Content lock**: DOM literal lock + synonym blacklist + reverse grep + demo screenshot path.

## Step 5: implementation design

After 4 pieces, before code, Dev writes `design.md`. Four-role review (Architect / PM / Security / QA) must all ✅ before coding starts. Same worktree, same PR. Full spec in `bf-implementation-design`.

## Literal consistency

The 4 pieces cite each other's §X.Y anchors. Drift gets caught during cross-review.

## Dispatch

```
1. Teamlead creates .worktrees/<milestone-or-issue> + feat/<milestone-or-issue>
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

All segments committed sequentially in the same worktree/branch:

| Segment | Owner | Content |
|---|---|---|
| 1.1 Schema | Dev | Migration + tables + drift test |
| 1.2 Server | Dev | API + business logic + reverse-assertion test |
| 1.3 Client | Dev | UI + e2e |
| 1.4 Current docs | Dev | `docs/current` changes follow `bf-current-doc-standard` |
| 1.5 Flips | QA/Dev | REG 🟢 + acceptance ✅ + PROGRESS [x] |
| ∥ 4 pieces | Arch/PM/QA | Parallel with execution |

Closure (acceptance / REG / PROGRESS) lands in the same PR. **No follow-up PR.**

## File-naming convention

| ✅ Good | ❌ Bad | Why |
|---|---|---|
| `agent_status.go` | `al_1b_2_status.go` | Milestone numbers don't belong in filenames |
| `canvas_renderers_test.ts` | `cv_3_3_renderers_test.ts` | Names should be self-explanatory |
| `privacy_promise.tsx` | `cm5stance/` | Cite milestones in PR descriptions, not filenames |

## Anti-patterns

- ❌ Skipping 4 pieces → stance drift uncatchable
- ❌ Splitting into multiple PRs (actually slower)
- ❌ Execution PR doesn't cite spec § anchors
- ❌ `/tmp/<work>` clone instead of `.worktrees/`
- ❌ One milestone on multiple branches
- ❌ Spec brief writing §5+ (dispatch/changelog — info is in PR body + git log)
- ❌ Content lock written without cross-grepping existing code (orphan drift)

## How to invoke

```
follow skill bf-milestone-fourpiece
```
