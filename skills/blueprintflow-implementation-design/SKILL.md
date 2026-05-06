---
name: blueprintflow-implementation-design
description: "Part of the Blueprintflow methodology. Dev writes an implementation design (data flow, API contract, edge cases, alternatives) after the four-piece set is ready but before coding. Four roles must approve before code starts. Lives in the same milestone PR. Use for code milestones, refactors, cross-module changes. Don't use for docs-only milestones, typos, or hotfixes."
version: 1.0.0
---

# Implementation Design

After the milestone four-piece set and before touching code, the **Dev is the primary author** of an implementation design document. Architect / PM / Security / QA review it, and only when all four sign off ✅ does coding start.

## Why this step exists

The four-piece set (spec / stance / acceptance / content lock) locks **"what to do / what not to do"** at the product-stance level — it doesn't lock the implementation path.

Going straight into code commonly produces:
- Data flow not thought through; halfway in you discover the interface shape is wrong and have to redo it
- No comparison of alternatives; you pick the first thing that came to mind and later regret the performance / maintainability
- Edge cases + error handling surface only while writing code (collisions inside the implementation PR)
- Security / permission paths missed during review (admin god-mode / cross-org / cookie domain)
- Integration points with existing code aren't reverse-grepped, leading to a pile of mismatches at integration time

This step pulls those forward. Four roles review and pass before any code is touched.

## Anti ivory-tower stance (user's call)

The design **is not pulled forward** before the four-piece set, nor to the start of the milestone.

- Four-piece set lands first (product stance locked + breakdown + acceptance + content lock)
- Design comes after (built on the locked stance, lays out the implementation path)
- Design review passes → coding starts

If design is pulled forward, it tends to drift away from product stance into ivory-tower architecture — that's the anti-pattern this avoids.

## Triggers

- ✅ **Required for any milestone that touches code** (any change to schema / server / client)
- ✅ Important refactor / cross-module change
- ❌ Non-code milestones can skip:
  - docs-only (blueprint wording / spec brief patch)
  - config-only (env / CI threshold tweaks)
  - wording adjustment (content lock byte-identical fixes)

If unsure → run the design step (the burden of proof is on the "we can skip it" side).

## Author: Dev is the primary author

Not the Architect, not the PM. Dev writes it — because Dev is the one who'll work from this document.

The Architect's role at the architecture gate is during review, not as ghostwriter.

## Output

**Path**: `docs/implementation/design/<milestone>.md`

**Length**: **no fixed length** — long enough to reflect the implementation, no longer.

Anti-constraints:
- ❌ Don't pad for length (write what's needed and stop, no filler)
- ❌ Don't skip key design (data flow / multi-option comparison / edge cases must be there)
- ❌ **No real code** — pseudocode at most (anti the "copy-paste future code" anti-pattern; real code lives in the implementation commits)

## Suggested structure (not enforced — tailor to the milestone)

### §1 Data flow

Sequence diagram / call graph (text or mermaid both fine).

Answers: user action → which components → which APIs → which DB tables → which side effects.

### §2 Data model

Schema change / migration ground truth.

- New / modified tables / fields (with types + constraints + indexes)
- Migration version
- Compatibility with existing schema (dual-write during rolling deploy? field nullable?)

### §3 API contract

Path + shape + status code, **byte-identical alignment between client and server** (intent).

- Request shape (path / method / body schema / query param)
- Response shape (success / error envelope)
- Error code list (not just "fail → 500")

### §4 Edge cases + error handling

- Empty / null / oversized input
- Concurrency (real race condition paths)
- Partial failure (transaction rollback / retry semantics)
- User-state edges (not logged in / token expired / insufficient permission)

### §5 Multiple options

**≥2 candidate options + which one is chosen + the real reason**.

You can't write a single option as "the only option". Even if the final choice is obviously better, the rejected options + reasons for rejection have to be written down so reviewers have something to push back on.

Format suggestion:
- Option A: <one line> | Pro: ... | Con: ...
- Option B: <one line> | Pro: ... | Con: ...
- **Pick A**, real reason: ...

**Exception**: if there really is only one viable option, write down the real reasons the others don't work (e.g. a schema migration adding a single field has no parallel option / a unique solution forced by performance, compat, or compliance constraints / an upstream API only exposes one endpoint). The exception is anti hand-wavy filler options (writing two near-equivalent options so one obviously loses is filler, not real selection). The exception clause doesn't relax the rule: you have to actually write "why are there no other options"; "I only thought of this one" is not accepted.

### §6 Integration with existing code

Reverse-grep interface anchors:
- Which existing functions are called / which components are reused (list specific paths)
- Where existing-code assumptions clash with the new design (e.g. existing schema doesn't allow null but the new design needs it; how to handle)
- Reverse impact: changing module A — who is affected (list dependencies)

## Four-role review (all ✅ blocks coding from starting)

| Role | Review angle |
|------|-------------|
| **Architect** | ① Stance carryover (no drift from blueprint §X.Y) ② **Is the architecture right and reasonable** (the new core responsibility added here) — data flow abstraction levels / multi-option choice rationale / consistency with existing architecture |
| **PM** | User value really delivered + content/UX (literal text in the design doc lines up with the content lock) |
| **Security** | All code changes must be reviewed — auth / capability / data isolation / cookie domain / admin god-mode / cross-org paths |
| **QA** | Testability + edge cases complete (cases listed in §4 line up 1:1 with the acceptance template) |

> **Architect review covers more than stance**: previously the Architect was only responsible for stance carryover; in the design review the **architectural reasonableness** responsibility is added — data flow abstraction / multi-option choice / cross-module boundaries. Stance gatekeeping ≠ architecture gatekeeping; both have to happen.

> **Security must be a separate role; the Architect cannot double-hat**: see `blueprintflow-team-roles`. The security lens and the architecture lens are independent dimensions; merging them silences both sides.

### Review protocol

- Any one ❌ blocks (Dev cannot touch code)
- ≥3 review rounds and still not passing → escalate to Teamlead + user decision (anti-deadlock)
- Reviews go through PR comments / the team's communication channel (per runtime-adapter); no separate PR is opened

## PR protocol (user's iron rule)

The design doc **is not a separate PR**. The "one milestone, one PR" iron rule is strict.

- The design doc + four-piece set + implementation + e2e + REG flip + acceptance + PROGRESS [x] **all live in the same PR**
- Order inside the worktree:
  1. Four-piece set (Architect / PM / QA in parallel)
  2. Design doc (Dev primary)
  3. Four-role review pass
  4. Implementation code (Dev, three sections)
  5. e2e
  6. Closure (REG flip / acceptance ⚪→✅ / PROGRESS [x])
  7. Teamlead opens the PR (only the Teamlead opens it)

The review stage happens inside the worktree through communication / comments — **not by opening a PR to gather review**.

## Anti-patterns

- ❌ Dev designing while writing (design comes first, before code)
- ❌ Treating the design doc as box-ticking paperwork (the four roles really push back, no padding)
- ❌ Architect reviewing only stance and not architectural reasonableness (both have to happen)
- ❌ Letting the Architect double-hat as Security (must be a separate role; see team-roles)
- ❌ Design doc as a separate PR (violates the "one milestone, one PR" iron rule)
- ❌ Real code in the design doc (use pseudocode; anti "copy-paste future code")
- ❌ Multiple options with only one written + no real reason (mandatory ≥2 + reason for rejection; for true single-solution cases, use the exception clause and write "why no other options")
- ❌ Design pulled forward before the four-piece set (ivory tower; loses product stance grounding)
- ❌ Forcing design on non-code milestones (docs-only / config-only skip)

## How to invoke

Once a milestone's four-piece set is ready:

```
follow skill blueprintflow-implementation-design
dispatch Dev to write docs/implementation/design/<milestone>.md
dispatch Architect/PM/Security/QA for the four-role review
all ✅ → coding starts
```
