---
name: blueprintflow-teamlead-role-reminder
description: "Part of the Blueprintflow methodology. 30-min cron that reminds the Teamlead to re-read their role definition and check if they've drifted from coordinating into doing."
---

# Teamlead Role Reminder

30-minute recurring cron. The exact command depends on your runtime — see `blueprintflow-runtime-adapter` for the concrete syntax.

**Cron prompt template:**
```
[role reminder · 30 min]
follow skill blueprintflow-teamlead-role-reminder
```

## What to do when this cron fires

1. Re-read your role: `blueprintflow-team-roles` → Teamlead section (responsibilities + anti-patterns).
2. Re-read how work flows: `blueprintflow-workflow` → Stage 3 + Stage 4.
3. Ask yourself: **am I coordinating, or have I started doing someone else's work?** If yes → stop and dispatch.
