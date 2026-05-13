---
name: bf-blueprint-write
description: "Part of the Blueprintflow methodology. Use when brainstorm has converged stances, a product-shape source of truth is needed, or a new blueprint module chapter is starting."
---

# Blueprint Write

`docs/blueprint/*.md` = source of truth for product shape. Every later PR cites a §X.Y anchor here. Once frozen, execution follows the blueprint.

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
| 2. Write blueprint PR | Architect + PM write `docs/blueprint/<module>.md`. Dev + QA review too — stances must be accepted by all roles |
| 3. Core stance list | Distill 10-15 core stances into `README.md`, mark ⭐ important ones |
| 4. Blueprint freeze | Post-freeze changes require PR + four-role review. Reasons in changelog, affected milestones rechecked |

## Anti-patterns

- ❌ Abstract platitudes as stances (no constraint = not a stance)
- ❌ Skipping reverse-check table (drift escapes acceptance)
- ❌ Never freezing the blueprint (execution keeps shifting)
- ❌ Non-standard §X.Y anchors (grep can't find them)

## How to invoke

```
follow skill bf-blueprint-write
```
