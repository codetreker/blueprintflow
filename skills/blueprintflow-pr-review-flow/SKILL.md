---
name: blueprintflow-pr-review-flow
description: "Part of the Blueprintflow methodology. Use when a milestone PR is open through merge - runs dual review (Architect + QA, plus Security if needed), the three-signoff gate, and standard squash; never admin-bypass."
---

# PR Review Flow

The standard flow from PR open to merged.

## Pre-requisite: implementation design ✅

Code milestones must have passed the four-role design review before the PR opens. Design doc at `docs/tasks/<milestone-or-issue>/design.md`. Full spec in `blueprintflow-implementation-design`. Non-code milestones skip this step.

## 🚫 Permanently forbidden (hard red line)

No scenario, no excuse. Set on 2026-04-29:

- ❌ `gh pr merge --admin`
- ❌ Ruleset disable / restore (even "≤10s window")
- ❌ Any way of bypassing required CI checks
- ❌ Phrases like "ruleset stopgap" / "admin merge agent" / "temporary transition"

Admin bypass hides bugs. History: e2e failures bypassed into main → each needed a hotfix.

## PR template

```
Blueprint: blueprint/<file>.md §X.Y
Touches: <packages or docs>
Current sync: <explanation or N/A — reason>
Stage: v0|v1

## Summary
...
## Acceptance
- [x] ...
## Test plan
- [x] ...
```

Missing fields → lint red. Fix through lint patch flow, don't bypass.

## Dual review

| PR type | Reviewer 1 | Reviewer 2 | +Security if sensitive |
|---|---|---|---|
| Dev implementation | Architect (architecture) | QA (acceptance) | ✓ |
| Architect spec brief | Dev (implementation) | QA + PM (stance) | — |
| PM stance / content-lock | Architect | QA | — |
| QA acceptance / status flip | Architect | PM (if v0 stance) | — |

> **UI / frontend PRs**: QA walks the 3 lines from `blueprintflow-e2e-verification` before LGTM.

**Security review**: walks `references/security-checklist.md` (12 categories). LGTM must cite specific items.

LGTM command (author cannot self-approve):
```
gh pr comment <num> --body "LGTM (reason ≤30 chars)"
```

## Three-signoff merge gate

| Gate | Check | Command |
|---|---|---|
| ① CI passes | statusCheckRollup all SUCCESS | `gh pr view <N> --json statusCheckRollup` |
| ② Non-author LGTM | ≥1 different reviewer identity | PR review or LGTM comment |
| ③ Task completeness | Acceptance + Test plan all ✅ | `gh pr view <N> --json body \| jq -r .body \| grep -cE "^- \\[ \\]"` == 0 |

All three pass → `gh pr merge <N> --squash --delete-branch`. Any missing → don't merge.

Detailed merge gate protocol in `blueprintflow-teamlead-fast-cron-checkin` references/execution.md §5.

## Flaky tests

**Principle: fix, don't rerun.**

- PR didn't change related code but CI fails → flaky signal
- Found flaky → fix root cause immediately
- Truly flaky → fix the real cause (race / timing / env dependency)
- Lint false positive → fix the lint rule
- ❌ Rerun and pray / "not my change" / "merge first, fix later" / "3 reruns green = passed"

## Review subagent

Parallel review subagents handle machine-checkable verification. Template in `references/review-subagent.md`. Batch merge in `references/batch-merge.md`.

Subagents are read-only — they verify, they don't author (spec / stance / content-lock). NOT-LGTM → escalate to persistent role.

## Review checklist

- [ ] Section breakdown lines up 1:1 with spec brief
- [ ] Counts add up
- [ ] Byte-identical anchors aligned to sources (list PR # / commit SHA)
- [ ] Anti-constraint grep (list specific pattern)

## Review do's

- Read the whole file, then the diff
- Put yourself in a first-time reader's shoes
- Before LGTM, find 3 things to challenge
- Verify technical details against docs — don't trust the author
- Check for unintended side effects (bulk replace breaking formatting, edits breaking references)
- Check that existing logic isn't broken — regression thinking
- Status flips (acceptance / REG / PROGRESS) land in the same PR, no follow-up

## Anti-patterns

- ❌ LGTM without reading the PR body
- ❌ Diff-only review (miss broken context)
- ❌ "No obvious bug" = LGTM (review is "good enough", not "no errors")
- ❌ Not questioning design reasonableness
- ❌ Self-LGTM as dual approval (same GH account doesn't count)
- ❌ Subagent review replacing persistent-role authoring
- ❌ Merge report containing "admin" / "ruleset" / "bypass"

## How to invoke

```
follow skill blueprintflow-pr-review-flow
dispatch review for PR #<N>
```
