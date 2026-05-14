---
name: bf-git-workflow
description: "Part of the Blueprintflow methodology. Use when starting a task branch/worktree, coordinating task commits, opening the task PR, or cleaning up after merge."
---

# Git Workflow (Task Protocol)

Task is the PR atom. Pairs with `bf-milestone-breakdown` (reviewed `task.md` contract), `bf-pr-review-flow` (merge red lines), and `bf-task-fourpiece` (task four-piece set lands inside the PR).

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## 🔒 Hard rules

### Rule 1: one task = one worktree + one branch + one PR

Teamlead (only) creates:
```bash
cd <repo-root>
git worktree add .worktrees/<task> -b feat/<task> origin/main
```

- Path: `.worktrees/<task>` (not `/tmp/`)
- Base: `origin/main` (rebase onto main, don't stack on another task)
- Same worktree + same branch for the whole lifecycle

### Rule 2: every role works in the same worktree

| Role | Commits in the worktree |
|---|---|
| Dev | Code + tests + screenshots |
| Architect | `spec.md` in the task leaf folder |
| QA | `acceptance.md` + flip ⚪→✅ |
| PM | `stance.md` + `content-lock.md` |
| Designer | Visual reference + design system |
| Security | Auth/admin/cross-org review |

All push to `feat/<task>`. No sub-branches, no stash, no cherry-pick.

### Rule 3: roles don't open PRs

No role runs `gh pr create`. The PR = the task's complete deliverable, not one role's output.

### Rule 4: Teamlead opens the sole PR

After all roles have committed:
```bash
gh pr create --title "feat(<task>): <summary>" --body "..."
```

Teamlead's check before opening: every role committed? `docs/current` synced with `bf-current-doc-standard` when applicable? Task PROGRESS updated?

### Rule 5: Teamlead removes the worktree after merge

```bash
git worktree remove .worktrees/<task>
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

## Cross-task parallelism

N tasks = N worktrees + N branches + N PRs. A single Dev works in one task worktree at a time. Different Devs run N tasks in parallel, including tasks under the same milestone when dependencies allow.

## Active Task Resume

When a task starts, Teamlead records it in `docs/tasks/README.md`:

```markdown
## Active Task Resume

| Scope | Execution | Active task | Owner | Worktree/branch | PR | Blocker | Progress |
|---|---|---|---|---|---|---|---|
| phase-6/milestone-2 | IMPLEMENTING | task-1-configure-job-api | Dev | .worktrees/task-1-configure-job-api / feat/task-1-configure-job-api | #820 | none | task-1-configure-job-api/progress.md |
```

Update this row when owner, branch, PR, blocker, or checkpoint changes. Remove it after task merge/closure; completed state lives in the task folder and milestone closure records.

## Anti-patterns

- ❌ **A role opens a PR** — fragments the task, creates closure follow-up tails
- ❌ **Two tasks sharing one worktree** — 1:1 only
- ❌ **Closure follow-up PR** — status flip / sync / closure all land in the main PR
- ❌ **Teamlead writing code** — creates + dispatches + supervises + opens + removes, doesn't build
- ❌ **Same worktree path with different branch** — collision overwrites work
- ❌ **`/tmp/` ad-hoc clones** — deprecated, use `.worktrees/`

## Pairs with

- `bf-task-fourpiece` — task four-piece set commits in the same worktree
- `bf-milestone-breakdown` — reviewed task skeletons and `task.md` contracts before task work starts
- `bf-pr-review-flow` — dual review + squash merge after Teamlead opens PR
- `workflow` — top-level lifecycle

## How to invoke

```
follow skill bf-git-workflow
```
