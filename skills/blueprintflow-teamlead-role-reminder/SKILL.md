---
name: blueprintflow-teamlead-role-reminder
description: "Part of the Blueprintflow methodology. 30-min cron that reminds the Teamlead of their core responsibilities and runs a self-check to catch role drift (doing work instead of coordinating, blocking on subagents, forgetting to broadcast retractions)."
---

# Teamlead Role Reminder

30-minute recurring cron. The exact command depends on your runtime — see `blueprintflow-runtime-adapter` for the concrete syntax.

**Cron prompt template:**
```
[role reminder · 30 min]
follow skill blueprintflow-teamlead-role-reminder
```

## What to do when this cron fires

Read `references/execution.md` for the 5-point self-check: doing others' work, blocking on subagent, forgot to broadcast, merging without reading PR, lost role awareness.
