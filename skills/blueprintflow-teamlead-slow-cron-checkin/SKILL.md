---
name: blueprintflow-teamlead-slow-cron-checkin
description: "Part of the Blueprintflow methodology. Use on 2-4h cron tick or when drift signals appear - Teamlead audits blueprint drift, docs/current sync, delayed acceptance flips, and stale worktrees."
---

# Teamlead Slow-Cron Check-in

2-4 hour recurring cron. Runtime syntax → `blueprintflow-runtime-adapter`.

## How to invoke

```
[drift audit · 2 hours]
follow skill blueprintflow-teamlead-slow-cron-checkin
```

## Execution

Read `references/execution.md` — covers 6 audit categories (PROGRESS accuracy, blueprint drift, docs/current sync, delayed flips, open-PR task completion, triaged-no-type queue), output format, and anti-patterns.
