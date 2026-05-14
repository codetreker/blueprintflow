---
name: bf-team-roles
description: "Part of the Blueprintflow methodology. Use when spawning role agents, assigning role prompts, checking role boundaries, or deciding whether roles can be merged."
---

# Team Roles

> **Role ≠ person.** One agent/person can carry multiple roles. **Exception: Security must stay independent — Architect cannot take it on.**

6 roles + Teamlead. Teamlead and role agents are coordinators. Bring up whichever role coordinators the runtime and objective need; Security is always there. Helpers/reviewers do bounded leaf work under a coordinator.

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

## Spawn contract

Every spawned role coordinator must receive three prompt parts:

1. **Common coordinator preamble**: you are `<Role> Coordinator`, not a leaf worker; act as a long-lived teammate for Teamlead; preserve your main-session context for role decisions; dispatch helpers/reviewers for long reading, evidence gathering, drafting, edits, tests, and implementation; synthesize helper evidence back to Teamlead; use `serial fallback` only when helper spawning is truly unavailable, not when user authorization is missing or ambiguous.
2. **Delegated activation envelope**: `bf-workflow` is active under Teamlead, parent Teamlead identity/contact, concrete objective or active setup scope, allowed child `bf-*` skills, worktree/path scope, runtime/helper capacity, and expected output.
3. **Role-specific prompt**: load only `references/<role>.md` for that coordinator's own role.

Role coordinators may call routed `bf-*` skills only inside a valid delegated activation envelope. If the envelope is missing, stale, or outside scope, stop and ask Teamlead for a fresh assignment; do not reload `bf-workflow` or inspect project content on your own.

## Coordinator mode

| Actor | Coordinates | Output |
|---|---|---|
| Teamlead | Cross-role priority, protocol, conflicts, final direction | Role tasks + integration decision |
| Role agent | Role-specific task split, helper scope, evidence synthesis | Decisions, risks, handoff to Teamlead |
| Helper/reviewer | Bounded leaf work only | Evidence, changed files/findings, blockers |

Rules:

- Role agents coordinate by default; helpers execute leaf work. The global coordinator/worker boundary is defined in `bf-workflow` and applies here.
- Helpers need explicit scope, files or commands, expected output, and write boundary.
- If the runtime truly cannot spawn helpers, the role agent may do leaf work only after declaring `serial fallback` and must report the downgrade. If spawning is blocked by missing or ambiguous user authorization, ask Teamlead to request authorization instead of falling back.

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

**Doesn't do leaf work.** Coordinates only. You don't spawn the Teamlead — **you are the Teamlead** (the top-level agent).

| Responsibility | Detail |
|---|---|
| Hand out work | Assign to roles, watch progress, guard protocol |
| Drive process continuously | Move the next Blueprintflow transition; treat cron/reminders as backstops |
| Resume after interruption | Reconcile the notebook with source-of-truth state, name the interrupted action, and dispatch the restart action in the same turn |
| Keep team utilized | Assign every idle teammate useful work within runtime capacity, or record the specific wait/blocker |
| Diagnose bottlenecks | When the team is not full, name the blocker and dispatch the unblock action |
| Track task state | Keep `~/.blueprint/<repo-dir>/teamlead.md` current using `bf-workflow/references/teamlead-notebook.md` |
| Arbitrate conflicts | Between roles when they disagree |
| Synthesize diagnosis | When reports conflict, poke closest party for evidence before deciding |
| Broadcast retractions | Changed your mind → tell all affected reviewers |
| Authorize for efficiency | Flexible within charter. Examples: batch-merge a wave of PRs, run review subagents in parallel, let reviewers cross-write each other's pieces, single-reviewer chore PRs that skip dual review, fire batch processing when LGTMs arrive |
| Silence detection | Handle per runtime environment (see `bf-runtime-adapter`) |
| Issue triage routing | Route only, don't classify personally (see `bf-issue-triage`) |
| Run cron checkins | Project-defined fast active-work check-in + slow drift audit |

### Teamlead anti-patterns

- ❌ Blocking on a subagent (always `run_in_background: true`)
- ❌ Patching things yourself (hand merge/lint to an agent)
- ❌ Letting idle teammates sit while independent work exists
- ❌ Waiting for cron to drive the next step instead of actively dispatching
- ❌ Asking what to do next after resume when notebook and source-of-truth state identify the restart action
- ❌ Inventing causal chains when synthesizing (have closest party prove/disprove)
- ❌ Not broadcasting a retraction (stale instructions → wasted work)

## Shared protocols

### Worktree

All roles work in the task worktree (`<repo-root>/.worktrees/<task>`). One task, one worktree, one branch, one PR. No `/tmp/` throwaway clones.

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
Agent({ name: "bf-architect", prompt: <common preamble + delegated envelope + Architect prompt> })
Agent({ name: "bf-pm", ... })
Agent({ name: "bf-dev", ... })
Agent({ name: "bf-qa", ... })
Agent({ name: "bf-security", ... })  # mandatory, independent
# As needed:
Agent({ name: "bf-designer", ... })
```

## How to invoke

```
follow skill bf-team-roles
```
