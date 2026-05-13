---
name: bf-workflow
description: "Part of the Blueprintflow methodology. Use first as the Blueprintflow entrypoint/router before any routed bf-* child skill, and when starting the workflow, onboarding a team, choosing the next skill, or coordinating product work."
---

# Blueprintflow Workflow

Blueprintflow coordinates multi-agent product work from concept to blueprint to Phase to milestone to PR to gate. The parent agent is **Teamlead**: it coordinates, assigns, and gates; roles execute and review.

## Non-negotiables

- **Bare activation is standby only.** No issue/PR/doc/git/worktree discovery, role dispatch, or cron setup until the user names a concrete objective.
- **Concrete objective activates the team protocol.** When the user invokes Blueprintflow with a named milestone, issue, PR, Phase, review, audit, backlog-selection, or cron objective, enter Assigned and load the runtime adapter. If the objective needs substantive reading, role judgment, drafting, verification, or review, activate the minimum role/helper set allowed by the runtime; do not wait for separate "spawn agents" wording.
- Blueprintflow controls Blueprintflow-scoped work. Other process skills may run only inside Blueprintflow role and stage boundaries.
- Teamlead dispatches leaf work (context exploration, design, implementation, testing, verification, review) to the appropriate role/helper.
- Security is mandatory and independent; Architect cannot double as Security.
- One milestone = one worktree = one branch = one PR.
- Blueprint freezes before build; changes after freeze go through PR + review.
- No admin bypass merge; CI must really pass.
- Code changes must sync `docs/current` using `bf-current-doc-standard` when the project uses that convention.

If role/helper spawning is unavailable, or the host runtime policy requires an extra confirmation before spawning, the coordinator must state the blocker before doing role-lens work. Use `serial fallback` only when spawning is truly unavailable; otherwise ask for the missing confirmation instead of silently downgrading.

## Activation Routing

Blueprintflow has two activation modes:

| User input | State | Teamlead action |
|---|---|---|
| Bare `$blueprintflow`, "activate Blueprintflow", or workflow load with no objective | Standby | Report runtime and Teamlead boundary; no repo, issue, PR, doc, worktree, cron, or role inspection |
| `$blueprintflow` plus a concrete objective | Assigned | Run runtime preflight, route to the matching skill, and activate the minimum role/helper set required for any leaf work |

Examples of concrete objectives:

- "Read GitHub backlog and discuss what to do next" → `bf-blueprint-iteration` + `bf-team-roles`; roles read backlog bodies and propose pull-in candidates.
- "Triage new untriaged issues" → `bf-issue-triage`; roles classify new issues through the issue entry gate.
- "Review PR #123" → `bf-pr-review-flow`; reviewers inspect the PR and report evidence.

## Coordinator / Worker Boundary

This boundary applies to Teamlead and every Role Coordinator across all `bf-*` skills.

Coordinators coordinate; workers do leaf work. A coordinator session must not perform leaf work directly, even when the leaf work belongs to that coordinator's role. If a task requires substantive project inspection, role judgment, drafting, editing, testing, or verification, the coordinator must spawn or reuse a worker/helper with a bounded scope and synthesize the returned evidence.

Coordinator-local work is limited to:

- Loading Blueprintflow skills and runtime adapters.
- Reading repo-local coordination rules such as `AGENTS.md` / `CLAUDE.md`.
- Reading routing metadata only, such as issue number/title/labels, PR number/title/status, file path lists, or existing role status.
- Assigning role/worker scopes.
- Synthesizing worker outputs.
- Enforcing gates, asking the user for decisions, and recording coordination state.

Leaf work includes:

- Reading issue bodies/comments for classification or selection.
- Reading blueprint/current/task docs for product or technical analysis.
- Reading code for implementation or review.
- Writing or editing docs/code.
- Deciding backlog pull-in candidates from substantive content.
- Drafting blueprint text.
- Running tests, builds, audits, grep-based evidence collection, or verification commands.
- Making PM/Architect/QA/Security judgments.

Leaf work must be delegated to a worker/helper. If spawning is unavailable, use the `serial fallback` rule above.

## Subagent Reuse

Coordinators should reuse existing relevant subagents whenever their context is still valid.

Default: continue the same role coordinator or worker thread for follow-up work in the same scope, especially when the task depends on prior findings, repo context, decisions, or partially completed analysis. Do not spawn one-off workers for every small follow-up when an existing scoped worker can continue safely.

Spawn a fresh subagent only when:

- The task needs independent judgment or blind review.
- Prior context may bias the result.
- The scope is materially different.
- The old subagent is closed, stale, blocked, or overloaded.
- Work must run in parallel and the existing subagent is already busy.
- Security/review independence requires separation.

When reusing a subagent, send a concise delta: what changed, what decision is needed now, and what output is expected. Do not ask it to rediscover context it already has unless stale context is a risk.

## Skill composition rule

When Blueprintflow is active, Blueprintflow is the controlling workflow for Blueprintflow-scoped work.

Other implementation/process skills may still be used, but only inside the role and stage boundaries defined by Blueprintflow. If another skill says to explore context, write a design, implement, test, verify, or review:

- Teamlead dispatches that leaf work to the appropriate role/helper.
- Role Coordinators dispatch role leaf work to helpers; role workers/helpers may use the other skill within their assigned scope.
- Teamlead synthesizes role outputs and makes coordination decisions; Teamlead does not perform leaf work directly.
- Security remains independent and cannot be merged into Architect.

If another skill conflicts with Blueprintflow protocol, Blueprintflow wins for Blueprintflow-scoped work.

## Standby Boundary

If the user only invokes `bf-workflow`, says "activate Blueprintflow", or asks to load the workflow without naming a milestone, issue, PR, Phase, review, audit, backlog-selection discussion, or cron check-in:

- Enter **Standby**: report the runtime mode and Teamlead boundary.
- Do not inspect GitHub issues, PRs, git log, task docs, blueprint docs, current-state docs, or worktrees.
- Do not infer the current project stage from repo state.
- Do not spawn role agents/helpers.
- Do not start crons or sleeper agents.
- Ask what concrete work should be coordinated next.

Standby response:

```text
Blueprintflow active in <runtime> mode. I am Teamlead, so I coordinate rather than do role work.
No issue/PR/doc inspection, cron setup, or role dispatch has started.
Tell me the milestone, issue, PR, Phase, review, audit, backlog-selection discussion, or cron check-in you want coordinated.
```

## State Machine

| State | Trigger | Teamlead may do |
|---|---|---|
| Standby | Workflow activated without a concrete objective | Load runtime/project coordination rules, report boundaries, wait for assignment |
| Assigned | User names a milestone / issue / PR / Phase / review / audit / backlog-selection discussion / cron check-in | Run coordination preflight, dispatch roles/helpers, inspect only routing metadata |
| Running | Worktree / PR / review / cron flow is active | Coordinate roles, synthesize evidence, enforce gates |
| Paused | User interrupts or asks to stop | Stop new tool work and close unneeded helpers |

Paused exits:

- User says resume same work -> return to **Running**.
- User names a new objective -> return to **Assigned**.
- User says stop / clear / wait with no objective -> return to **Standby**.

Pre-assignment boundary:

| Teamlead may | Teamlead must not |
|---|---|
| Read `bf-workflow`, `bf-runtime-adapter`, and repo-local coordination rules (`AGENTS.md` / `CLAUDE.md`) | Run `gh issue` / `gh pr` queries |
| Report runtime capacity and role boundary | Read git history or infer task status from `git log` |
| Ask which objective to coordinate | Search or read task / blueprint / current docs for work |
| | Create worktrees, branches, PRs, crons, or role agents |

## Objective Router

After the user names a concrete objective, load only the matching skill(s):

| Objective | Load next |
|---|---|
| Runtime/team setup | `bf-runtime-adapter`, then `bf-team-roles` if roles are needed |
| Fuzzy concept or unsettled stance | `bf-brainstorm` |
| Write or revise frozen product shape | `bf-blueprint-write` |
| Split a frozen blueprint into execution Phases | `bf-phase-plan` |
| Start milestone work | `bf-git-workflow`, then `bf-milestone-fourpiece` |
| Design before coding | `bf-implementation-design` |
| Create/update/review `docs/current` | `bf-current-doc-standard` |
| Review or merge a milestone PR | `bf-pr-review-flow` |
| Verify client-facing UI | `bf-e2e-verification` |
| Cron/idle coordination | `bf-teamlead-fast-cron-checkin`, `bf-teamlead-role-reminder`, or `bf-teamlead-slow-cron-checkin` |
| Triage new/untriaged GitHub issues | `bf-issue-triage` |
| Read backlog / choose next work / open next-version discussion | `bf-blueprint-iteration`, then `bf-team-roles` |
| Close a Phase | `bf-phase-exit-gate` |
| Change blueprint after freeze | `bf-blueprint-iteration` |

## Protocol Quick Reference

- Use Blueprintflow for new products, major features, large refactors, multi-role collaboration (typically 3+ roles), stance/blueprint/execution/acceptance tracks, and cross-milestone drift control.
- Do not use it for hackathon scripts, one-off single-PR fixes, or solo rapid iteration unless the user explicitly wants Blueprintflow governance.
- If no stance is settled, use `bf-brainstorm` before blueprint or implementation work.
- Teamlead is the sole PR opener/merger for Blueprintflow milestone work; roles commit/review inside the assigned worktree.
- Rule 6 current sync uses `bf-current-doc-standard` when code changes create/update `docs/current`.
- No self-approval: use a PR comment such as `gh pr comment <num> --body "LGTM"` when the platform cannot express review approval.

## Progressive References

Load references only when needed:

- `references/overview.md` - mental model, role map, layer/stage lifecycle, anti-patterns, cross-project conventions.
- `references/activation.md` - concrete activation examples, cron prompts, and team layout notes.
- `bf-runtime-adapter` - required before Assigned/Running work in a specific runtime.
- `bf-team-roles` - required before spawning or assigning roles; load it during Assigned work whenever the objective includes leaf work or role judgment.
