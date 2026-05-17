---
name: bf
version: 0.1.0-alpha
description: "Blueprintflow — general evidence-gated work loop framework. Moves Work Objects from raw input through brainstorm → breakdown → loop → close via mechanical gates and independent review. Use when starting any non-trivial work that needs structured progress tracking with evidence, not just LLM consensus."
---

# bf — Blueprintflow

> **Status: v0.1.0-alpha.** Core contracts (5) and runtime are in place
> (Stage 1+2 of the fork plan). The full dispatcher logic (task inference,
> Pack selection, flow execution) lands in Stage 4. This SKILL.md is the
> bare-skill entry; full execution behavior is a placeholder for now.

## What this skill is

BF is a general work-loop framework: it moves **Work Objects** (bounded
pieces of uncertain work) through state transitions using **flows**
(directed graphs of typed nodes) gated by **mechanical evidence checks**
(no LLM-only consensus).

The skill is one user-facing entry. Behind it sits:

- A vendored harness (CLI: `bf-harness`) that executes the flow graph,
  validates handshakes, computes gate verdicts mechanically, and detects
  oscillation / cycle limits.
- Five Core contracts: Work Object, Flow, Gate, WO Home, Pack. See
  [`references/`](references/) for each one's full definition.
- A roles library (21 specialist agent prompts inherited from OPC).
- A protocols library (empty in v0.1; Stage 3 vendors Core node protocols).
- A Pack directory for domain-specific instantiation (product-engineering
  Pack lands in Stage 3).

## When to use

- Starting any non-trivial work (≥3 distinct decisions, ≥1 review needed)
- Need structured progress tracking that survives session restarts
- Want mechanical evidence gates rather than LLM-only "looks good"
- Multi-agent collaboration with independent verification

**Not for:**
- Trivial one-shot tasks (bug fixes, single function tweaks) — use plain Claude
- Pure conversation / brainstorming — use [brainstorming](https://docs.anthropic.com/skills) or similar
- Already-running OPC flow (we're a fork, not a peer)

## How to invoke (v0.1.0-alpha)

```
/bf <task description>
```

In v0.1.0-alpha this prints a status message and pointers. The dispatcher
implementation lives at `bin/bf.mjs` and is intentionally a stub until
Stage 4.

The runtime harness is **fully functional** today:

```bash
bf-harness --help
bf-harness init --flow build-verify --entry build --dir .bf/run-1
bf-harness transition --from build --to code-review --verdict PASS \
  --flow build-verify --dir .bf/run-1
```

See `bin/bf-harness.mjs --help` for the complete CLI.

## How BF is laid out

```
bf/
├── SKILL.md           ← this file
├── bin/
│   ├── bf.mjs         ← dispatcher (Stage 4)
│   ├── bf-harness.mjs ← runtime CLI (fully functional)
│   └── lib/           ← 40 mjs modules (vendored from OPC)
├── pipeline/          ← Core node protocols (Stage 3)
├── roles/             ← 21 role prompts (Stage 3 sorts Core vs Pack)
├── packs/             ← embedded domain Packs (Stage 3+)
├── references/        ← 5 Core contract docs
├── test/              ← harness test suite (108 / 0 / 1)
├── scripts/           ← postinstall
└── UPSTREAM.md        ← OPC fork provenance
```

## See also

For full design rationale: `docs/specs/2026-05-16-bf-fork-design.md`
(in the source repo; not bundled in the npm package).

For Core contract details: `references/work-object.md`, `flow.md`,
`gate.md`, `wo-home.md`, `pack.md`, plus [`references/README.md`](references/README.md)
as the reading-order index.

For acceptance judgement model (criteria-lint + review + execute + gate):
`docs/specs/2026-05-16-bf-fork-design/acceptance-judgement.md`.

## Status

| Stage | What | Done? |
|---|---|---|
| 1 | Vendor + brand-rename OPC harness | ✅ |
| 2 | Author 5 Core contract docs | ✅ |
| 3 | First Pack (product-engineering) + protocol library | pending |
| 4 | Live dispatcher (`/bf <task>` actually runs flows) | pending |
| 5 | End-to-end demo flow | pending |
| 6 | v6 → v1 migration guide | pending |
