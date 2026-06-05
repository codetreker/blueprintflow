# Project Docs

Goal: find and use the target project's design documentation as the system
design authority for BF work.

## Doc Root Discovery

Before treating project docs as authoritative, locate the project's design-doc
root.

First read the current `discussion.md`. If it already records a confirmed
design-doc root for this work object, reuse that root and do not repeat
discovery, confirmation, or persistence prompts unless later evidence conflicts
with the recorded result.

Use these signals in order:

1. Read explicit project instructions: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
   README files, package-local instructions, and prompt or workflow files.
2. Inspect repository structure for likely design-doc roots such as `docs/`,
   `documentation/`, `architecture/`, `design/`, `spec/`, or `blueprint/`.
3. Inspect candidate docs for design-authority signals: reading maps, module
   boundaries, state authority, cross-module flows, validation boundaries, known
   gaps, implementation anchors, or "single source of truth" wording.

Record the discovery result in `discussion.md`:

| Result | Required action |
|---|---|
| Confirmed root | Record the path and use it as the project design-doc root. |
| One inferred candidate | Record the candidate and ask the user to confirm before treating it as authoritative. |
| Multiple candidates | Record the candidates and ask the user to choose. |
| No candidate | Record that no design-doc root exists; if the work changes system design, include design-doc creation in the BF contract. |
| Conflicting instructions | Record the conflict and ask the user; do not choose silently. |

After the user confirms an inferred root, ask whether to persist the result in
the governing project instruction file. Record the answer in `discussion.md`.
Prefer the most specific instruction file that governs the current work.

Route persistence through one of these paths:

- If persistence belongs to the current BF work, add the instruction-file update
  to the accepted contract as task scope and Evidence before implementation.
- If the user gives an explicit out-of-band command to persist immediately,
  update only the confirmed target file and record the action in `discussion.md`.
- If the user declines persistence, record `not persisted` and continue.
- If no governing project instruction file exists, ask before creating one.
- If multiple instruction systems apply or the target file remains ambiguous,
  stop and ask which file or files should receive the update.

## Design Authority

Once confirmed, project design docs are the system design single source of truth
for BF work.

Use design docs to understand:

- system boundaries;
- module ownership;
- state authority;
- cross-module flows;
- validation and release boundaries;
- known gaps and do-not-assume notes;
- stable implementation anchors.

Accepted design changes that affect those topics must include design-doc update
requirements in the BF contract and task Evidence.

## Design Drift

If code and confirmed design docs disagree, treat the mismatch as design drift.

Record the mismatch in `discussion.md` and stop for user clarification. Do not
decide whether code or docs win. The clarified path must either change code to
match the design docs or change design docs through an explicit accepted design
change.

## Return To Design

If execution exposes a design gap in accepted `bf.md` or task `spec.md`, stop
implementation and return to design discussion.

Do not silently expand locked scope. Do not edit locked `bf.md` or task
`spec.md` directly. If the gap changes accepted scope, continue only after the
user approves an explicit path, such as a new BF work object, a follow-up task,
or a harness-supported contract mutation.
