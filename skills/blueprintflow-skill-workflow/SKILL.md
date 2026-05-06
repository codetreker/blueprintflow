---
name: blueprintflow-skill-workflow
description: "The update process for the blueprintflow skill repo itself: worktree → PR → all-hands vote → merge. The skill repo is self-governing and doesn't mix with business project flows. Use this skill whenever adding, changing, or deleting a blueprintflow skill, changing a skill's anti-constraints, adding a lazy reference, changing a skill description, or doing batch description optimization. Don't use for business project implementation (use milestone-fourpiece + implementation-design), business project blueprint iteration (use blueprint-iteration), single business PR review (use pr-review-flow), or hotfix urgent path."
version: 1.0.0
---

# Skill Workflow

The update process for blueprintflow skills. All skill changes (add, edit, delete) go through this flow — never push to main directly.

## Flow

### 1. Architect creates worktree + branch

```bash
cd /workspace/blueprintflow
git fetch origin
git worktree add .worktrees/<topic> -b docs/<topic> origin/main
```

- Path: `.worktrees/<topic>`
- Branch: `docs/<topic>` (e.g. `docs/generalize-skills`, `docs/add-new-skill`)

### 2. Architect writes the draft

Edit skill files inside the worktree, then commit + push:

```bash
cd /workspace/blueprintflow/.worktrees/<topic>
# edit skill files...
git add -A
git commit -m "docs(<scope>): <description>"
git push -u origin docs/<topic>
```

### 3. Architect opens the PR

```bash
gh pr create --repo codetreker/blueprintflow \
  --title "docs(<scope>): <description>" \
  --body "## Summary\n<what changed and why>\n\n## Affected skills\n- <list affected skills>"
```

### 4. All-hands review

Dev, PM, and QA review and comment on the PR:

- **Dev**: implementation lens — can the rules be executed? Any ambiguity?
- **PM**: user lens — can a new team member understand it? Cognitive load too high?
- **QA**: acceptance lens — are the rules verifiable? Enough examples?
- **Architect**: consistency — does it conflict with other skills? Does the overall structure hold up?
- **All hands**: progressive disclosure — does this skill need to be split into references?

**Review standard**: see the "review do's" section in `blueprintflow-pr-review-flow`. Core: read the whole thing + put yourself in others' shoes + really hunt for problems before LGTM.

**Format check**: PRs that do bulk replace / rename must verify ASCII art (sequence diagrams, tables, code block indentation) wasn't damaged. A diff full of pure-whitespace changes is a red flag.

Review comments via `gh pr comment` or directly on the GitHub PR page.

### 5. Once consensus is reached, the Architect merges

After everyone has signed off (or objections are resolved):

```bash
gh pr merge <N> --repo codetreker/blueprintflow --squash
```

### 6. Architect cleans up the worktree + branch

```bash
cd /workspace/blueprintflow
git worktree remove .worktrees/<topic>
git branch -d docs/<topic>
git fetch origin --prune
```

## Rules

- **Only the Architect can open PRs and merge** — other roles participate through review comments
- **Never push to main directly** — every change goes through a PR
- **PR can only merge after all-hands vote** — Architect, PM, Dev, QA, and Jianjun all ✅; missing any one = don't merge
- **Read the whole thing** — review can't be diff-only; read the post-change skill file in full
- **Commit message format**: `docs(<skill-name>): <description>`

## When it doesn't apply

- Business project code changes (use blueprintflow-git-workflow)
- Skills in other projects (use that project's own flow)
- Pure discussion (hold the discussion in the channel; only fix the conclusion through a PR)

## How to invoke

When you need to change a blueprintflow skill:
```
follow skill skill-workflow
Architect creates the worktree, writes the draft, opens the PR
```
