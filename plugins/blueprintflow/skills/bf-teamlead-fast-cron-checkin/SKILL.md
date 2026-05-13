---
name: bf-teamlead-fast-cron-checkin
description: "Part of the Blueprintflow methodology. Use on fast-cron ticks, idle-role signals, stuck PRs, or merge-gate check-ins during active Blueprintflow work."
---

# Teamlead Fast-Cron Check-in

15-minute recurring cron. Runtime syntax → `bf-runtime-adapter`.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## How to invoke

```
[auto check-in · 15 min]
follow skill bf-teamlead-fast-cron-checkin
```

## Execution

Read `references/execution.md` — covers dispatch priority, current-iteration issue scan, merge gate, PR BLOCKED routing, and anti-patterns.
