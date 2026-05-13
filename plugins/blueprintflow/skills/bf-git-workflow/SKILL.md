---
name: bf-git-workflow
description: "Part of the Blueprintflow methodology. Use when starting a milestone or cleaning up after merge - enforces one-milestone-one-worktree-one-branch-one-PR with Teamlead as sole opener and cleaner."
---

# Git Workflow (Milestone Protocol)

Hard rules set on 2026-04-29. Pairs with `bf-pr-review-flow` (merge red lines) and `bf-milestone-fourpiece` (four-piece set lands inside the PR).

## 🔒 Hard rules

### Rule 1: one milestone = one worktree + one branch

Teamlead (only) creates:
```bash
cd <repo-root>
git worktree add .worktrees/<milestone-or-issue> -b feat/<milestone-or-issue> origin/main
```

- Path: `.worktrees/<milestone-or-issue>` (not `/tmp/`)
- Base: `origin/main` (rebase onto main, don't stack on another milestone)
- Same worktree + same branch for the whole lifecycle

### Rule 2: every role works in the same worktree

| Role | Commits in the worktree |
|---|---|
| Dev | Code + tests + screenshots |
| Architect | `spec.md` in milestone folder |
| QA | `acceptance.md` + flip ⚪→✅ |
| PM | `stance.md` + `content-lock.md` |
| Designer | Visual reference + design system |
| Security | Auth/admin/cross-org review |

All push to `feat/<milestone-or-issue>`. No sub-branches, no stash, no cherry-pick.

### Rule 3: roles don't open PRs

No role runs `gh pr create`. The PR = the milestone's complete deliverable, not one role's output.

### Rule 4: Teamlead opens the sole PR

After all roles have committed:
```bash
gh pr create --title "feat(<milestone-or-issue>): <summary>" --body "..."
```

Teamlead's check before opening: every role committed? `docs/current` synced with `bf-current-doc-standard`? PROGRESS flipped?

### Rule 5: Teamlead removes the worktree after merge

```bash
git worktree remove .worktrees/<milestone-or-issue>
```

Roles don't touch worktrees (don't delete / switch branch / create).

## Workflow timeline

```
teamlead              roles                    GitHub
   │                    │                        │
   │─ worktree add ────►│                        │
   │─ dispatch ────────►│                        │
   │                    │─ commit + push ───────►│
   │                    │─ cross-role review ────│
   │◄── ready signal ───│                        │
   │─ gh pr create ─────────────────────────────►│
   │─ squash merge (never admin) ───────────────►│
   │─ worktree remove ─ cleanup                  │
```

## Cross-milestone parallelism

N milestones = N worktrees + N branches. A single Dev works in one worktree at a time. Different Devs run N milestones in parallel.

## Anti-patterns

- ❌ **A role opens a PR** — fragments the milestone, creates closure follow-up tails
- ❌ **Two milestones sharing one worktree** — 1:1 only
- ❌ **Closure follow-up PR** — status flip / sync / closure all land in the main PR
- ❌ **Teamlead writing code** — creates + dispatches + supervises + opens + removes, doesn't build
- ❌ **Same worktree path with different branch** — collision overwrites work
- ❌ **`/tmp/` ad-hoc clones** — deprecated, use `.worktrees/`

## Pairs with

- `bf-milestone-fourpiece` — four-piece set commits in the same worktree
- `bf-pr-review-flow` — dual review + squash merge after Teamlead opens PR
- `workflow` — top-level lifecycle

## How to invoke

```
follow skill bf-git-workflow
```
