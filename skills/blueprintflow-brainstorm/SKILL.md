---
name: blueprintflow-brainstorm
description: "Part of the Blueprintflow methodology. Multi-round Architect + PM + Teamlead discussion that converges a fuzzy idea into core stances, concept model, and constraints for the blueprint. Use when starting a new product/module, stances conflict, or a major blueprint rewrite is needed. Don't use for mechanical PRs, small patches, hotfixes, or milestone-splitting."
---

# Brainstorm

Converge a fuzzy idea into core stances, concept model, and constraints. Teamlead facilitates, PM + Architect drive (Designer or Security pulled in as needed). Usually 5-15 rounds; each locks 1-2 concepts.

## When to use / not use

| Use | Don't use |
|---|---|
| New product starting up (→ `blueprintflow-blueprint-write`) | Implementation choices (SQLite vs Postgres → spec brief) |
| New module added to existing product | Milestone with stance already locked (→ `blueprintflow-milestone-fourpiece`) |
| Existing stances in conflict | Mechanical PRs, small patches, hotfixes |
| Major blueprint rewrite | — |

## Multi-round structure

| Round | Focus | Output |
|---|---|---|
| **1: Scope** | Q1: first-class concepts (≤3)? Q2: relation to existing concepts? Q3: what's NOT in this module? | PM + Architect each answer ≤200 words |
| **2-N: Stance debate** | Pick 1-2 stances per round. Can you write "X is, Y isn't"? Conflicts? v0/v1 boundaries? | ≤5-line stance draft per round |
| **Final: Freeze** | Teamlead summarizes 5-7 stances + constraints | PM + Architect sign off → `blueprintflow-blueprint-write` |

## Teamlead facilitation

| Principle | Detail |
|---|---|
| Don't answer for others | Assign to PM/Architect, only arbitrate (conflict? v0/v1 clear? constraint writable?) |
| Push toward closure | Every round produces ≤5-line stance draft. "Wait for more info" = not allowed |
| Converge to 5-7 | Too many stances → unmemorable, execution drifts. 10-15 = product total; 5-7 per module |

## Stance format (hard rule)

Each stance must contain:

| Element | Requirement |
|---|---|
| Claim | ≤30 words, something a user could repeat |
| Constraint | "X is, Y isn't" — prevents drift |
| Key scenario | A demo example you can actually run |
| v0/v1 boundary | What's done now, what's left for later |

**Worked example** — "silence beats fake loading":
- Claim: don't show spinner / progress bar / "thinking..."
- Constraint: UI stays still while agent processes; only show result when done
- Scenario: agent edits artifact, user sees no intermediate state until commit
- v0: fully silent; v1 may add "thinking" hint (still no fake progress)

## Anti-patterns

- ❌ Locking all stances in round 1 (no convergence, drags)
- ❌ Teamlead answering PM's user-side stance (no real perspective)
- ❌ Round produces no stance draft (just talk)
- ❌ Abstract platitudes (can't write constraint → redo round)
- ❌ Implementation details hijacking discussion (Teamlead cuts it off)

## Output checklist

- [ ] All 5-7 stances have claim + constraint + scenario + v0/v1
- [ ] Constraints machine-checkable (reverse grep / assertion)
- [ ] PM + Architect signed off
- [ ] Handed off to `blueprintflow-blueprint-write`

## How to invoke

```
follow skill blueprintflow-brainstorm
```
