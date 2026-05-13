---
name: bf-implementation-design
description: "Part of the Blueprintflow methodology. Use when the milestone four-piece is in place, code has not started, and a code-facing implementation design needs review."
---

# Implementation Design

After the four-piece set, before code: **Dev writes the implementation design**, four roles review, all ✅ then coding starts.

**Why**: four-piece locks "what" (stance); this locks "how" (data flow, contracts, edge cases). Skipping → wrong interfaces, missed edge cases, integration mismatches discovered mid-implementation.

**Anti ivory-tower**: design comes **after** four-piece, not before. Four-piece grounds it in product stance.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Triggers

| Applies | Skip |
|---|---|
| Any milestone touching code (schema / server / client) | Docs-only, config-only, wording adjustments |
| Important refactor / cross-module change | — |

If unsure → run it (burden of proof on "we can skip").

## Author

Dev is the primary author (they'll work from it). Architect reviews, doesn't ghostwrite.

## Output

**Path**: milestone's leaf folder as `design.md`. **Length**: no fixed limit — long enough to reflect the implementation.

- ❌ No padding for length
- ❌ No skipping key design (data flow / alternatives / edge cases)
- ❌ No real code — pseudocode at most

## Suggested structure

| Section | What it covers |
|---|---|
| §1 Data flow | Sequence diagram / call graph: user action → components → APIs → DB → side effects |
| §2 Data model | New/modified tables + fields + types + constraints + migration version + compatibility |
| §3 API contract | Path + shape + status codes, byte-identical alignment between client and server |
| §4 Edge cases | Empty/null/oversized input, concurrency, partial failure, user-state edges |
| §5 Multiple options | ≥2 candidates + chosen + real reason. Single-option exception requires "why no alternatives" |
| §6 Integration | Reverse-grep existing interfaces + clash points + reverse impact (who is affected) |

**Format is flexible** (H2/H3/prose/diagram all fine), but **content is required**: data flow, data model, API contract, edge cases, alternatives, and integration points must all be covered.

## Four-role review

| Role | Review angle |
|---|---|
| **Architect** | Stance carryover (no drift from §X.Y) + **architectural reasonableness** (data flow abstraction, multi-option rationale, cross-module consistency) |
| **PM** | User value delivered + content/UX alignment with content lock |
| **Security** | Auth / capability / data isolation / cookie domain / admin god-mode / cross-org (must be separate role, not Architect) |
| **QA** | Testability + §4 edge cases line up 1:1 with acceptance template |

- Any one ❌ blocks coding
- ≥3 rounds still blocked → escalate to Teamlead + user
- Reviews through PR comments / communication channel, no separate PR

## PR protocol

The design doc is **not a separate PR**. Everything in one milestone PR:
1. Four-piece set → 2. Design doc → 3. Four-role review → 4. Implementation → 5. e2e → 6. Closure → 7. Teamlead opens PR

## Anti-patterns

- ❌ Designing while coding (design first)
- ❌ Design as box-ticking (four roles really push back)
- ❌ Architect reviewing only stance, not architecture (both required)
- ❌ Architect doubling as Security
- ❌ Design doc as separate PR
- ❌ Real code in design doc
- ❌ Single option without "why no alternatives"
- ❌ Design before four-piece set (ivory tower)

## How to invoke

```
follow skill bf-implementation-design
```
