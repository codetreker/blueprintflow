# BF Core Contracts

This directory holds the five canonical BF Core contracts. Read in order:

1. [work-object.md](./work-object.md) — the primary citizen (what)
2. [flow.md](./flow.md) — how a Work Object advances (also documents Artifact as a sub-contract)
3. [gate.md](./gate.md) — how PASS / ITERATE / FAIL is decided
4. [wo-home.md](./wo-home.md) — where a Work Object lives on disk
5. [pack.md](./pack.md) — domain-specific instantiation

For the **design rationale** behind these contracts — including the 10 BF axioms,
the Core / Pack layering principles, and the four-step core loop —
see `../../../docs/specs/2026-05-16-bf-fork-design/layering-principles.md`.

For **how acceptance is judged** (criteria-lint + review + execute + gate),
see `../../../docs/specs/2026-05-16-bf-fork-design/acceptance-judgement.md`.

For the **command surface** (`bf-run` verbs), see
`../../../docs/specs/2026-05-16-bf-fork-design/bf-run-commands.md`.

## Source-of-truth note

These five docs are derived from the design spec at
`../../../docs/specs/2026-05-16-bf-fork-design/core-contracts.md`. The spec
is the canonical source until v1 ships; after v1, this directory becomes
canonical and the spec is archived.
