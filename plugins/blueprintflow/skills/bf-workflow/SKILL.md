---
name: bf-workflow
description: "Part of the Blueprintflow methodology. Use first as the Blueprintflow entrypoint/router before any routed bf-* child skill, and when starting the workflow, onboarding a team, choosing the next skill, or coordinating product work."
---

# Blueprintflow Workflow

`bf-workflow` is the entry driver for Blueprintflow. It brings up the Teamlead boundary, loads the runtime/team setup path, and routes the user's objective to the child skill that owns the detailed procedure.

## Activation

Always start by loading `bf-runtime-adapter` and `bf-team-roles` to establish runtime and team boundaries. Bring up role coordinators according to runtime capacity; dispatch helpers/reviewers only when the objective needs leaf work.

| User input | Teamlead action |
|---|---|
| No concrete objective | Set up runtime/team boundaries, report Blueprintflow active, and ask what milestone, issue, PR, Phase, review, audit, backlog-selection discussion, or cron check-in to coordinate. Do not inspect repo, issue, PR, doc, git, or worktree state. |
| Concrete objective present | Set up runtime/team boundaries, route to the matching child skill, and ask role coordinators to dispatch helpers/reviewers for leaf work. |
| User interrupts or stops | Stop new work. Continue only after the user confirms the same objective or names a new one. |

Workflow active means the Teamlead boundary and runtime/team setup are in place. It does not authorize content inspection by itself.

## Workflow Skeleton

Use the router for exact stage entry, but keep this mainline in view:

```text
1. Setup: bf-runtime-adapter + bf-team-roles
2. Shape: bf-brainstorm -> bf-blueprint-write
3. Plan: bf-phase-plan
4. Execute milestone loop:
   bf-git-workflow -> bf-milestone-fourpiece -> bf-implementation-design
   -> implementation/current-doc sync -> bf-pr-review-flow
5. Coordinate while active:
   bf-teamlead-fast-cron-checkin / bf-teamlead-role-reminder / bf-teamlead-slow-cron-checkin / bf-issue-triage
6. Close Phase: bf-phase-exit-gate
7. Iterate frozen blueprint/backlog: bf-blueprint-iteration
```

## Coordinator Boundary

Teamlead and role agents own decisions in their scopes, but preserve their main-session context by delegating bounded leaf work to helpers/reviewers.

Teamlead owns global coordination decisions: routing, priority, conflict arbitration, user escalation, merge gates, final integration, and progress control. Role coordinators own role decisions: PM value, Architect consistency, QA acceptance, Security risk, Dev implementation approach, and Designer interaction/visual judgment.

Leaf work goes through the relevant coordinator to helpers/reviewers:

- reading issue bodies/comments, blueprint/current/task docs, or code for substantive analysis
- drafting or editing docs/code
- running tests, builds, audits, grep evidence, or verification commands
- gathering evidence for Teamlead or role-coordinator decisions
- choosing backlog pull-in candidates from substantive issue content

Coordinators synthesize helper evidence and decide within their scope. They should not spend coordinator context on long reading, evidence gathering, tests, builds, audits, or code/doc edits. If helper spawning is unavailable, a coordinator may use `serial fallback` for its own lens work and must report the downgrade. If the runtime can spawn agents but host policy requires extra confirmation, ask for confirmation instead of calling it runtime unavailability.

Security is mandatory and independent; Architect cannot double as Security.

## Router

After the user names a concrete objective, load only the matching skill(s):

| Objective | Load next |
|---|---|
| Runtime/team setup | `bf-runtime-adapter`, then `bf-team-roles` |
| Fuzzy concept or unsettled stance | `bf-brainstorm` |
| Write or revise product shape before freeze | `bf-blueprint-write` |
| Split a frozen blueprint into execution Phases | `bf-phase-plan` |
| Start milestone work | `bf-git-workflow`, then `bf-milestone-fourpiece` |
| Design before coding | `bf-implementation-design` |
| Create/update/review `docs/current` | `bf-current-doc-standard` |
| Review or merge a milestone PR | `bf-pr-review-flow` |
| Verify client-facing UI | `bf-e2e-verification` |
| Triage new/untriaged GitHub issues | `bf-issue-triage` |
| Read backlog / choose next work / open next-version discussion | `bf-blueprint-iteration`, then `bf-team-roles` |
| Change blueprint after freeze | `bf-blueprint-iteration` |
| Cron/idle coordination | `bf-teamlead-fast-cron-checkin`, `bf-teamlead-role-reminder`, or `bf-teamlead-slow-cron-checkin` |
| Close a Phase | `bf-phase-exit-gate` |

Route backward when prerequisites are missing: if stances are unsettled, use `bf-brainstorm`; if product shape is not frozen, use `bf-blueprint-write`; if milestone execution has not started, use `bf-git-workflow` and `bf-milestone-fourpiece` before implementation or PR review.

## Hard Rules

- Blueprintflow controls Blueprintflow-scoped work; other process skills run only inside Blueprintflow role and stage boundaries.
- One milestone = one worktree = one branch = one PR.
- Blueprint freezes before build; post-freeze changes go through PR + review.
- Teamlead is the sole PR opener/merger for Blueprintflow milestone work.
- No admin bypass merge; CI must really pass.
- Code changes must sync `docs/current` using `bf-current-doc-standard` when the project uses that convention.
- No self-approval: use a PR comment such as `gh pr comment <num> --body "LGTM"` when the platform cannot express review approval.

## How To Invoke

```text
follow skill bf-workflow
```

Use Blueprintflow for new products, major features, large refactors, multi-role collaboration, stance/blueprint/execution/acceptance tracks, and cross-milestone drift control. Do not use it for one-off single-PR fixes or solo rapid iteration unless the user explicitly wants Blueprintflow governance.
