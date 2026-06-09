# Brainstorm

Goal: produce `discussion.md` capturing the user's intent, decisions, and trade-offs.

## Steps

| Actor | Action |
|---|---|
| Harness | `bf list-packs` — enumerate installed packs. Output is one labeled key:value block per pack (`Id:`, `Desc:`, one or more `Path:` lines), blocks separated by `---`. |
| LLM | Pick the pack whose `Desc` / `When to Use` matches the request. Read every `Path:` for the selected pack in output order; later paths have higher priority when guidance conflicts. |
| LLM | Follow [project-docs.md](project-docs.md) to discover the project design-doc root before spec authoring. Record the discovery result in `discussion.md`. |
| LLM | Drive an interactive discussion with the user, shaped by the chosen pack's `Brainstorm Guidance`. |
| LLM | Append to `<project-root>/.bf/<bf-wo>/discussion.md` as the discussion happens. |

`discussion.md` is never locked; you can append to it at any phase.

## Crash-safety

Write each Q&A or decision to `discussion.md` **as it happens**. Do not buffer in memory and dump at the end — if the session crashes mid-discussion, only what is on disk survives. Use the `templates/discussion.md` shape.

## Source coverage

Before moving to spec authoring, confirm source coverage in `discussion.md`.
Recorded discussion must answer requirement, acceptance, out-of-scope boundary,
important constraints or tradeoffs, evidence shape, and remaining open questions
or accepted proposals.

You may fill gaps with an assistant-led proposal instead of only asking the
user a question. Append the proposal to `discussion.md`, discuss it with the
user, and treat it as source material only after it becomes a confirmed or
accepted proposal.
Only a confirmed or accepted proposal can support `bf.md`.

Every bf.md section must be supportable from `discussion.md`: Goal,
Requirement, Acceptance Criteria, Boundary, and Task List rationale. This is an
authoring and review discipline, not a formatting requirement. Keep `bf.md`
concise; do not quote or cite discussion entries by default.

## Pack selection

- One pack per bf-wo. The pack you pick here governs role/capability lookups for Phases 2 and 3.
- If two packs match, prefer the one whose `When to Use` lists the request's most specific symptom. If still tied, ask the user.
- If no pack matches, stop and tell the user. Do not invent a pack on the fly.

## Exit

Brainstorm ends when the user agrees you have captured enough to write a spec
and the source coverage check is satisfied. Move to
[spec-authoring.md](spec-authoring.md).
