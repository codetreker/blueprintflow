---
name: bf-blueprint-write
description: "Part of the Blueprintflow methodology. Use when brainstorm has converged stances, a product-shape source of truth is needed, or a new blueprint module chapter is starting."
---

# Blueprint Write

`docs/blueprint/next/*.md` = source of truth for product shape that is planned, locked, or in progress. Every task PR cites a §X.Y anchor here. `docs/blueprint/current/*.md` is reserved for implemented-and-accepted product truth.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Blueprint structure

| File | Content |
|---|---|
| `README.md` | Core stance list (10-15 stances, most authoritative) |
| `concept-model.md` | First-class concepts + relationships |
| `<module>.md` | Product shape per module (e.g. admin-model, channel-model, auth-permissions) |
| `onboarding-journey.md` | User's first-time journey |

## Single-blueprint template

```markdown
# <Module Name> (product shape)

## §1 Core concepts
### §1.1 <concept>
One-sentence definition + relationship to other concepts + constraint (X is, Y isn't).

## §2 Invariants / red lines
5-10 product-level red lines no execution can violate.

## §3 v0/v1 boundary
- v0 (no external users): free to drop DB / swap protocols
- v1 (first external user): forward-only schema / backups / gradual rollout

## §4 Constraints (kept for v2+)
What is explicitly not in v1's scope.

## §5 Acceptance hooks
How this connects to acceptance template / stance checklist (with anchors).
```

## Stances

Each stance = one sentence + constraint + key scenario.

**Validity test**: if you can't write "X is, Y isn't" for a stance, it's not a stance — it's a platitude.

Every stance must produce 5-7 reverse-check items (used by `bf-milestone-fourpiece` stance checklist).

## Process

| Step | Action |
|---|---|
| 1. Concept discussion | Paired with `bf-brainstorm`. Lock 1-2 concepts/stances per round |
| 2. Write next-blueprint PR | Architect + PM write `docs/blueprint/next/<module>.md` and update `docs/blueprint/next/README.md` anchors/status. Dev + QA review too — stances must be accepted by all roles |
| 3. Core stance list | Distill 10-15 core stances into `docs/blueprint/next/README.md`, mark ⭐ important ones |
| 4. Next anchor lock | Approved anchors in `docs/blueprint/next/README.md` move to `LOCKED`; later changes require PR + four-role review and affected tasks rechecked |

## Anti-patterns

- ❌ Abstract platitudes as stances (no constraint = not a stance)
- ❌ Skipping reverse-check table (drift escapes acceptance)
- ❌ Starting task implementation before the next anchor is `LOCKED`
- ❌ Moving not-yet-accepted work into `docs/blueprint/current/`
- ❌ Non-standard §X.Y anchors (grep can't find them)

## How to invoke

```
follow skill bf-blueprint-write
```
