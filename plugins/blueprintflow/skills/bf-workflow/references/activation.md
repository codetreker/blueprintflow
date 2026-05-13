# Activation Details

Read this only after `bf-workflow` is Assigned/Running or when the user asks how activation/check-ins should work.

## Bare activation

Bare activation means the user invokes `bf-workflow` or asks to activate Blueprintflow without naming a milestone, issue, PR, Phase, review, audit, or cron check-in. It is standby only.

Expected response:

```text
Blueprintflow active in <runtime> mode. I am Teamlead, so I coordinate rather than do role work.
No issue/PR/doc inspection, cron setup, or role dispatch has started.
Tell me the milestone, issue, PR, Phase, review, audit, or cron check-in you want coordinated.
```

## Concrete objective bootstrap

After a concrete objective is assigned, use this order as applicable:

```text
0. bf-runtime-adapter    - confirm environment
1. bf-team-roles         - spawn/assign roles when needed
2. bf-brainstorm         - lock stances
3. bf-blueprint-write    - write blueprint
4. bf-phase-plan         - split into Phases
5. (loop) bf-milestone-fourpiece + bf-pr-review-flow + bf-teamlead-fast-cron-checkin
6. (periodic) bf-teamlead-role-reminder + bf-teamlead-slow-cron-checkin + bf-issue-triage
7. (Phase wrap-up) bf-phase-exit-gate
```

## Cron protocol

Start crons only after the workflow is **Assigned** or **Running** and the user has agreed to ongoing coordination.

| Cron | Frequency | Prompt |
|---|---|---|
| fast-cron | 15 min | `[auto check-in · 15 min] follow skill bf-teamlead-fast-cron-checkin` |
| role-reminder | 30 min | see `bf-teamlead-role-reminder` SKILL.md for the `<system reminder>` block |
| slow-cron | 2 h | `[drift audit · 2 hours] follow skill bf-teamlead-slow-cron-checkin` |
| issue-triage | 3 h | `[issue triage · 3h] follow skill bf-issue-triage` |

Without crons, agents go idle. Crons stop automatically when the session ends; explicitly remove them to pause.

Anti-patterns:

- Starting only some crons, letting drift/issues accumulate.
- Cron prompt missing the skill name, causing uncontrolled behavior.
- Persistent crons without user signoff, leaking across projects.

## Team layout principle

Regardless of runtime: Teamlead gets the widest view (coordination thread), roles are visible at a glance, every pane/window is named. Concrete layout commands depend on the runtime; use `bf-runtime-adapter`.
