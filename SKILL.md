---
name: bf
description: "Use when the user types /bf, asks to brainstorm a software change, decompose a feature into tasks, draft a spec, ship work behind an explicit review-and-verify gate, or explicitly asks to prepare, file, or comment on BF GitHub issue feedback. Applies to software tasks and BF feedback intake."
---

# BF — Blueprintflow

Evidence-gated work loop for LLM orchestrators. BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next → do → review → verify` loop until every Acceptance Criterion is signed off by a reviewer subagent.

## Core idea

- **Independent Verification (IV) is the axis.** Every "done" claim is signed off by a reviewer subagent that is **not the same subagent instance** that did the work. Same `role` is fine (e.g. `engineer` doer + a different `engineer` reviewer). Same subagent is not.
- **The harness owns the mutation whitelist; the LLM owns the content.** After `accept`, only the harness can flip `[ ]` → `[x]`, advance `State`, sync `Updated`, or write task execution metadata (`Branch`, `Worktree`, `Pull-Request`) in `bf.md` / `spec.md`. The LLM never edits those fields directly again. Everything else (`discussion.md`, review results, code) is LLM-written.
- **Three phases, gated:** brainstorm → spec → execute.

```
brainstorm  →  spec  ──accept──▶  execute  ──verify──▶  Completed
                  ▲                    │
                  └──── lint / verify FAIL ───┘
```

## IV — non-negotiable

The harness cannot see subagent identity (review filenames are role-level). IV is enforced **only by you** when you spawn subagents:

- For any given task, the doer subagent and any reviewer subagent must be **different subagent instances**.
- The same `role` may appear on both sides; the same subagent instance on both sides is a contract violation the harness will not catch.

Re-check this every time you spawn a reviewer. It is the one rule the system cannot self-defend.

## Pointers

- `references/brainstorm.md` — drive the discussion, pick a pack, append `discussion.md`.
- `references/project-docs.md` — discover project design docs, use them as design authority, and stop on design drift.
- `references/spec-authoring.md` — author `bf.md` + per-task `spec.md`, lint, Spec Review loop, `accept`.
- `references/execution.md` — `next → do → review → verify` loop, Task Verification and Final Acceptance.
- `references/feedback.md` — prepare user-requested GitHub issue feedback with duplicate checks, filing boundaries, redaction, and final user confirmation.
- `templates/` — frozen file shapes (`bf.md`, `task-spec.md`, `discussion.md`, `review-result.md`, `role.md`, `pack.md`). Copy these when authoring; do not improvise.
- `roles/` — Core roles (`architect`, `engineer`, `tester`, …). Each pack's `pack.md` declares which role plays which phase. Packs may add private roles under `packs/<id>/roles/`.
- `packs/` — installed packs. Each `pack.md` has `When to Use` + the three phase guidances. Pack pipelines live under `packs/<id>/pipelines/*.yml` and are discoverable with `bf list-pipelines --pack <id>`.
- `extensions/` (optional) — user-supplied roles and packs. Global extensions live at `~/.bf/extensions/`; project extensions live under the normal project BF state home at `.bf/extensions/`. Project beats global beats selected pack-private roles and Core roles; same id wins by precedence.
- BF state — Git projects store BF state under the primary worktree `.bf`, even when commands run from linked worktrees. New work objects live under `.bf/works/<bf-wo>`; legacy `.bf/<bf-wo>` work objects remain readable. Non-Git directories fall back to `<cwd>/.bf`.
- Run `bf --help` and `bf-harness --help` for the authoritative command reference.
