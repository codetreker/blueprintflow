---
name: blueprintflow-phase-plan
description: "Part of the Blueprintflow methodology. Use when the blueprint is freshly frozen and an execution-plan is needed - breaks it into value-loop Phases (0/1/2/3/4+) with exit gates and milestone lists."
---

# Phase Plan

Once the blueprint is ready, the Architect leads. Break the project into Phases, each anchored to a **value loop** (something an end user can actually use), not to technical layers.

## Preflight check

Before using this skill, read `references/preflight.md` to confirm it applies. The decision graph checks: single-file change? mechanical PR type? team <3? blueprint missing? If any → skip the 4-piece flow.

## Phase vs wave

Not every batch of milestones is a new Phase. Read `references/phase-vs-wave.md` for the rule: **did the blueprint contract change?** Yes → new Phase. No → wave inside existing Phase. Ad-hoc issue → single milestone.

## How to split Phases

Split by **value loop**, not by technical layer:

- ❌ Wrong: Phase 1 schema / Phase 2 server / Phase 3 client (technical layers, no value)
- ✅ Right: Phase 1 identity loop / Phase 2 collaboration loop / Phase 3 second-dimension product / Phase 4+ remaining (each Phase independently demonstrable)

> **Real example (Borgee):** Phase 0 foundation → Phase 1 identity loop → Phase 2 collaboration loop ⭐ → Phase 3 second dimension → Phase 4+ remaining

## Exit gate design

Every Phase needs **machine-checkable** + **user-perceivable** exit conditions:

| Gate type | What it checks | Example |
|---|---|---|
| **Strict** (machine) | Automated assertions | Cookie crosstalk test, throttle unit test, lint pass |
| **User-perceivable** (signoff) | Demo + PM ✅ + screenshot | Flagship milestone demo, real human can use it |
| **Carry-over** (partial OK) | Anchored to Phase N+1 placeholder PR # | Deferred work with a real PR anchor (rule 6) |

## Four drift-prevention gates

Every milestone must have these attached before execution:

| Gate | Owner | What it checks |
|---|---|---|
| 1. Template self-check | Architect | Spec brief uses the template correctly |
| 2. grep §X.Y anchor | Architect | Every milestone cites a blueprint section |
| 3. Reverse-check table | PM + Architect | Stances writable in one sentence; no drift |
| 4. Flagship signoff | PM | Demo + screenshot (AI teams skip video) |

Gates 1+2 in spec brief PR, gate 3 in stance + acceptance, gate 4 at demo signoff.

## Deliverables

**Path**: `docs/tasks/`

- **README.md** — cross-milestone index + Phase overview (updated on every PR merge)
- **00-foundation/** — execution-plan, roadmap, milestone template
- **<milestone-or-issue>/** — one folder per work unit (see `milestone-fourpiece`)

## docs/tasks/README.md template

```
| Phase | Status | Exit condition | Notes |
|-------|--------|----------------|-------|
| Phase 0 foundation | ✅ | G0.x passed | bootstrap |
| Phase 1 identity | ✅ | G1.x passed | milestone-ids |
| Phase 2 collaboration ⭐ | 🔄 | strict N + carry-over anchored | milestone-id ⭐ |
| Phase 3+ | TODO | G3.x + PM signoff | waiting |
```

After every PR merge, update the matching milestone row ⚪→✅ immediately.

## Anti-patterns

- ❌ Splitting by technical layer (no value loop)
- ❌ Exit gates without user perception (machine-only)
- ❌ Carry-over not anchored to a PR # (rule 6)
- ❌ PROGRESS not updated promptly

## How to invoke

```
follow skill blueprintflow-phase-plan
```
