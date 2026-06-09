---
name: bf
description: "Use when the user types /bf, asks to brainstorm a software change, decompose a feature into tasks, draft a spec, ship work behind an explicit review-and-verify gate, or explicitly asks to prepare, file, or comment on BF GitHub issue feedback. Applies to software tasks and BF feedback intake."
---

# BF — Blueprintflow

Evidence-gated work loop for LLM orchestrators. BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next → do → review → verify` loop until every Acceptance Criterion is signed off by an independent reviewer.

## Core idea

- **Independent Verification (IV) is the axis.** Every "done" claim is signed off by a reviewer actor that is **not the same actor instance** whose work is reviewed. Same `role` is fine (e.g. an `engineer` task driver + a different `engineer` reviewer). Same actor instance is not.
- **The harness owns the mutation whitelist; the LLM owns the content.** After `accept`, only the harness can flip `[ ]` → `[x]`, advance `State`, sync `Updated`, or write task execution metadata (`Branch`, `Worktree`, `Pull-Request`) in `bf.md` / `spec.md`. The LLM never edits those fields directly again. Everything else (`discussion.md`, review results, code) is LLM-written.
- **Host runtime strategy is explicit.** The main session is the BF coordinator. It records the host runtime, task driver type, nested-delegation limit, lifecycle/closure rule, and reviewer spawning owner before Spec Review and task execution. During execute, every claimed task and verification fix is assigned to a host-compatible task driver; in Codex this is a Codex subagent task driver.
- **Three phases, gated:** brainstorm → spec → execute.

```
brainstorm  →  spec  ──accept──▶  execute  ──verify──▶  Completed
                  ▲                    │
                  └──── lint / verify FAIL ───┘
```

## IV — non-negotiable

The harness cannot see actor identity (review filenames are role-level). IV is enforced **only by you** when you spawn reviewers:

- For any given task, the actor whose work is reviewed and any reviewer actor must be **different actor instances**.
- The same `role` may appear on both sides; the same actor instance on both sides is a contract violation the harness will not catch.

Re-check this every time you spawn a reviewer. It is the one rule the system cannot self-defend.

## Host Runtime Actors

Use these generic actor names in BF core guidance:

- **coordinator** — the main session. It owns `next`, `start-review`, `verify`,
  Final Acceptance, BF state transitions, reviewer dispatch for BF acceptance,
  and actor lifecycle accounting.
- **task driver** — the actor assigned one concrete task. It follows the task
  pipeline and produces artifacts, evidence, pipeline review outputs, closure
  evidence, and a review-ready handoff. The coordinator assigns claimed task
  work and verification fixes to a task driver instead of doing that leaf work
  in the main session.
- **leaf worker** — a bounded helper for one stage or artifact, used only when
  the current host runtime supports that delegation from the current actor.
- **reviewer** — an independent actor that writes review results. IV applies to
  the actor instance whose work is reviewed.

Claude Code `teammate` and Codex subagent are host-specific task driver
implementations, not BF core roles. If a task driver cannot spawn nested
workers or reviewers, it hands the need back to the coordinator.

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
