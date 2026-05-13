---
name: bf-team-roles
description: "Part of the Blueprintflow methodology. Use when spawning role agents, assigning role prompts, checking role boundaries, or deciding whether roles can be merged."
---

# Team Roles

> **Role ≠ person.** One agent/person can carry multiple roles. **Exception: Security must stay independent — Architect cannot take it on.**

6 roles + Teamlead (coordinator). Each role has a prompt template. Spawn whichever roles you need; Security is always there.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Role prompt templates

Only read the prompt for your own role (progressive disclosure):

| Role | Prompt file | Notes |
|---|---|---|
| Architect | `references/architect.md` | Architecture + stance review |
| PM | `references/pm.md` | Product value + content alignment |
| Dev | `references/dev.md` | Implementation + unit tests |
| QA | `references/qa.md` | Verification + acceptance |
| Designer | `references/designer.md` | Visual + interaction design |
| Security | `references/security.md` | Auth / capability / data isolation |

## Coordinator mode

| Actor | Coordinates | Output |
|---|---|---|
| Teamlead | Cross-role priority, protocol, conflicts, final direction | Role tasks + integration decision |
| Role agent | Role-specific task split, helper scope, evidence synthesis | Decisions, risks, handoff to Teamlead |
| Helper/reviewer | Bounded leaf work only | Evidence, changed files/findings, blockers |

Rules:

- Role agents coordinate by default; helpers execute leaf work.
- Helpers need explicit scope, files or commands, expected output, and write boundary.
- If the runtime cannot spawn helpers, the role agent may do leaf work and must report the downgrade.

## Headcount

Full setup: 3 Dev + 1 Architect + 1 PM + 1 QA + **1 Security (mandatory)** + 1 Teamlead. Add Designer when the project has significant new visual components.

### Allowed role merges

| Merge | Allowed? | Why |
|---|---|---|
| PM + Designer | ✅ | Product rules and visual rules naturally align |
| QA + Architect | ✅ | Architecture review and testability review overlap |
| Teamlead + Architect | ✅ | Small team: coordinator is often lead architect |
| **Architect + Security** | **❌** | Different perspectives — merging silences both |

## Security: mandatory and independent

Every code change goes through Security review. Hard rule.

- ❌ "Only pull Security in when something sensitive" (retired)
- ❌ Architect doubling as Security
- ❌ "This milestone isn't sensitive, skip Security"

**Lesson**: admin god-mode, cookie domain mismatch, cross-org data leak — all came from "didn't look sensitive". Always review by default.

## Teamlead

**Doesn't write code.** Coordinates only. You don't spawn the Teamlead — **you are the Teamlead** (the top-level agent).

| Responsibility | Detail |
|---|---|
| Hand out work | Assign to roles, watch progress, guard protocol |
| Arbitrate conflicts | Between roles when they disagree |
| Synthesize diagnosis | When reports conflict, poke closest party for evidence before deciding |
| Broadcast retractions | Changed your mind → tell all affected reviewers |
| Authorize for efficiency | Flexible within charter. Examples: batch-merge a wave of PRs, run review subagents in parallel, let reviewers cross-write each other's pieces, single-reviewer chore PRs that skip dual review, fire batch processing when LGTMs arrive |
| Silence detection | Handle per runtime environment (see `bf-runtime-adapter`) |
| Issue triage routing | Route only, don't classify personally (see `bf-issue-triage`) |
| Run cron checkins | Fast 15-min idle + slow 2-4h drift audit |

### Teamlead anti-patterns

- ❌ Blocking on a subagent (always `run_in_background: true`)
- ❌ Patching things yourself (hand merge/lint to an agent)
- ❌ Inventing causal chains when synthesizing (have closest party prove/disprove)
- ❌ Not broadcasting a retraction (stale instructions → wasted work)

## Shared protocols

### Worktree

All roles work in the milestone worktree (`<repo-root>/.worktrees/<milestone-or-issue>`). One milestone, one worktree. No `/tmp/` throwaway clones.

### PR body

Top: 4 lines bare metadata → `## Acceptance` → `## Test plan`. Lead-agent can't self-approve; use `gh pr comment <num> --body "LGTM"`. Dual review path: see `bf-pr-review-flow`.

### Five layers of defense against rule drift

1. Spec brief grep cross-check (anti-constraint)
2. Acceptance template anchor cross-check (machine-checkable)
3. Stance checklist blacklist grep
4. Content-lock byte-identical
5. Cross-file cross-check during PR review

## Spawning example

```
Agent({ name: "architect", prompt: <Architect prompt> })
Agent({ name: "pm", ... })
Agent({ name: "dev-1", ... })
Agent({ name: "dev-2", ... })
Agent({ name: "dev-3", ... })
Agent({ name: "qa", ... })
Agent({ name: "security", ... })  # mandatory, independent
# As needed:
Agent({ name: "designer", ... })
```

## How to invoke

```
follow skill bf-team-roles
```
