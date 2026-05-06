---
name: blueprintflow-brainstorm
description: "Part of the Blueprintflow methodology. Multi-round Architect + PM + Teamlead discussion that converges a fuzzy idea into core stances, concept model, and constraints for the blueprint. Use when starting a new product/module, stances conflict, or a major blueprint rewrite is needed. Don't use for mechanical PRs, small patches, hotfixes, or milestone-splitting."
version: 1.1.0
---

# Brainstorm

Take a fuzzy product idea and converge it into the core stances, concept model, and constraints a blueprint can be built on. Teamlead facilitates, PM and Architect drive the discussion (with Designer or Security pulled in as needed). Usually 5-15 rounds; each round locks down one or two concepts.

> **Real example (Borgee):** Ran 11 rounds of brainstorm and locked 14 core stances.

## When to use

- A new product is starting up (paired with `blueprintflow:blueprint-write`)
- A new module is being added (e.g. adding a conversation module to an existing product)
- Existing stances are in conflict (execution exposed that the stance was never really settled)
- A major blueprint change (always go through brainstorm before a big rewrite)

## When not to use

- Implementation-level technical choices (e.g. SQLite vs Postgres) — that belongs in the spec brief, not in brainstorm
- A milestone whose stance is already locked (use `blueprintflow:milestone-fourpiece`)

## Multi-round structure

### Round 1: scope

Teamlead poses three questions. PM and Architect each answer in ≤200 words:

- Q1: What are the **first-class concepts** of this module? (≤3)
- Q2: How do they relate to existing concepts (org / agent / channel)?
- Q3: Reverse boundary — what is **not** part of this module?

### Rounds 2-N: stance debate

Each round picks one or two concrete stances and works them through. PM brings the user perspective, Architect brings feasibility, Teamlead arbitrates:

- Is stance X clearly written? (Can you write a "X is, Y isn't" constraint?)
- Does it conflict with another stance? Which one wins?
- Are the v0 / v1 boundaries clearly nailed down?

Each round produces a stance draft of ≤5 lines, which becomes the baseline for the next round.

### Final round: stance freeze

Teamlead summarizes 5-7 stances and their constraints. PM and Architect both sign off, then it goes into `blueprintflow:blueprint-write` to be written down.

## Teamlead facilitation principles

### Don't answer for others

- Assign the work to PM and Architect; only arbitrate
- Arbitration criteria: does this conflict with existing stances? Are v0/v1 boundaries clear? Can a constraint actually be written?

### Push toward closure

- Every round must produce a ≤5-line stance draft (if it can't be written, the stance doesn't exist — fail the round)
- No "let's wait for more information" stalling (information will never be enough — make the call)

### Converge to 5-7 stances

- Don't expand without limit (too many stances are unmemorable, execution drifts)
- 10-15 stances is product-level total; for a single module 5-7 is enough

## How to write a stance (hard rule)

Each stance must contain:

- **A one-sentence claim** (≤30 words, something a user could repeat)
- **A constraint** (X is, Y isn't, to prevent drift)
- **A key scenario** (a demo example you can actually run)
- **v0/v1 boundary** (what's done now, what's left for later)

> **Stance example (silence beats fake loading):**
> - Claim: don't show spinner / progress bar / "thinking..."
> - Constraint: while the agent is processing the UI stays still, no fake progress; only show the result when it's actually done
> - Scenario: agent edits an artifact, the user sees no intermediate state until commit
> - v0: fully silent; v1 may consider a "thinking" subject hint based on user feedback (still no fake progress)

## Anti-patterns in multi-round discussion

- ❌ Trying to lock all stances in round 1 (no convergence, drags forever)
- ❌ Teamlead answering the user-side stance for PM (no real user perspective, execution drifts)
- ❌ Producing no stance draft in a round (just talk)
- ❌ Stances written as abstract platitudes (if you can't write a constraint, redo the round)
- ❌ Implementation details hijacking the discussion (e.g. SQLite vs Postgres) — Teamlead must cut it off and pull back to stance

## Output checklist

When brainstorm wraps up:

- [ ] All 5-7 stances have "claim + constraint + scenario + v0/v1 boundary"
- [ ] Constraints can be checked by machine (reverse grep / reverse assertion)
- [ ] PM and Architect both signed off
- [ ] Hand off to `blueprintflow:blueprint-write` to write the blueprint

## How to invoke

For a new module or new stance:

```
follow skill blueprintflow-brainstorm
start multi-round discussion (Teamlead + PM + Architect)
```

When the discussion converges, hand off to `blueprintflow:blueprint-write`.
