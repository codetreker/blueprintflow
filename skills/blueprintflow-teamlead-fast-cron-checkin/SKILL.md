---
name: blueprintflow-teamlead-fast-cron-checkin
description: "Part of the Blueprintflow methodology. Use on 15-min cron tick or when a role goes idle - Teamlead dispatches idle roles, clears stuck PRs, and runs the three-signoff merge gate."
---

# Teamlead Fast-Cron Check-in

15-minute recurring cron. Runtime syntax → `blueprintflow-runtime-adapter`.

## How to invoke

```
[auto check-in · 15 min]
follow skill blueprintflow-teamlead-fast-cron-checkin
```

## Execution

Read `references/execution.md` — covers dispatch priority, current-iteration issue scan, merge gate, PR BLOCKED routing, and anti-patterns.
