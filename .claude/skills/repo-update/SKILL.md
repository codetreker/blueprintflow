---
name: repo-update
description: "Part of the Blueprintflow methodology. Use when updating the Blueprintflow repository itself, including skills, plugin metadata, README, CI, scripts, or release notes."
---

# Repo Update

All Blueprintflow repo changes go through: **worktree → PR → all-hands review → merge**. Never push to main directly.

## Flow

```bash
# 1. Create worktree
cd <repo-root> && git fetch origin
git worktree add .worktrees/<topic> -b docs/<topic> origin/main

# 2. Edit + commit
cd .worktrees/<topic>
# ... edit repo files ...
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
cd <repo-root>
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

**Review standard**: see `bf-pr-review-flow` for the full review protocol. Core: read the whole thing + put yourself in others' shoes + hunt for problems before LGTM.

## Skill Writing Standard

Write skills as executable instructions, not essays.

- Use imperative verbs: `Read`, `Create`, `Dispatch`, `Stop`, `Record`, `Verify`.
- Name the trigger, action, owner, artifact, and stop condition.
- Prefer tables, numbered steps, and checklists over paragraphs.
- Keep background only when it changes a decision.
- Keep wording short. Remove examples or explanations that do not prevent a real mistake.
- Avoid vague verbs: `consider`, `think about`, `handle`, `support`, `ensure` without a concrete check.
- Review every changed skill for instruction clarity before LGTM.

## Anti-patterns

- ❌ Bulk-editing skills with `sed` / scripted replacement before classifying which skills the rule actually applies to.
- ❌ Treating every `bf-*` skill as the same kind of child skill; entry workflows, repo-maintenance flows, role setup, and execution stages have different invocation boundaries.
- ❌ Relying on validation scripts as semantic review. Every changed skill must be read as a whole after the edit.
- ❌ Writing descriptive skill prose when a direct command, checklist, or decision table would remove ambiguity.

## Rules

- **Only the Architect opens PRs and merges**
- **Never push to main directly**
- **All-hands vote required** — Architect + PM + Dev + QA + Jianjun all ✅; any missing = don't merge
- **Read the whole file** — not just the diff
- **No LGTM with open issues** — found a problem = NOT LGTM; author fixes, re-review, then LGTM. "LGTM, not blocking" does not exist
- **Bump `plugin.json` version** — patch for fixes, minor for new public skills, major for public skill renames/removals. Same PR, not follow-up
- **Commit format**: `docs(<skill-name>): <description>`

## When it doesn't apply

- Business project code → `bf-git-workflow`
- Skills in other projects → that project's own flow
- Pure discussion → channel; only conclusions go through PR

## How to invoke

```
follow skill repo-update
```
