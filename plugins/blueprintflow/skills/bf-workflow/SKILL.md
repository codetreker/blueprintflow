---
name: bf-workflow
description: "Part of the Blueprintflow methodology. Use first as the Blueprintflow entrypoint/router before any routed bf-* child skill, and when starting the workflow, onboarding a team, choosing the next skill, or coordinating product work."
---

# Blueprintflow Workflow

`bf-workflow` is the entry driver for Blueprintflow. It brings up the Teamlead boundary, loads the runtime/team setup path, and routes the user's objective to the child skill that owns the detailed procedure.

## Activation

Always start by loading `bf-runtime-adapter` and `bf-team-roles` to establish runtime and team boundaries. This entrypoint activation is allowed to load those setup skills even though routed child skills normally require `bf-workflow` to be active first.

Bring up role coordinators according to runtime capacity. Do not dispatch helpers/reviewers, start cron/sleeper/automation checks, or inspect project content until the user names a concrete objective or explicitly requests ongoing coordination.

| User input | Teamlead action |
|---|---|
| No concrete objective | Set up runtime/team boundaries, report Blueprintflow active, and ask what Phase, milestone, task, issue, PR, review, audit, backlog-selection discussion, or cron check-in to coordinate. Do not inspect repo, issue, PR, doc, git, or worktree state. |
| Concrete objective present | Set up runtime/team boundaries, route to the matching child skill, and ask role coordinators to dispatch helpers/reviewers for leaf work. |
| User interrupts or stops | Stop new work. Continue only after the user confirms the same objective or names a new one. |

Workflow active means the Teamlead boundary and runtime/team setup are in place. It does not authorize content inspection, leaf work, or scheduled check-ins by itself.

## Workflow Skeleton

Use the router for exact stage entry, but keep this mainline in view:

```text
1. Setup: bf-runtime-adapter + bf-team-roles
2. Shape: bf-brainstorm -> bf-blueprint-write
3. Plan locked next scope: bf-phase-plan (Phase -> Milestone + first task seed)
4. Break down the selected milestone: bf-milestone-breakdown (reviewed task skeletons)
5. Start task loop:
   bf-git-workflow -> bf-milestone-fourpiece -> bf-implementation-design
   -> implementation/current-doc sync -> bf-pr-review-flow
6. Coordinate while active:
   bf-teamlead-fast-cron-checkin / bf-teamlead-role-reminder / bf-teamlead-slow-cron-checkin / bf-issue-triage
7. Close Phase: bf-phase-exit-gate
8. Iterate accepted current / locked next / backlog intake: bf-blueprint-iteration
```

## Coordinator Boundary

Teamlead and role agents own decisions in their scopes, but preserve their main-session context by delegating bounded leaf work to helpers/reviewers.

Teamlead owns global coordination decisions: routing, priority, conflict arbitration, user escalation, merge gates, final integration, and progress control. Role coordinators own role decisions: PM value, Architect consistency, QA acceptance, Security risk, Dev implementation approach, and Designer interaction/visual judgment.

Teamlead must maintain the project coordination notebook at `~/.blueprint/<repo-dir>/teamlead.md`. Read `references/teamlead-notebook.md` before routing or dispatching a concrete objective, and update the notebook after dispatches, blockers, retractions, PR gate decisions, merges, or pauses.

Teamlead must spawn role coordinators with the `bf-team-roles` delegated activation envelope so they know `bf-workflow` is active, which child skills they may load, and what scope they are allowed to inspect.

Leaf work goes through the relevant coordinator to helpers/reviewers:

- reading issue bodies/comments, blueprint/current/next/task docs, or code for substantive analysis
- drafting or editing docs/code
- running tests, builds, audits, grep evidence, or verification commands
- gathering evidence for Teamlead or role-coordinator decisions
- choosing backlog pull-in candidates from substantive issue content

Coordinators synthesize helper evidence and decide within their scope. They should not spend coordinator context on long reading, evidence gathering, tests, builds, audits, or code/doc edits. If helper spawning is truly unavailable, a coordinator may use `serial fallback` for its own lens work and must report the downgrade. Missing or ambiguous user authorization is not unavailability: if the runtime can spawn agents but host policy or the tool contract requires extra confirmation, ask the user for authorization instead of calling it runtime unavailability.

Teamlead treats role coordinators as long-lived teammates. Once brought up, role coordinators stay open for the Blueprintflow session and receive concise deltas for follow-up work. Only short-lived helpers/reviewers may be closed after their evidence or patch has been integrated.

Reuse active coordinators/helpers when their context is still valid. Spawn fresh only for independence, stale or biased context, materially different scope, overload, parallelism, or required Security/review separation.

Security is mandatory and independent; Architect cannot double as Security.

## Router

After the user names a concrete objective, load only the matching skill(s):

| Objective | Load next |
|---|---|
| Runtime/team setup | `bf-runtime-adapter`, then `bf-team-roles` |
| Fuzzy concept or unsettled stance | `bf-brainstorm` |
| Write or revise product shape before next lock | `bf-blueprint-write` |
| Split locked next-blueprint anchors into execution Phases/Milestones, with task seed | `bf-phase-plan` |
| Break a selected milestone into reviewed task skeletons | `bf-milestone-breakdown` |
| Start task work | `bf-git-workflow`, then `bf-milestone-fourpiece` |
| Design before coding | `bf-implementation-design` |
| Create/update/review `docs/current` | `bf-current-doc-standard` |
| Review or merge a task PR | `bf-pr-review-flow` |
| Verify client-facing UI | `bf-e2e-verification` |
| Triage new/untriaged GitHub issues | `bf-issue-triage` |
| Read backlog / choose next work / open or resume next discussion | `bf-blueprint-iteration`, then `bf-team-roles` |
| Change blueprint after current acceptance | `bf-blueprint-iteration` |
| Cron/idle coordination | `bf-teamlead-fast-cron-checkin`, `bf-teamlead-role-reminder`, or `bf-teamlead-slow-cron-checkin` |
| Close a Phase | `bf-phase-exit-gate` |

Route backward when prerequisites are missing: if stances are unsettled, use `bf-brainstorm`; if next product shape is not locked, use `bf-blueprint-write`; if Phase/Milestone planning is missing, use `bf-phase-plan`; if milestone task skeletons are missing or unreviewed, use `bf-milestone-breakdown`; if a concrete task has not started, use `bf-git-workflow` and `bf-milestone-fourpiece` before implementation or PR review.

## Hard Rules

- Blueprintflow controls Blueprintflow-scoped work; other process skills run only inside Blueprintflow role and stage boundaries.
- `docs/blueprint/current/` is implemented and accepted only; planned or in-progress work stays in `docs/blueprint/next/`.
- `docs/tasks/` is the next -> current execution path: Phase -> Milestone first, then reviewed task skeletons at milestone breakdown, then concrete task work.
- One task = one worktree = one branch = one PR.
- Next-blueprint anchors lock before Phase/Milestone planning; `bf-milestone-breakdown` creates reviewed task skeletons before task work; accepted work promotes to current only after coding and acceptance pass.
- Teamlead is the sole PR opener/merger for Blueprintflow milestone work.
- No cron, sleeper, or automation setup without a concrete objective or explicit ongoing-coordination request.
- No closing role coordinators as task cleanup; treat them as long-lived teammates for the Blueprintflow session.
- No admin bypass merge; CI must really pass.
- Code changes must sync `docs/current` using `bf-current-doc-standard` when the project uses that convention.
- No self-approval: use a PR comment such as `gh pr comment <num> --body "LGTM"` when the platform cannot express review approval.

## How To Invoke

```text
follow skill bf-workflow
```

Use Blueprintflow for new products, major features, large refactors, multi-role collaboration, stance/blueprint/execution/acceptance tracks, and cross-milestone drift control. Do not use it for one-off single-PR fixes or solo rapid iteration unless the user explicitly wants Blueprintflow governance.
