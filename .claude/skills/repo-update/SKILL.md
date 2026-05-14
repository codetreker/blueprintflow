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

## Failure-Driven Updates

When a real Blueprintflow run fails because an agent stalled, serialized independent work, bypassed a gate, misrouted, lost context, or required repeated user correction:

1. Record the failure as `symptom -> missing/weak instruction -> owning skill/reference -> prevention check`.
2. Patch the owning skill/reference. Do not add generic reminders to `bf-workflow` unless the failure is entry setup, routing, or global coordination.
3. Add the prevention check to the Local Skill Review Gate prompt: `Would this exact instruction have prevented the observed failure? If not, return NOT LGTM with the missing command.`
4. Record the prevention check result in the PR `Local Skill Review Gate` artifact.
5. Stop before PR readiness if the prevention check is missing or NOT LGTM.

## Local Skill Review Gate

Run this gate after editing any skill body, skill reference, or skill metadata, before marking the change ready.

1. Spawn 4 local subagents in parallel when the runtime supports it.
2. If capacity is insufficient, follow `bf-runtime-adapter`: ask for required authorization, then declare and record `serial fallback` only for true runtime/session incapacity.
3. Give each reviewer the changed file paths, the diff, and this `repo-update` skill. Require each reviewer to read every changed skill/reference as a whole. Do not give them your intended conclusion.
4. Give the Process reviewer `skill-creator` and `writing-skills`, or tell it to load them before review. If either skill is unavailable, record that as a Process blocker and ask Jianjun for a fallback in the PR.
5. For failure-driven changes, give every reviewer the recorded failure and prevention check.
6. Require final output with `Blockers`, `Findings`, `Prevention check` when applicable, and `LGTM` or `NOT LGTM`.
7. Require each finding to state whether it is informational or must-fix.
8. Cover these lenses:

| Reviewer | Required questions |
|---|---|
| Global value / placement | Does the change improve repo-wide Blueprintflow maintenance or skill execution? Is it in the right skill/reference? Should it move, split, or stay out? |
| Process / completeness | Does it follow `repo-update`, `skill-creator`, and `writing-skills`? Are trigger, action, owner, durable review artifact, fallback, and stop condition complete? |
| Language / structure | Is it directive, concise, structured, and unambiguous? Remove vague or descriptive prose. |
| Risk / anti-patterns | Does it create conflicts, loopholes, regressions, stale examples, validation gaps, or anti-patterns? |

9. Architect records the 4 reviewer outcomes in the PR body under `Local Skill Review Gate`, or in a PR comment linked from that section.
10. Fix every blocker and every must-fix finding. Re-run the affected reviewer lens after each fix.
11. Treat local reviewer LGTM as a prerequisite only. It does not replace all-hands PR review or Jianjun approval.
12. Do not check any PR `Review checklist` item until all 4 local reviewers return LGTM and the durable review artifact is recorded.
13. Do not self-approve the gate.

## Anti-patterns

- ❌ Bulk-editing skills with `sed` / scripted replacement before classifying which skills the rule actually applies to.
- ❌ Treating every `bf-*` skill as the same kind of child skill; entry workflows, repo-maintenance flows, role setup, and execution stages have different invocation boundaries.
- ❌ Relying on validation scripts as semantic review. Every changed skill must be read as a whole after the edit.
- ❌ Writing descriptive skill prose when a direct command, checklist, or decision table would remove ambiguity.
- ❌ Updating a skill without the 4-lens local review gate.

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
