---
name: blueprintflow-pr-review-flow
description: "Part of the Blueprintflow methodology. Use when a milestone PR is open through merge - runs dual review (Architect + QA, plus Security if needed), the three-signoff gate, and standard squash; never admin-bypass."
---

# PR Review Flow

The standard flow once a PR is open until it gets merged.

## Before opening a PR: implementation design with 4 ✅ is required

Before a milestone PR is opened, any milestone that touches code **must** have already passed the four-role implementation design review:

- Design doc: `docs/tasks/<milestone-or-issue>/design.md` (Dev is the primary author)
- Four-role ✅: Architect (architecture + stance) / PM (user value + UX) / Security (auth / data isolation / cross-org) / QA (testability + edge cases)
- Reviews happen through worktree-internal communication or PR comments — no separate PR
- Any one ❌ blocks — the milestone PR cannot open

Full spec is in `blueprintflow-implementation-design`.

Non-code milestones (docs-only / config-only / wording adjustments) can skip this step and go directly to PR review.

## Security review walks the checklist (lazy reference)

When the Security role does a PR review, they pull `references/security-checklist.md` and walk the 12 categories (auth, input validation, sensitive data, sessions and credentials, rate limit, dependencies, configuration and deployment, business logic, etc.).

- The checklist **does not live in the SKILL.md body** — that keeps the main flow's context lean
- During Security review, pick the relevant items based on the PR's change scope
- An LGTM comment must cite specific checklist items (e.g. "§1 auth ✅, §8 IDOR — see line 42, already prevented") — no "blanket approval"

Details in `references/security-checklist.md` (12 categories, each with bullets covering "why" and "how to verify").

## 🚫 Permanently forbidden (hard red line — non-negotiable)

The following methods are **forbidden forever**, no scenario, no excuse. This is a hard red line the user set on 2026-04-29; "temporary" / "stopgap" / "flaky" / "urgent" — none of these excuses are accepted:

1. **`gh pr merge --admin`** — any form of admin bypass flag
2. **Ruleset disable / restore** — even a "≤10s window" is not allowed
3. **Any way of bypassing required CI checks** — modifying the ruleset to remove a check / changing branch protection / disabling required reviewers / granting yourself an admin role, etc.

**Why this is a red line**:
- Admin bypass hides bugs — flaky symptoms turn out to be real bugs more often than they look
- It breaks the "CI really passes" protocol; team signals become noise
- History: e2e failures bypassed into main multiple times, each one needed a hotfix afterwards

**Anti-patterns (permanent)**:
- ❌ `gh pr merge --admin` in any scenario
- ❌ `gh api -X PUT /rulesets/<id> -f enforcement=disabled` in any scenario
- ❌ Dispatching an "admin merge agent" or "batch admin merge agent" — the agent name itself is deprecated
- ❌ Phrases like "ruleset stopgap" or "temporary transition" — there is no temporary; temporary is the start of permanent

## PR template required

Top of the body: 4 lines of bare metadata + 2 H2 sections:

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

If the PR template lint finds any of the 5 fields missing → red. Fix it through the lint patch flow (fix the body / fix the lint regex; **do not bypass**).

## Handling flaky tests

**Signals that a test is flaky**:
- The PR didn't change related code, but a CI case fails → flaky signal
- The same case fails randomly across different PRs → flaky signal
- It already fails occasionally on main → flaky signal (not an excuse — even more reason to fix it)

**Principle for flaky tests: fix, don't rerun**:
- Found flaky → fix the root cause immediately, don't rerun and pray
- Truly flaky → fix the real cause (race condition, timing, environment dependency)
- Lint false positive → fix the lint rule
- Coverage on the line → really add tests to raise coverage
- e2e really fails → send back to author to fix the bug
- In every scenario, **"wait until I've fixed it before merging"** is the only answer; "merge first, fix later" is not an option

**Flaky anti-patterns**:
- ❌ **Rerun and pray** — flaky doesn't fix itself; if a rerun goes green, that's just luck and it'll fail next time
- ❌ **"Not my change, it's already on main"** — at least open a tracking issue, ideally fix it on the side. It doesn't block the current PR, but you can't pretend not to see it
- ❌ **"Merge first, deal with flaky later"** — once it's on main nobody fixes it; flaky just piles up
- ❌ **3 reruns and then green = passed** — 1 fail in 3 = 33% failure rate; that's not "occasional", that's a real bug

## Dual review path

For each PR, dispatch dual reviews immediately:

| PR type | reviewer 1 | reviewer 2 | reviewer 3 (optional) |
|---|---|---|---|
| Dev implementation PR | Architect (architecture) | QA (acceptance) | — |
| Architect spec brief PR | Dev (implementation lens) | QA (acceptance, machine-checkable) | PM (stance) |
| PM stance / content-lock PR | Architect (architecture) | QA (acceptance) | — |
| QA acceptance template / status flip PR | Architect (architecture) | PM (stance, only when v0 stance is involved) | — |
| Sensitive write actions (auth/admin) PR | + Security | | |

> **For client-facing UI / frontend PRs**: QA's signoff is not just code-level acceptance — it walks the three lines defined in `blueprintflow-e2e-verification` (code-level acceptance + product usability + design reasonableness) before LGTM. Skipping the usability or design line is exactly how UI bugs reach users.

LGTM command (author cannot self-approve):
```
gh pr comment <num> --body "LGTM (reason ≤30 chars)"
```

The review must include anchors (literal cross-check against spec/stance/acceptance):
- Does it line up word-for-word with #<other-PR>?
- Is the §X.Y anti-constraint held?
- Is it consistent with the byte-identical template (e.g. shared structure templates across milestones)?

**Merge three-signoff** (CI + LGTM + task completeness):
- ① CI really passes (statusCheckRollup all SUCCESS — never admin/ruleset bypass)
- ② ≥1 non-author LGTM (`gh pr review --approve` OR an LGTM comment from a different reviewer identity)
- ③ **Teamlead reviews PR body Acceptance + Test plan all checked** (`gh pr view <N> --json body | jq -r .body | grep -cE "^- \[ \]"` must be == 0)

All three pass → standard squash merge. Any one missing → don't merge.

The detailed merge gate protocol lives in `blueprintflow-teamlead-fast-cron-checkin §5`. The task-completeness criterion (under the "one milestone, one PR" protocol) is unfolded there.

> Parallel review subagent template is in `references/review-subagent.md`.

## Required anchors
1. `gh pr view <N>` — PR body + diff
2. `gh pr diff <N>` — see the actual change
3. <spec brief / content lock / acceptance template / existing cross-ref PRs>
4. (optional) Existing LGTM comments on the PR — angles already covered, don't repeat

## Review checklist (machine-checkable)
- [ ] Section breakdown lines up 1:1 with the spec brief
- [ ] Counts add up (e.g. 26 items = 5+7+7+7)
- [ ] Byte-identical anchors aligned to N sources (list specific PR # / commit SHA)
- [ ] Anti-constraint grep N-line strong-typed (list specific grep pattern)

## Output
- All pass: `gh pr comment <N> --body "LGTM (<lens> review subagent). [one-line summary of checks]"` — land it on GitHub
- NOT-LGTM: don't comment; report back specific issues + quotes + suggested fixes.

Report ≤200 words.
`
})
```

#### When it applies vs when it doesn't

| Applies | Doesn't apply |
|---|---|
| Routine four-piece review (byte-identical / anti-constraint grep / 1:1 breakdown) | Architectural judgment / drift arbitration (e.g. "is envelope going from 9 to 10 fields drift?") |
| Acceptance template / stance / content lock review | Spec brief authorship (creative work) |
| Count math reconciliation / REG flip | NOT-LGTM arbitration (escalate to persistent role) |

#### Hybrid protocol

1. PR open → dispatch review subagents (N angles in parallel) for machine-checkable verification
2. All LGTM + CI really passes → standard merge (see Merge section below — **never admin/ruleset bypass**)
3. NOT-LGTM or suspected cross-PR drift → escalate to persistent role for arbitration
4. Persistent roles keep: spec brief / stance / acceptance / content lock authorship + drift arbitration + cross-milestone judgment

#### Anti-patterns

- ❌ Subagent review replacing persistent-role authoring (subagent is read-only, doesn't write spec brief / content lock)
- ❌ NOT-LGTM arbitrated by the subagent itself (escalate to persistent)
- ❌ Subagent prompt missing specific cross-ref PR # / commit SHA (review loses byte-identical verification)

## Merge (standard squash, never admin)

Dispatch a general-purpose agent (background) to run it. **Absolutely no --admin / no ruleset disable / no bypassing any required check**:

```
Merge PR #<N>:

1. gh pr view <N> --json statusCheckRollup,mergeStateStatus,reviews,body
2. Verify ≥1 non-author LGTM (gh pr review --approve OR an LGTM comment from a different agent role)
3. If PR template lint finds missing fields:
   patch body via gh api -X PATCH /repos/<owner>/<repo>/pulls/<N> --input <(jq ...)
   close+reopen to trigger lint rerun (fix the body, **do not** modify lint enforcement)
4. CI really passes (statusCheckRollup all SUCCESS) + mergeable=CLEAN + ≥1 non-author LGTM
   → gh pr merge <N> --squash --delete-branch
   (note: --admin is **not allowed** in the command)
5. Any failure scenario goes back to the author to fix; do not bypass:
   - go-test/client-vitest/e2e/bpp-envelope-lint/coverage/build/typecheck FAILURE → author fixes
   - PR template lint regex false positive → fix the regex so a really compliant body passes; don't bypass
   - DIRTY → author rebases main
   - Genuinely flaky → re-trigger CI; if it still fails, send back to author to fix the root cause
6. Report merge time + SHA. The report must **not** contain the words "admin" / "ruleset disable" / "bypass"
```

Note: `gh pr edit --body` doesn't take effect in some environments — use `gh api PATCH` to patch the JSON directly.

#> Batch merge mode is detailed in `references/batch-merge.md`.

## Cross-review example: catching stance drift

> **Real example (Borgee):** While reviewing acceptance, QA self-checked and noticed a field name didn't match the Architect's spec brief (a rename hadn't been propagated). Patched on the spot.

This is the dual-track review working — the spec was written in shape A, acceptance was naturally written against shape A, and the drift surfaced.

## Anti-patterns (consolidated)

**Permanently forbidden (hard red line, listed up top)**:
- ❌ `gh pr merge --admin` in any scenario
- ❌ Ruleset disable/restore in any scenario
- ❌ Any way of bypassing required CI checks
- ❌ Phrases like "ruleset stopgap" / "admin merge agent" / "temporary transition"

**Review do's**:
- ✅ Read the whole file first, then look at the diff
- ✅ Put yourself in others' shoes: "I'm an agent reading this skill for the first time — would this paragraph confuse me?"
- ✅ Each role's review angle must be different:
  - **Architect**: architectural consistency + cost reasonableness + cross-skill conflicts
  - **PM**: user experience + cognitive load + can a new team member understand it
  - **Dev**: executability + ambiguity + would I get stuck following this
  - **QA**: verifiability + how do we know it's done right + are there enough examples
  - **Security**: code vulnerabilities (injection / XSS / SSRF) + auth and least-privilege + sensitive data handling + dependency security
  - **Performance**: algorithmic complexity + hot path performance + unnecessary IO/network calls + memory and concurrency
- ✅ Before LGTM, find 3 things to challenge; if you can't, then LGTM
- ✅ Verify technical details (commands, APIs, parameters) against documentation — don't trust the author
- ✅ Check for unintended side effects — bulk replaces breaking formatting, edits in one place breaking another, renames breaking references
- ✅ When code is added or changed, check that existing logic isn't broken — regression thinking; not just "is the new thing right" but "does the old thing still work"
- ✅ Status flips (acceptance ⚪→✅ / REG flip / PROGRESS [x]) land in the same milestone PR as the implementation — no follow-up PRs
- ❌ Skipping the 5 PR template fields (lint will reject — don't try to bypass by repeating metadata in an H2)
- ❌ The merge agent's report containing "admin" / "ruleset" / "bypass" (transparency + red-line alarm)
- ❌ Self-LGTM counting as dual approval (multiple agents on the same GH account commenting LGTM does not count as ≥1 non-author — needs a real different reviewer identity)

**Operation anti-patterns**:
- ❌ LGTMing without reading the PR body, just templated boilerplate (loses cross-check value)
- ❌ Looking at the diff only without the whole picture — miss broken context, logical contradictions
- ❌ LGTM as long as there's no obvious bug — review isn't "no errors", it's "good enough"
- ❌ Not questioning design reasonableness — "the rule technically allows it" ≠ "actually reasonable" (token cost, UX, cognitive load)
- ❌ Trusting whatever the author wrote — technical details (commands, APIs, parameters) must be verified

## How to invoke

Once a PR is open:
```
follow skill blueprintflow-pr-review-flow
dispatch review for PR #<N>
```
