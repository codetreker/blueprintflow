---
name: blueprintflow-git-workflow
description: "Blueprintflow's git collaboration rules: one milestone, one worktree, one branch — every role stacks commits on the same branch under .worktrees/<milestone>; only the Teamlead opens the PR and only the Teamlead removes the worktree; one milestone, one PR (don't split into separate schema / server / client / closure PRs). Use this skill whenever a milestone is starting and a worktree needs creating, cleanup after a PR is merged, or a role isn't sure which directory to work in. Don't use for blueprint-level or Phase-level documents (commit on main directly, don't open a milestone worktree), for hotfix urgent path (use a dedicated hotfix branch), or for skill repo updates (use skill-workflow)."
version: 1.0.0
---

# Git Workflow (Milestone Protocol)

A hard rule the user set on 2026-04-29. Pairs with `blueprintflow-pr-review-flow` (merge red lines) and `blueprintflow-milestone-fourpiece` (the four-piece set lands inside the implementation PR).

## 🔒 Hard rules (non-negotiable)

### Rule 1: one milestone, one worktree, one branch

When a milestone starts, the **Teamlead** (and only the Teamlead) creates:

```bash
cd <repo-root>
git worktree add .worktrees/<milestone> -b feat/<milestone> origin/main
```

- Path: `.worktrees/<milestone>` (under the repo root's `.worktrees/`, not `/tmp/`)
- Branch: `feat/<milestone>` (e.g. `feat/<milestone-a>` / `feat/<milestone-b>` / `feat/<milestone-c>`)
- Base: `origin/main` (when rebasing, also rebase onto main; don't stack on another milestone)
- The whole milestone lifecycle **reuses the same worktree + the same branch**

### Rule 2: every role works in the same worktree

Every role involved in the milestone (Dev / Architect / QA / PM / Designer / Security) **stacks commits in the same worktree**:

| Role | What they do in the worktree |
|---|---|
| Dev | Write code (server / client / e2e) + unit tests + screenshots |
| Architect | Write the spec brief (`docs/implementation/modules/<milestone>-spec.md`) |
| QA | Write the acceptance template (`docs/qa/acceptance-templates/<milestone>.md`) + flip acceptance ⚪→✅ |
| PM | Write stance checklist + content lock (`docs/qa/<milestone>-{stance,content-lock}.md`) + stance reverse-checks |
| Designer (UI) | Visual reference + design system anchor |
| Security | auth/admin/cross-org path review (committed) |

**Every role can commit + push to the `feat/<milestone>` branch.** No sub-branches, no stash, no cherry-pick. Everyone sees each other's commits, and cross-role review happens in sync.

### Rule 3: roles don't open PRs

**No role** (including Dev) **may ever** run `gh pr create`. Permanently forbidden:

```bash
# ❌ Dev doesn't open
gh pr create --title "feat(<milestone>.1): schema"

# ❌ Architect doesn't open
gh pr create --title "docs(<milestone>): spec brief v0"

# ❌ QA doesn't open
gh pr create --title "docs(qa): <milestone> acceptance template"

# ❌ PM doesn't open
gh pr create --title "chore(<milestone>): stance + content-lock"
```

The PR is the entry point for the milestone's complete deliverable, not for any single role's output. Roles opening separate PRs would:
- Fragment the milestone (violates "one milestone, one PR")
- Create write contention across multiple PRs on §5 totals / acceptance template / PROGRESS.md
- Create closure follow-up tails

### Rule 4: only the Teamlead creates the PR

After everyone has committed + pushed + self-checked, **only the Teamlead** opens the PR:

```bash
cd <repo-root>/.worktrees/<milestone>
gh pr create --title "feat(<milestone>): <summary>" --body "..."
```

The PR body must contain the full four-piece set + the three implementation sections + e2e + closure (REG flip / acceptance ⚪→✅ / PROGRESS [x]) — per the `blueprintflow-milestone-fourpiece` protocol.

When opening the PR, the Teamlead's mental check:
- Has every role committed to `feat/<milestone>`? (Dev code + Architect spec + QA acceptance + PM stance/content-lock all present)
- Is `docs/current` synced with the code?
- Does the project's regression / registry math add up (where applicable)?
- Has PROGRESS.md `[x]` been flipped?

Any one missing → don't open the PR — send the missing role back to commit.

### Rule 5: after the PR is merged, the Teamlead removes the worktree

```bash
cd <repo-root>
git worktree remove .worktrees/<milestone>
git branch -d feat/<milestone>  # if not auto-pruned
```

Worktree lifecycle is entirely the Teamlead's. Roles don't touch worktrees (don't delete / don't switch branch / don't create new worktrees).

## Workflow timeline

```
teamlead                roles (Dev+Architect+QA+PM+...)         GitHub
   │                            │                                │
   │── git worktree add ──────► │                                │
   │   .worktrees/<milestone>   │                                │
   │   -b feat/<milestone>      │                                │
   │                            │                                │
   │── dispatch to roles (work in worktree) ►│                   │
   │                            │── commit + push ──────────────►│
   │                            │    (Dev code / Architect spec /        │
   │                            │     QA acceptance / PM stance) │
   │                            │── cross-role review (commit  │
   │                            │   comments + ping) ─────── │
   │                            │── all roles self-check + commit │
   │ ◄──────── ready signal ──── │                                │
   │                                                             │
   │── gh pr create ──────────────────────────────────────────►│
   │                                                             │
   │── dispatch review subagents (dual lens) ──────────────────►│
   │                                                             │
   │── standard squash merge (CI really passes) ───────────────►│
   │   (never admin / never ruleset bypass — see pr-review-flow)│
   │                                                             │
   │── git worktree remove ──── cleanup                          │
```

## Anti-patterns

### ❌ A role opens a PR by themselves
Any role running `gh pr create` is overstepping. History:
- Architect opening a standalone spec brief PR → forces the four-piece set into a serial chain
- QA opening a standalone acceptance template PR → fragments the milestone
- Dev splitting into .1 schema / .2 server / .3 client / .4 closure PRs → collisions + rebase nightmare

### ❌ Two milestones sharing one worktree
Worktree and milestone are 1:1. Not allowed:
- One worktree carrying two milestones (e.g. `<milestone-b>` commits sneaking into `.worktrees/<milestone-a>`)
- Cross-milestone branch (e.g. `feat/<milestone-a>-and-<milestone-b>`)
- Worktree reuse (e.g. doing the next version of <milestone-c> in `.worktrees/<milestone-c>.2` — should remove the old worktree and create a new one, or stay on the same branch / same worktree the whole way)

### ❌ Closure follow-up PR / spec drift follow-up PR
Under the new protocol there is no follow-up PR. Status flip / literal sync / closure all happen inside the main PR. If drift is found after the main PR is merged → fix it incidentally in the next milestone's PR. No standalone follow-up.

Exception (use sparingly): a real hard bug fix can be a standalone PR (e.g. `fix/ci-flaky-xyz`), but it **doesn't count as a milestone PR** and the Teamlead doesn't treat it as a milestone follow-up.

### ❌ Teamlead writing code for a role
Teamlead creates worktrees + dispatches + supervises + opens PRs + removes worktrees, **and doesn't write code / specs / acceptance / content lock**. Writing it is overstepping (same as a city engineer overseeing the contractor doesn't lay bricks).

### ❌ Same worktree path reused with a different branch
Dev-d gets <milestone-d> and starts `.worktrees/<milestone-d>` + branch `feat/<milestone-d>-server-client`; later Dev-e starts the same path with branch `feat/<milestone-d>` — the collision overwrites Dev-e's work directly. **A worktree path can only be created once at a time, by the Teamlead, and only one branch at a time.** Roles don't touch worktrees.

### ❌ /tmp/ ad-hoc clones
The `/tmp/<role>-<topic>-work` clone pattern is deprecated. Everything goes through `.worktrees/<milestone>`.

## Pairs with other skills

- `blueprintflow-milestone-fourpiece` — the four-piece set lands inside the implementation PR (one milestone, one PR); the four-piece set is also written by committing into the worktree, not as a separate PR
- `blueprintflow-pr-review-flow` — once the Teamlead opens the PR, it goes through dual review + standard squash (never admin/ruleset bypass)
- `blueprintflow-workflow` — top-level timeline: concept → Phase → milestone (this skill) → exit gate

## Cross-milestone parallelism

N milestones running at once = N worktrees + N branches. The Teamlead creates and removes each. Roles split across worktrees by dispatch:

```
.worktrees/<milestone-a>    ← teamlead create, dev-c + Architect spec + QA acceptance commit
.worktrees/<milestone-b>    ← teamlead create, dev-d + Architect + QA + PM commit
.worktrees/<milestone-c>    ← teamlead create, dev-a + ...
.worktrees/<milestone-d>    ← teamlead create, dev-b + ...
```

A single Dev can only work in one worktree at a time (worktree isolation; no two in-flight at once). Different Devs running N milestones in parallel is fine.

## How to invoke

When a milestone starts:
```
follow skill blueprintflow-git-workflow
teamlead creates .worktrees/<milestone> + feat/<milestone>
dispatch to roles, all roles stack commits in the same worktree
all roles ready → teamlead opens the PR → merged → teamlead removes the worktree
```
