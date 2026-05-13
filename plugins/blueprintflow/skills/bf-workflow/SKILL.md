---
name: bf-workflow
description: "Part of the Blueprintflow methodology. Use when starting a new product, onboarding a team, or unsure which skill applies - navigates the concept-to-blueprint-to-Phase-to-milestone-to-PR-to-gate lifecycle."
---

# Blueprintflow Workflow

Blueprintflow coordinates multi-agent product work from concept to blueprint to Phase to milestone to PR to gate. The parent agent is **Teamlead**: it coordinates, assigns, and gates; roles execute and review.

## Non-negotiables

- **Bare activation is standby only.** No issue/PR/doc/git/worktree discovery, role dispatch, or cron setup until the user names a concrete objective.
- Blueprintflow controls Blueprintflow-scoped work. Other process skills may run only inside Blueprintflow role and stage boundaries.
- Teamlead dispatches leaf work (context exploration, design, implementation, testing, verification, review) to the appropriate role/helper.
- Security is mandatory and independent; Architect cannot double as Security.
- One milestone = one worktree = one branch = one PR.
- Blueprint freezes before build; changes after freeze go through PR + review.
- No admin bypass merge; CI must really pass.
- Code changes must sync `docs/current` using `bf-current-doc-standard` when the project uses that convention.

If role/helper spawning is unavailable, Teamlead must declare `serial fallback` before doing role-lens work, label each lens explicitly, and record the downgrade.

## Skill composition rule

When Blueprintflow is active, Blueprintflow is the controlling workflow for Blueprintflow-scoped work.

Other implementation/process skills may still be used, but only inside the role and stage boundaries defined by Blueprintflow. If another skill says to explore context, write a design, implement, test, verify, or review:

- Teamlead dispatches that leaf work to the appropriate role/helper.
- Role agents may use the other skill within their assigned scope.
- Teamlead synthesizes role outputs and makes coordination decisions; Teamlead does not perform leaf work directly.
- Security remains independent and cannot be merged into Architect.

If another skill conflicts with Blueprintflow protocol, Blueprintflow wins for Blueprintflow-scoped work.

## Standby Boundary

If the user only invokes `bf-workflow`, says "activate Blueprintflow", or asks to load the workflow without naming a milestone, issue, PR, Phase, review, audit, or cron check-in:

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
Tell me the milestone, issue, PR, Phase, review, audit, or cron check-in you want coordinated.
```

## State Machine

| State | Trigger | Teamlead may do |
|---|---|---|
| Standby | Workflow activated without a concrete objective | Load runtime/project coordination rules, report boundaries, wait for assignment |
| Assigned | User names a milestone / issue / PR / Phase / review / audit / cron check-in | Run the relevant preflight, dispatch roles/helpers, inspect only assigned scope |
| Running | Worktree / PR / review / cron flow is active | Coordinate roles, synthesize evidence, enforce gates |
| Paused | User interrupts or asks to stop | Stop new tool work and close unneeded helpers |

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
| Triage GitHub issues | `bf-issue-triage` |
| Close a Phase | `bf-phase-exit-gate` |
| Change blueprint after freeze | `bf-blueprint-iteration` |
| Edit Blueprintflow skills | `bf-skill-workflow` |

## Protocol Quick Reference

- Use Blueprintflow for new products, major features, large refactors, multi-role collaboration, stance/blueprint/execution/acceptance tracks, and cross-milestone drift control.
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
- `bf-team-roles` - required before spawning or assigning roles.
