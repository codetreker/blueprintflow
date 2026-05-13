# Iteration lifecycle

```
Current iteration passes acceptance
   ↓
Teamlead reminds the user "next-version discussion can open"
   ↓
User doesn't respond → AGENTS.md reminder-period repeats the reminder
   ↓
User says go
   ↓
Scan GitHub issues with label `backlog` (clean up + pick, move to `next-iteration`) + brainstorm
   ↓
Write docs/blueprint/next/ + migration analysis
   ↓
Four roles + Teamlead/user discuss
   ↓
User signs off (or user authorizes Teamlead to sign off)
   ↓
Freeze:
  - docs/blueprint/next/ → docs/blueprint/current/ replacement
  - Old version gets a git tag (blueprint-vN.M) for history
  - Write docs/blueprint/_meta/<version>/source-issues.md (link issue # that were pulled in; don't list those that weren't; forks can trace back)
  - Issues pulled in change label from `next-iteration` to `current-iteration`, then get assigned milestones for execution
  - Issues kept at `backlog` are untouched (still pending)
  - Create an empty docs/blueprint/next/ to open the entry point for the next-version discussion
```

### source-issues.md trail

At freeze time, list the picked-in issue # in `docs/blueprint/_meta/<version>/source-issues.md`:

```markdown
# Source issues for blueprint vN.M

The issues this version of the blueprint draws from (grouped by topic):

## Module X
- gh#123 — title, one sentence on what this version delivers
- gh#125 — title, one sentence on what this version delivers

## Module Y
- gh#127 — ...
```

Effects:
- Fork users can trace where this version of the blueprint came from (even if the fork can't see upstream issue history, they can see the original numbers and look them up upstream)
- Issues that weren't picked aren't listed (noise — leave them in the GitHub backlog)
- Frozen together with the blueprint version, immutable

### After cutover: trigger a new Phase

When the next-version blueprint becomes the current version (cutover complete, old current archived under git tag), the Architect runs `bf-phase-plan` to split the new blueprint into Phase N+1 (where N is the previous Phase number). The new Phase has its own value loop, exit gate, and milestone list.

This is the only path that creates a new Phase — milestone waves inside an existing blueprint version do not (see `bf-phase-plan` "When to start a new Phase vs add a wave").

### Stuck-milestone safety net

If a single milestone is stuck for ≥2 weeks → Architect + PM evaluate, kick it back to backlog or split it; don't drag the whole iteration.
