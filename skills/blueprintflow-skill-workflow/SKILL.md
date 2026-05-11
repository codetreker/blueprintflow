---
name: blueprintflow-skill-workflow
description: "Part of the Blueprintflow methodology. Use when adding, editing, or deleting a blueprintflow skill - runs the self-governing worktree to PR to all-hands vote to merge flow for the skill repo."
---

# Skill Workflow

All skill changes (add, edit, delete) go through: **worktree → PR → all-hands review → merge**. Never push to main directly.

## Flow

```bash
# 1. Create worktree
cd /workspace/blueprintflow && git fetch origin
git worktree add .worktrees/<topic> -b docs/<topic> origin/main

# 2. Edit + commit
cd .worktrees/<topic>
# ... edit skill files ...
git add -A && git commit -m "docs(<scope>): <description>"
git push -u origin docs/<topic>

# 3. Open PR
gh pr create --repo codetreker/blueprintflow \
  --title "docs(<scope>): <description>" \
  --body "## Summary\n<what + why>\n\n## Affected skills\n- ..."

# 4. All-hands review (see review table below)

# 5. Merge (after all ✅)
gh pr merge <N> --repo codetreker/blueprintflow --squash

# 6. Clean up
cd /workspace/blueprintflow
git worktree remove .worktrees/<topic>
git fetch origin --prune
```

## Review

| Role | Lens | Question to answer |
|---|---|---|
| Dev | Implementation | Can these rules be executed without ambiguity? |
| PM | User | Can a new team member understand this on first read? |
| QA | Acceptance | Are the rules verifiable? Are there enough examples? |
| Architect | Consistency | Does it conflict with other skills? Does the structure hold? |
| All | Progressive disclosure | Should any section move to references/? |

**Format check**: bulk replace / rename PRs must verify ASCII art, tables, and code block indentation weren't damaged.

**Review standard**: see `blueprintflow-pr-review-flow` for the full review protocol. Core: read the whole thing + put yourself in others' shoes + hunt for problems before LGTM.

## Rules

- **Only the Architect opens PRs and merges**
- **Never push to main directly**
- **All-hands vote required** — Architect + PM + Dev + QA + Jianjun all ✅; any missing = don't merge
- **Read the whole file** — not just the diff
- **No LGTM with open issues** — found a problem = NOT LGTM; author fixes, re-review, then LGTM. "LGTM, not blocking" does not exist
- **Bump `plugin.json` version** — patch for fixes, minor for new skills. Same PR, not follow-up
- **Commit format**: `docs(<skill-name>): <description>`

## When it doesn't apply

- Business project code → `blueprintflow-git-workflow`
- Skills in other projects → that project's own flow
- Pure discussion → channel; only conclusions go through PR

## How to invoke

```
follow skill blueprintflow-skill-workflow
```
