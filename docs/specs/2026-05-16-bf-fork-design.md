# BF Fork OPC — Design Spec

- Date: 2026-05-16
- Status: Draft (awaiting user review)

## Goal

Turn Blueprintflow from a product-engineering plugin into a **general evidence-gated work loop framework**, by narrow-forking OPC's harness execution core and building BF Core (Work Object, Flow, Gate, WO Home, Pack — five contracts) on top. BF Core has exactly **four flow types** — `brainstorm` / `breakdown` / `loop` / `close` — and Work Objects are **recursive directories** (a sub-directory containing `wo.md` is a child WO). BF tracks process, not product — what gets made lives in its natural habitat (git, PR, external doc); BF only asserts product existence via `acceptance_criteria`.

## Background (one paragraph)

Blueprintflow today is one plugin: a product-engineering governance workflow with 20+ skills. The evaluation in §1-17 concluded BF is the first instance of a deeper pattern: **Raw Input → shape to Work Object → produce artifacts → independent verify → gate → advance state → route**. The product-engineering workflow should become one *Pack* of a generalized framework, not the framework's boundary. OPC already has the runtime mechanics this pattern needs (digraph, mechanical gates, oscillation detection, atomic writes, scope coverage); BF should not reinvent them.

## Decisions (confirmed in conversation)

| # | Question | Decision |
|---|---|---|
| D1 | OPC relationship | **Narrow fork** — long-term divergence, no upstream pump after v1 |
| D2 | Fork scope | OPC harness + selective reusable roles. OPC's `skill.md` and product-engineering protocols are NOT taken. |
| D3 | Naming policy | Brand words replaced (OPC, opc-harness, .harness/, .opc/); generic vocabulary kept (flow, node, edge, verdict, handshake, gate, route, transition) |
| D4 | Repo layout | Same `blueprintflow` repo; single `plugins/bf/` plugin with Packs embedded at `plugins/bf/packs/<pack-id>/` (e.g. `product-engineering`). Old `plugins/blueprintflow/` content migrates in. |
| D5 | Distribution | Marketplace only at v1; npm deferred until non-Claude-Code consumers appear |
| D6 | Pack work | Parallel — Core contracts and product-engineering Pack built side-by-side, each pressure-testing the other |

## Non-goals

- Maintain compatibility with upstream OPC after the fork commit
- Build a runtime for non-Claude-Code platforms in v1
- Re-implement OPC's harness from scratch — we vendor and rename
- Preserve runtime backward compatibility with the existing v6.0.0 `blueprintflow` plugin; a migration path is documented but state is not auto-migrated

## Architecture

### Layered model

```
┌─────────────────────────────────────────────────┐
│ Pack layer (domain instances)                   │
│   plugins/bf/packs/product-engineering/         │
│   plugins/bf/packs/<future-packs>/              │
└────────────┬────────────────────────────────────┘
             │ consumes
             ▼
┌─────────────────────────────────────────────────┐
│ BF Core (domain-general contracts + entry)      │
│   plugins/bf/core/        ← 6 contracts         │
│   plugins/bf/skills/bf-run/ ← public entry      │
│   plugins/bf/roles/       ← Core roles          │
└────────────┬────────────────────────────────────┘
             │ invokes
             ▼
┌─────────────────────────────────────────────────┐
│ Runtime (vendored harness)                      │
│   plugins/bf/runtime/bf-harness.mjs             │
│   plugins/bf/runtime/lib/*.mjs                  │
└─────────────────────────────────────────────────┘
```

All three layers ship inside one `plugins/bf/` plugin in v1. Packs are subdirectories of `bf/packs/`, not separate plugins. See [layering-principles.md](./2026-05-16-bf-fork-design/layering-principles.md) §3 for the design rationale and the future migration path to externalized Packs.

### Conceptual reversal vs OPC

| Layer | OPC | BF |
|---|---|---|
| Primary citizen | Flow run | **Work Object** (persistent, cross-run) |
| Movement | Flow + Node + Edge + Verdict | (same vocabulary, kept) |
| Evidence | handshake.json + artifacts[] | (same, kept; promoted to Artifact contract) |
| Decision | Gate + synthesize | (same, kept; promoted to Gate contract) |
| Persistence | `.harness/` (per-session) | `.bf/` (per-run) + **WO Home** (semi-persistent, per WO) |
| Domain bundle | rolesDir + protocolDir + unitHandlers | **Pack** (one manifest) |

In OPC, flow is primary; the run is what's tracked. In BF, **Work Object is primary**; flows are how it moves between states. This is BF's narrative ownership.

### Repository layout

```
blueprintflow/
├── .claude-plugin/marketplace.json    ← single bf plugin entry
├── plugins/
│   └── bf/                            ← Core + runtime + embedded Packs
│       ├── .claude-plugin/plugin.json
│       ├── runtime/                   ← vendored from OPC
│       │   ├── bf-harness.mjs
│       │   └── lib/*.mjs
│       ├── core/                      ← BF Core contracts (docs)
│       │   ├── work-object.md
│       │   ├── flow.md                 ← also documents Artifact as sub-shape
│       │   ├── gate.md
│       │   ├── wo-home.md
│       │   └── pack.md
│       ├── roles/                     ← Core roles (cross-Pack)
│       ├── skills/
│       │   └── bf-run/                ← public entry
│       ├── packs/                     ← embedded Pack directory
│       │   └── product-engineering/   ← migrated from old plugins/blueprintflow/
│       │       ├── pack.json
│       │       ├── flows/             ← Pack flow graphs
│       │       ├── schemas/           ← Pack Work Object schemas
│       │       ├── roles/             ← Pack roles (domain-specific)
│       │       ├── protocols/         ← Pack node protocols
│       │       └── skills/            ← Pack-invocable skills (e.g. using-bf)
│       └── UPSTREAM.md                ← OPC fork point + delta log
└── (plugins/blueprintflow/ retired — content moved to plugins/bf/packs/product-engineering/)
```

**One plugin, embedded Packs.** Pack discovery in `bf-run` is written to allow a future `plugins/bf-pack-*/` external Pack form (third-party or independently-released Packs) without core refactor. See [layering-principles.md](./2026-05-16-bf-fork-design/layering-principles.md) §3.

## Core contracts (overview)

Five contracts make up BF Core. Field-by-field detail in [core-contracts.md](./2026-05-16-bf-fork-design/core-contracts.md).

| Contract | Purpose | Origin |
|---|---|---|
| **Work Object** | The thing being advanced through states. Semi-persistent directory containing `wo.md`; children are sub-directories also containing `wo.md`. Discardable when done. | New (BF; v0.2 in [core-contracts.md](./2026-05-16-bf-fork-design/core-contracts.md) §1) |
| **Flow** | How a WO is advanced. Four types: `brainstorm` / `breakdown` / `loop` / `close`. Inherits OPC's flow-template graph + BF additions (`core_type`, `accepts`, `produces`). | OPC + BF additions |
| **Gate** | Decides PASS / ITERATE / FAIL mechanically from eval severity emojis. | OPC `synthesize` |
| **WO Home** | The semi-persistent directory holding `wo.md` + `runs/` for one WO. Replaces earlier "Ledger" concept. | New (BF) |
| **Pack** | Manifest binding schemas + flows + roles + routing. | New (BF) |

**Artifact is not a top-level contract** (it was in earlier drafts) — artifacts are a sub-shape of handshake, documented within Flow.

**BF does not track work product.** "What got made" (code, PR, document, behavior change) lives in its natural habitat. The WO's `acceptance_criteria` describes how to recognize a product exists; judgement is distributed across criteria-lint (mechanical), review-node role agents (LLM), execute / verify nodes (evidence production), and gate `synthesize` (mechanical emoji counting). There is no `output_target`, no product schema, no ledger of past WOs. See [layering-principles.md](./2026-05-16-bf-fork-design/layering-principles.md) §9 for the rationale and [acceptance-judgement.md](./2026-05-16-bf-fork-design/acceptance-judgement.md) for the judgement mechanism.

## Naming policy

**Replaced (brand words):**

| OPC term | BF term |
|---|---|
| OPC (product name) | BF / Blueprintflow |
| opc-harness | bf-harness |
| `/opc` (skill entry) | `/bf-run` |
| .harness/ | .bf/ |
| ~/.opc/sessions/ | ~/.bf/sessions/ |
| `OPC_HARNESS` env | `BF_HARNESS` env |
| `opc_compat` (flow JSON field) | `bf_compat` |
| `@touchskyer/opc` (npm) | not published in v1 |

**Kept (generic vocabulary):**

`flow`, `node`, `edge`, `verdict`, `handshake`, `gate`, `route`, `transition`, `runId`, `artifact`, `evidence`, `finding`, `severity`, `synthesize`, `oscillation`, `drain`, `criteria`, `role`, `protocol`, `FLOW_TEMPLATES`.

Rule: if a word is industry-generic and a reader from outside BF would recognize it, keep it. Only rename what brands the framework.

## Runtime fork: scope and process

### Vendored from OPC

- `bin/opc-harness.mjs` → `runtime/bf-harness.mjs` (renamed entry)
- `bin/lib/*.mjs` → `runtime/lib/*.mjs` (mechanical lift, brand renames applied)
- `test/` — full test suite (renamed assertions, kept structure)
- `bin/lib/extensions.mjs` — kept but extensions disabled by default in v1

### NOT taken from OPC

- `skill.md` — product-engineering scent throughout; **rewrite from scratch** as `skills/bf-run/SKILL.md`
- `pipeline/*.md` (most) — product-engineering protocols; the BF Pack rewrites its own
- `roles/*.md` — **selective adoption** ([opc-role-mapping.md](./2026-05-16-bf-fork-design/opc-role-mapping.md))
- `bin/opc.mjs` (slash-command dispatcher) — replaced by Claude Code plugin skill
- `bin/opc-report.mjs` (HTML report) — defer to v2
- `bin/replay-viewer.html` — defer to v2
- `bin/hooks/` (PreCompact/PostCompact) — defer to v2; not v1 critical
- `scripts/postinstall.mjs` — n/a (marketplace install, not npm)

### Fork commit hygiene

- One initial vendor commit, message: `bf-fork: vendor OPC harness@<commit-sha>` listing every vendored file
- `UPSTREAM.md` records:
  - OPC fork point (commit SHA + version, e.g. `OPC@0.10.0 / abc123`)
  - List of files vendored
  - Delta log: each subsequent BF-side change to vendored files, with one-line reason
- No upstream pump after v1. Bug fixes from OPC may be cherry-picked manually if relevant; documented in `UPSTREAM.md`.

## Distribution

### v1: marketplace, single plugin

- `.claude-plugin/marketplace.json` lists one entry: `bf`
- The previous `blueprintflow` plugin entry is removed; its content moves into `plugins/bf/packs/product-engineering/`
- Users install via `/plugin install` in Claude Code
- `bf-harness.mjs` invoked from skills via `node ${CLAUDE_PLUGIN_ROOT}/runtime/bf-harness.mjs`
- No external download, no npm

### Deferred to v2 (gated by demand)

- External Pack form: `plugins/bf-pack-*/` for third-party or independently-released Packs (bf-run discovery already designed to extend; see [layering-principles.md](./2026-05-16-bf-fork-design/layering-principles.md) §3)
- npm publish for non-Claude-Code consumers
- Standalone CLI invocation (`bf` binary on PATH)
- Codex / generic-CLI runtime adapter
- Extension system re-enabled (capability routing)

## Pack: product-engineering

The existing `plugins/blueprintflow/` plugin's content moves into `plugins/bf/packs/product-engineering/` and becomes the first Pack. Skill-by-skill migration plan in [bf-skill-migration.md](./2026-05-16-bf-fork-design/bf-skill-migration.md); layering rationale in [layering-principles.md](./2026-05-16-bf-fork-design/layering-principles.md).

Migration categories (skills map onto Core's four flow types):

1. **Skills → Brainstorm flow protocols** — `bf-brainstorm`, `bf-blueprint-iteration`, `bf-task-fourpiece` describe how to shape a WO at different depths
2. **Skills → Breakdown flow protocols** — `bf-phase-plan`, `bf-milestone-breakdown`, `bf-implementation-design` describe how to produce child WOs
3. **Skills → Loop / Close flow protocols** — `bf-milestone-progress`, `bf-task-execute`, `bf-pr-review-flow`, `bf-verification`, `bf-phase-exit-gate` describe how to drive children to done and how to validate at close
4. **Skills → Work Object schemas** — `bf-task-state-standard`, `bf-current-doc-standard` define state enums and `wo.md` content conventions
5. **Skills → Roles** — `bf-team-roles` splits into Pack-level `roles/*.md` (PM / Architect / Dev / QA / Teamlead); Core-eligible roles (tester / security / a11y / etc.) live in `plugins/bf/roles/`
6. **Skills retained as user entry** — `using-plueprint` (renamed `using-bf`) is the Pack's routing skill at `packs/product-engineering/skills/using-bf/`
7. **Skills retired** — `bf-runtime-adapter` and `bf-teamlead-*` subsumed by BF Core + runtime
8. **Issue triage** — `bf-issue-triage` becomes a Pack protocol invoked by Core verb `intake` (deferred to v2)

## Implementation order

Six stages, each a runnable checkpoint. Stages run sequentially; each ends with a commit + working state.

### Stage 0 — preamble (this work)
- This spec, reviewed and approved
- Implementation plan written via `superpowers:writing-plans`

### Stage 1 — runtime vendoring
- Create `plugins/bf/` skeleton
- Vendor `bin/` from OPC → `plugins/bf/runtime/`
- Apply brand renames (D3)
- Run OPC's test suite under new names; all green = stage done
- Write `UPSTREAM.md`

### Stage 2 — BF Core contracts v0.2
- Author `plugins/bf/core/*.md` (5 files: work-object, flow, gate, wo-home, pack)
- Each contract: purpose, fields, lifecycle, where stored, examples
- Open questions parked in each file's "Open Questions" section
- This stage now starts from the v0.2 drafts in [core-contracts.md](./2026-05-16-bf-fork-design/core-contracts.md), not v0.1

### Stage 3 — first Pack: product-engineering v0.1 (3 migration probes)
- Move `plugins/blueprintflow/` content into `plugins/bf/packs/product-engineering/`
- Create `packs/product-engineering/pack.json` with **`state_aliases`** mapping (existing v6 state names → canonical Core states `new` / `shaped` / `broken_down` / `doing` / `children_done` / `done`)
- Create **at least one flow of each Core type** to stress-test:
  - `flows/brainstorm-task.json` — shaping a task (covers `bf-task-fourpiece`)
  - `flows/breakdown-milestone.json` — breaking a milestone into tasks (covers `bf-milestone-breakdown`)
  - `flows/loop-milestone.json` — driving children to done (covers `bf-milestone-progress`)
  - `flows/close-leaf.json` — implement + review + verify for a task (covers `bf-task-execute` + `bf-verification`)
- Record discoveries in Core contracts' Open Questions
- DO NOT migrate all 20 skills yet

### Stage 4 — public entry: bf-run
- Write `plugins/bf/skills/bf-run/SKILL.md` from scratch (not vendored from OPC)
- BF-flavored: Work Object first, Pack discovery (scan `bf/packs/*`, with hook for future `plugins/bf-pack-*/`), then flow dispatch
- Update `.claude-plugin/marketplace.json` to a single `bf` entry; remove the old `blueprintflow` entry
- bf-run accepts **verb-first commands** (scriptable, predictable) **AND natural language** (LLM parses, transcribes to verb form, then executes). See [bf-run-commands.md](./2026-05-16-bf-fork-design/bf-run-commands.md) for the verb catalog and parsing rules.

### Stage 5 — demo: first runnable end-to-end flow
- Pick one task / milestone already in `docs/tasks/` (or fabricate a small tree)
- Run `bf-run create` → `bf-run execute` through the product-engineering Pack
- Capture: `wo.md` after each Core flow + handshake.json files under `runs/`
- Note all breakage for Stage 6

### Stage 6 — Core revision + remaining Pack migration
- Update `core/*.md` based on Stage 3/5 discoveries (v0.2 if material)
- Migrate remaining bf-* skills using stabilized Core
- v6.0.0 → v1.0.0 migration guide written

**Cumulative effort: rough estimate 5–8 sessions to v1, gated by Stage-3 / Stage-5 surprises.**

### v1 definition of done

- `bf` plugin installable from marketplace; `/bf-run` invocable
- product-engineering Pack runs a task end-to-end via BF runtime
- BF Core contracts v0.2+ stable
- All 20+ bf-* skills either migrated to Pack or retired
- Migration path from v6.0.0 documented

## Risk register

| Risk | Mitigation |
|---|---|
| Core contract gets it wrong, requires mid-stage rewrite | Stage 3 deliberately migrates only 3 skills before full commit |
| Vendored renames break OPC tests | Run full test suite at end of Stage 1; treat any red as hard stop |
| Product-engineering Pack feels "second-class" because Core is BF-Core branded | Stage 4's `bf-run` demonstrates Pack-first routing, not Core-first |
| WO Home vs `.bf/run-*/` confusion in implementation | `wo-home.md` contract written in Stage 2 before any code touches WO paths |
| Bugs in vendored OPC code with no upstream | We own the fork — patch directly, log in `UPSTREAM.md` |
| Loss of existing v6.0.0 users during migration | v6.0.0 plugin (`plugins/blueprintflow/`) remains marketplace-installable side-by-side until v1 announced; once v1 cuts over, `bf` plugin replaces it. Migration doc in Stage 6. |
| Extension system (capability routing) needed earlier than v2 | Code is vendored but disabled; can be re-enabled mid-v1 if a stage requires it |

## Open questions (resolve during Stage 2-3)

These are not blockers for spec approval; they are explicit gaps to close as implementation pressure-tests the design.

1. **Pack-defined state extensions** — how do Packs add states beyond the canonical (new / shaped / broken_down / doing / children_done / done) without breaking routing? (lean: `state_aliases` in pack.json maps custom names to canonical)
2. **Resume vs new-run** — when `runtime.active_run` is non-null and process restarts, auto-resume or prompt? (lean: auto-resume if no stale-detection signal)
3. **Pack composition** — can a Pack import another Pack? (defer; YAGNI for v1)
4. **Capability vs Role** — Work Object has `capability_required` (declares what ability is needed); OPC's `nodeCapabilities` is on Flow node (declares supply). Both? (likely both: WO declares need, Flow node declares supply)
5. **OPC's `criteria-lint` / `scope coverage` mechanism** — keep code, write BF-flavored protocol pointing at the same harness functions
6. **`depends_on` resolution** — sibling-only in v1; cross-tree references deferred
7. **`bf-run sweep` / `intake`** — cron-triggered Core verbs for cross-WO scans and external intake. Deferred. Cron scheduling is owned by user / OS, not BF.
8. **Resolved** — Artifact is no longer a top-level contract (it's a sub-shape of Flow). Shaping / breakdown / loop / close are the four `core_type` values, not separate contracts.

## What this spec does NOT decide

- Detailed field schema of each Core contract — see [core-contracts.md](./2026-05-16-bf-fork-design/core-contracts.md)
- Which OPC roles get adopted vs skipped — see [opc-role-mapping.md](./2026-05-16-bf-fork-design/opc-role-mapping.md)
- Which bf-* skills become what — see [bf-skill-migration.md](./2026-05-16-bf-fork-design/bf-skill-migration.md)
- bf-run's verb catalog and command parsing — see [bf-run-commands.md](./2026-05-16-bf-fork-design/bf-run-commands.md)
- How `acceptance_criteria` are judged satisfied (criteria-lint + review + execute + gate) — see [acceptance-judgement.md](./2026-05-16-bf-fork-design/acceptance-judgement.md)

The companion files are also drafts; they will be revised during Stage 2-3 implementation.

For the **why** behind Core / Pack / roles layering decisions, see [layering-principles.md](./2026-05-16-bf-fork-design/layering-principles.md).
