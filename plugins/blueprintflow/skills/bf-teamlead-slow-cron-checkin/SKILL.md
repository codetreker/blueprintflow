---
name: bf-teamlead-slow-cron-checkin
description: "Part of the Blueprintflow methodology. Use on slow-cron ticks or when blueprint, current-doc, acceptance, PR, issue, or worktree drift signals appear."
---

# Teamlead Slow-Cron Check-in

2-4 hour recurring cron. Runtime syntax → `bf-runtime-adapter`.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## How to invoke

```
[drift audit · 2 hours]
follow skill bf-teamlead-slow-cron-checkin
```

## Execution

Read `references/execution.md` — covers 6 audit categories (PROGRESS accuracy, blueprint drift, docs/current sync, delayed flips, open-PR task completion, triaged-no-type queue), output format, and anti-patterns.
