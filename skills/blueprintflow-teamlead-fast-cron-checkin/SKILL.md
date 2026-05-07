---
name: blueprintflow-teamlead-fast-cron-checkin
description: "Part of the Blueprintflow methodology. Use on 15-min cron tick or when a role goes idle - Teamlead dispatches idle roles, clears stuck PRs, and runs the three-signoff merge gate."
---

# Teamlead fast-cron check-in

15-minute recurring cron. The exact command depends on your runtime — see `blueprintflow-runtime-adapter` for the concrete syntax.

**Cron prompt template:**
```
[auto check-in · 15 min]
follow skill blueprintflow-teamlead-fast-cron-checkin
```

**Companion crons (all must be running):**
- `blueprintflow-teamlead-role-reminder` — 30 min, Teamlead self-check
- `blueprintflow-teamlead-slow-cron-checkin` — 2-4 h, blueprint drift audit
- `blueprintflow-issue-triage` — 3 h, GitHub issue scan

**Stopping:** when the workflow session ends, crons stop automatically. To pause (e.g. during brainstorm), explicitly remove the cron.

## What to do when this cron fires

Read `references/execution.md` for the full execution logic: core rules, dispatch priority, current-iteration issue scan, merge gate, PR BLOCKED routing, and anti-patterns.
