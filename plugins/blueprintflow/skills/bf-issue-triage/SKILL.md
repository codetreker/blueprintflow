---
name: bf-issue-triage
description: "Part of the Blueprintflow methodology. Use on issue-triage cron ticks or when new untriaged GitHub issues need routing into Blueprintflow work."
---

# Issue Triage

3-hour recurring cron. Runtime syntax → `bf-runtime-adapter`.

## How to invoke

Cron:
```
[issue triage · 3h]
follow skill bf-issue-triage
```

Inline (new issue arrives outside cron):
```
new issue gh#NNN arrived → follow skill bf-issue-triage
```

## Execution

Read `references/execution.md` — covers native issue type field usage, Teamlead routing table, scan scope, triaged label, user review queue, walkthrough example, downstream state machine, and anti-patterns.
