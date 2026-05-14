---
name: bf-pr-review-flow
description: "Part of the Blueprintflow methodology. Use when a task PR is open, under review, blocked, ready for merge, or needs standard Blueprintflow merge-gate handling."
---

# PR Review Flow

The standard flow from PR open to merged.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Pre-requisite: implementation design ✅

Code tasks must have passed the four-role design review before the PR opens. Design doc lives in the task leaf folder as `design.md` (see `bf-milestone-fourpiece` for folder layout). Full spec in `bf-implementation-design`. Non-code tasks skip this step.

## 🚫 Permanently forbidden (hard red line)

No scenario, no excuse. Set on 2026-04-29:

- ❌ `gh pr merge --admin`
- ❌ Ruleset disable / restore (even "≤10s window")
- ❌ Any way of bypassing required CI checks
- ❌ Phrases like "ruleset stopgap" / "admin merge agent" / "temporary transition"

Admin bypass hides bugs. History: e2e failures bypassed into main → each needed a hotfix.

## PR template

```
Blueprint: docs/blueprint/next/<file>.md §X.Y
Touches: <packages or docs>
Current sync: <docs/current path + bf-current-doc-standard check, or N/A — reason>
Stage: v0|v1

## Summary
...
## Acceptance
- [x] ...
## Test plan
- [x] ...
```

Missing fields → lint red. Fix through lint patch flow, don't bypass.

## Required reviews

Every PR is a task PR. Role artifacts are commits inside that task PR, not separate PR types.

| Task content | Required reviewers before merge |
|---|---|
| Code implementation | Architect (architecture) + QA (acceptance) + Security |
| Spec-only task | Dev (executability) + QA (verifiability) + PM (stance) |
| Stance / content-lock task | Architect + QA |
| Acceptance / status-flip task | Architect + PM (if v0/v1 stance changes) |

> **UI / frontend PRs**: QA walks the 3 lines from `bf-e2e-verification` before LGTM.

**Security review**: walks `references/security-checklist.md` (12 categories). LGTM must cite specific items.

LGTM command (author cannot self-approve):
```
gh pr comment <num> --body "LGTM (reason ≤30 chars)"
```

## Three-gate merge rule

| Gate | Check | Command |
|---|---|---|
| ① CI passes | statusCheckRollup all SUCCESS | `gh pr view <N> --json statusCheckRollup` |
| ② Required reviews | Every required reviewer for the task content has non-author LGTM; code tasks include Security | PR review or LGTM comment |
| ③ Task completeness | Acceptance + Test plan all ✅ | `gh pr view <N> --json body \| jq -r .body \| grep -cE "^- \\[ \\]"` == 0 |

For code changes, task completeness includes `docs/current` sync. QA verifies existence; Architect verifies boundary/state/anchor quality with `bf-current-doc-standard`.

All three pass → `gh pr merge <N> --squash --delete-branch`. Any missing reviewer, red CI, or unchecked item → don't merge.

Detailed merge gate protocol in `bf-teamlead-fast-cron-checkin` references/execution.md §5.

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
- Each role reviews from their specific angle:
  - **Architect**: architectural consistency + cost reasonableness + cross-skill conflicts
  - **PM**: user experience + cognitive load + can a new team member understand it
  - **Dev**: executability + ambiguity + would I get stuck following this
  - **QA**: verifiability + how do we know it's done right + enough examples
  - **Security**: injection / XSS / SSRF + auth and least-privilege + sensitive data + dependency security
  - **Performance**: algorithmic complexity + hot path + unnecessary IO/network + memory and concurrency
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

> **Real example (Borgee):** While reviewing acceptance, QA noticed a field name didn't match the Architect's spec brief (a rename hadn't been propagated). Patched on the spot. This is dual-track review working — the spec was written in shape A, acceptance naturally written against shape A, and the drift surfaced.

## How to invoke

```
follow skill bf-pr-review-flow
dispatch review for PR #<N>
```
