---
name: bf
description: "Use when the user types /bf, asks to brainstorm a software change, decompose a feature into tasks, draft a spec, or ship work behind an explicit review-and-verify gate. Trigger symptoms: a multi-task feature needs structured planning, the user wants every acceptance criterion signed off by an independent reviewer, the user wants an audit trail of decisions and trade-offs, or strict separation between the agent doing the work and the agent reviewing it is required. Applies to any software task — new feature, bugfix, refactor, library/CLI/API."
---

# BF — Blueprintflow

Evidence-gated work loop for LLM orchestrators. BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next → do → review → verify` loop until every Acceptance Criterion is signed off by a reviewer subagent.

## Core idea

- **Independent Verification (IV) is the axis.** Every "done" claim is signed off by a reviewer subagent that is **not the same subagent instance** that did the work. Same `role` is fine (e.g. `engineer` doer + a different `engineer` reviewer). Same subagent is not.
- **The harness owns the mutation whitelist; the LLM owns the content.** After `accept`, only the harness can flip `[ ]` → `[x]`, advance `State`, or sync `Updated` in `bf.md` / `spec.md`. The LLM never edits those fields directly again. Everything else (`discussion.md`, review results, code) is LLM-written.
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

- `references/phase-1-brainstorm.md` — drive the discussion, pick a pack, append `discussion.md`.
- `references/phase-2-spec.md` — author `bf.md` + per-task `spec.md`, lint, Spec Review loop, `accept`.
- `references/phase-3-execute.md` — `next → do → review → verify` loop, Task Verification and Final Acceptance.
- `templates/` — frozen file shapes (`bf.md`, `task-spec.md`, `discussion.md`, `review-result.md`, `role.md`, `pack.md`). Copy these when authoring; do not improvise.
- `roles/` — Core roles (`architect`, `engineer`, `tester`, …). Each pack's `pack.md` declares which role plays which phase. Packs may add private roles under `packs/<id>/roles/`.
- `packs/` — installed packs. Each `pack.md` has `When to Use` + the three phase guidances. Pack pipelines live under `packs/<id>/pipelines/*.yml` and are discoverable with `bf list-pipelines --pack <id>`.
- `extensions/` (optional) — user-supplied roles and packs. Lives at `~/.claude/skills/bf/extensions/` (global) or `<project-root>/.bf/extensions/` (project). Project beats global beats core; same id wins by precedence.
- Run `bf --help` and `bf-harness --help` for the authoritative command reference.
