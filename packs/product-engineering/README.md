# product-engineering Pack

The original Blueprintflow methodology as a BF Pack: blueprint →
phase → milestone → task, with stance, four-piece, and acceptance gates.

This Pack is v1.0.0-alpha. The v6 plugin at `plugins/blueprintflow/`
remains installable side-by-side until v1 cuts over.

## What's here

- `pack.json` — manifest, routing, state_aliases mapping v6 state
  names to BF Core canonical (shaped / broken_down / doing / done)
- `schemas/` — Work Object schemas (task, milestone, phase, blueprint)
- `flows/` — flow graphs (brainstorm / breakdown / loop / close)
- `protocols/` — node execution protocols (derived from v6 skills)
- `roles/` — product-engineering specialist agent prompts
- `reference-v6/` — copies of v6 SKILL.md content, for traceability
  during the v6 → v1 migration. Becomes authored Pack content in
  Stage 6.

## Mapping v6 skills → Pack content

See [bf-skill-migration.md](../../docs/specs/2026-05-16-bf-fork-design/bf-skill-migration.md).
