---
name: blueprintflow-issue-triage
description: "Part of the Blueprintflow methodology. Use on cron tick or when new untriaged GitHub issues arrive - Teamlead routes each to Architect/PM/QA, who set the issue's native type field + apply status/triaged labels as the entry gate to blueprint iteration."
---

# Issue Triage

3-hour recurring cron. The exact command depends on your runtime — see `blueprintflow-runtime-adapter` for the concrete syntax.

## How to invoke

Cron prompt:
```
[issue triage · 3h]
follow skill blueprintflow-issue-triage
```

Inline trigger (when a new issue arrives outside the cron cycle):
```
new issue gh#NNN arrived
follow skill blueprintflow-issue-triage
Teamlead decides → route → role classifies → set native type + apply triaged
```

## What to do when this cron fires

Read `references/execution.md` for the full execution logic: native issue type field usage, Teamlead routing table, scan scope, triaged label, user review queue, walkthrough example, downstream state machine, and anti-patterns.
