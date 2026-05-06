---
name: blueprintflow-blueprint-write
description: "Part of the Blueprintflow methodology. Write brainstorm's converged stances into docs/blueprint/ — the product shape source of truth. Use after brainstorm converges, for first blueprint draft, or adding a module chapter. Don't use if brainstorm isn't settled, for typo patches on frozen blueprints, or stance reversals (use blueprint-iteration)."
version: 1.0.0
---

# Blueprint Write

`docs/blueprint/*.md` is the source of truth for the product's shape. Every later PR has to cite a §X.Y anchor here. Once the blueprint is frozen, execution follows the blueprint, not the other way around.

## Blueprint structure

Under `docs/blueprint/`:

- **README.md** — the core stance list (the most authoritative statement of product stances, usually 10-15)
- **concept-model.md** — first-class concepts (e.g. org / human / agent / channel) and their relationships
- **<module>.md** — the product shape for each module (e.g. admin-model / channel-model / agent-lifecycle / canvas-vision / plugin-protocol / realtime / auth-permissions / data-layer / client-shape)
- **onboarding-journey.md** — the user's first-time journey

> **Real example (Borgee):** 11 blueprint files plus 14 core stances.

## Single-blueprint template

```markdown
# <Module Name> (product shape)

## §1 Core concepts

### §1.1 <first-class concept>
One-sentence definition + how it relates to other concepts + constraint (X is, Y isn't).

### §1.2 ...

## §2 Invariants / red lines

5-10 product-level red lines that no execution can violate:
- Red line 1: ... (constraint spelled out)
- Red line 2: ...

## §3 v0/v1 boundary

### v0 (no external users)
- Free to drop and recreate the database / no backfill / swap protocols
- High freedom on the execution side

### v1 (after the first external user)
- Forward-only schema / backups / gradual rollout
- No more dropping the database

## §4 Constraints (kept for v2+)
Explicit list of what is not in v1's scope (e.g. CRDT / multi-device collaboration / anchor conversation extension)

## §5 Acceptance hooks
How this connects to acceptance template / stance checklist (with anchors)
```

## Core stance examples

Each stance is one sentence + constraint + key scenario:

> **Example (Borgee product):**
> 1. **One organization = one human + multiple agents** (the UI hides the org concept; the user perspective is "me and my agents")
> 2. **An agent represents itself** (not a tool / not the owner's proxy / agent-to-agent collaboration is allowed across boundaries)
> 3. **Silence beats fake loading** (§11 — no spinners, no "thinking...")
> 4. **Workspace + chat as twin pillars** (artifacts don't live inside chat; channel collaboration doesn't bleed into workspace)
> 5. **The product carries no runtime** (§7 — agent runtime is the plugin's own concern; we only attach a process descriptor)
> 6. **Managing metadata is OK; reading your content requires authorization** (§13 — admin god-mode boundary)
> 7-14: ...

Every stance has to be able to produce 5-7 reverse-check items (used by `blueprintflow:milestone-fourpiece` stance checklist).

## A stance you can't write a constraint for is not a stance

Practical check: every stance has to be able to write both directions of "X is, Y isn't".

> **Example (Borgee):**
> - ✅ "An agent represents itself" → constraint: "an agent is not the owner's proxy / agent-to-agent collaboration may cross owners / mentioning an agent ≠ mentioning the owner"
> - ❌ "Good user experience" → no constraint can be written → too vague, not in the blueprint

## Process

### 1. Multi-round concept discussion
Paired with `blueprintflow:brainstorm` — Teamlead facilitates PM and Architect through multiple rounds, locking one or two concepts and stances per round.

### 2. Write the blueprint (PR)
Architect and PM pair up to write `docs/blueprint/<module>.md`. The PR goes through review (Dev and QA participate too — stances must also be accepted by Dev and QA, otherwise execution will drift).

### 3. Core stance list emerges
Once every module blueprint is reviewed, distill the core stances (usually 10-15) into README.md and mark the ⭐ important ones (which acceptance must check later).

### 4. Blueprint freeze
After freeze, changes go through PR + four-role review (same review bar as execution PRs). Reasons go into the changelog, and every affected milestone is rechecked.

## Anti-patterns

- ❌ Stances written as abstract platitudes (if no constraint can be written, the stance doesn't exist)
- ❌ Skipping the reverse-check table and writing only the claim (drift escapes acceptance)
- ❌ Constantly editing the blueprint and never freezing (execution keeps shifting, stances lose focus)
- ❌ Non-standard §X.Y anchors (PRs cite them but grep can't find them)

## How to invoke

After the multi-round concept discussion locks down:

```
follow skill blueprintflow-blueprint-write
write docs/blueprint/<module>.md
```
