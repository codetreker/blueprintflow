---
name: blueprintflow-teamlead-slow-cron-checkin
description: "Part of the Blueprintflow methodology. Use on 2-4h cron tick or when drift signals appear - Teamlead audits blueprint drift, docs/current sync, delayed acceptance flips, and stale worktrees."
---

# Teamlead slow-cron check-in

2-4 hour recurring cron. The exact command depends on your runtime — see `blueprintflow-runtime-adapter` for the concrete syntax.

**Cron prompt template:**
```
[drift audit · 2 hours]
follow skill blueprintflow-teamlead-slow-cron-checkin
```

**Companion crons (all must be running):**
- `blueprintflow-teamlead-fast-cron-checkin` — 15 min, idle dispatch + merge gate
- `blueprintflow-teamlead-role-reminder` — 30 min, Teamlead self-check
- `blueprintflow-issue-triage` — 3 h, GitHub issue scan

**Stopping:** same rules as fast-cron.

## What to do when this cron fires

Read `references/execution.md` for the full execution logic: 6 audit categories (PROGRESS accuracy, blueprint drift, docs/current sync, delayed flips, open-PR task completion, triaged-no-type queue), output format, and anti-patterns.
