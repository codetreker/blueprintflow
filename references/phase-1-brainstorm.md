# Phase 1 — Brainstorm

Goal: produce `discussion.md` capturing the user's intent, decisions, and trade-offs.

## Steps

| Actor | Action |
|---|---|
| Harness | `bf list-packs` — enumerate installed packs (JSON). |
| LLM | Pick the pack whose `Desc` / `When to Use` matches the request. |
| LLM | Drive an interactive discussion with the user, shaped by the chosen pack's `Brainstorm Guidance`. |
| LLM | Append to `<project-root>/.bf/<bf-wo>/discussion.md` as the discussion happens. |

`discussion.md` is never locked; you can append to it at any phase.

## Crash-safety

Write each Q&A or decision to `discussion.md` **as it happens**. Do not buffer in memory and dump at the end — if the session crashes mid-discussion, only what is on disk survives. Use the `templates/discussion.md` shape.

## Pack selection

- One pack per bf-wo. The pack you pick here governs role/capability lookups for Phases 2 and 3.
- If two packs match, prefer the one whose `When to Use` lists the request's most specific symptom. If still tied, ask the user.
- If no pack matches, stop and tell the user. Do not invent a pack on the fly.

## Exit

Phase 1 ends when the user agrees you have captured enough to write a spec. Move to [phase-2-spec.md](phase-2-spec.md).
