---
name: bf-issue-triage
description: "Part of the Blueprintflow methodology. Use on cron tick or when new untriaged GitHub issues arrive - Teamlead routes each to Architect/PM/QA, who set the issue's native type field + apply status/triaged labels as the entry gate to blueprint iteration."
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
