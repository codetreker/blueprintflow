---
name: bf
description: "Use when the user types $bf or /bf; asks to brainstorm, scope, spec, review, execute, verify, or resume a software BF work object; or explicitly asks to prepare, file, or comment on BF GitHub issue feedback."
---

# BF — Blueprintflow

Evidence-gated work loop for LLM orchestrators. BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next -> do -> review/verify -> complete` loop until every Acceptance Criterion is signed off by an independent reviewer and harness completion succeeds.

## Core idea

- **Independent Verification (IV) is the axis.** Every "done" claim is signed off by a reviewer actor that is **not the same actor instance** whose work is reviewed. Same `role` is fine (e.g. an `engineer` task driver + a different `engineer` reviewer). Same actor instance is not.
- **The harness owns the mutation whitelist; the LLM owns the content.** After `accept`, only the harness can flip `[ ]` -> `[x]`, advance `State`, sync `Updated`, or write task execution metadata (`Branch`, `Worktree`, `Pull-Request`) in `bf.md` / `spec.md`. The LLM never edits those fields directly again. Everything else (`discussion.md`, review results, code) is LLM-written.
- **Host runtime strategy is explicit.** The main session is the BF coordinator. It records the host runtime, task driver type, nested-delegation limit, lifecycle/closure rule, and reviewer spawning owner before Spec Review and task execution. During execute, every claimed task and verification fix is assigned to a host-compatible task driver; in Codex this is a Codex subagent task driver.
- **Three phases, gated:** brainstorm → spec → execute.

```
brainstorm -> spec --accept--> execute --verify/complete--> Completed
                 ^                  |
                 +---- lint / verify FAIL ----+
```

## IV — non-negotiable

The harness cannot see actor identity (review filenames are role-level). IV is enforced **only by you** when you spawn reviewers:

- For any given task, the actor whose work is reviewed and any reviewer actor must be **different actor instances**.
- The same `role` may appear on both sides; the same actor instance on both sides is a contract violation the harness will not catch.

Re-check this every time you spawn a reviewer. It is the one rule the system cannot self-defend.

## Host Runtime Actors

Use these generic actor names in BF core guidance:

- **coordinator** — the main session. It owns `next`, task-driver assignment or resume, final task verification rerun, PR merge, `bf-harness complete`, cleanup, Final Acceptance, and actor lifecycle accounting.
- **task driver** — the actor assigned one concrete task. It owns that task to acceptance-ready: follows the task pipeline; produces artifacts, evidence, pipeline review outputs, and closure evidence; opens and records the PR when needed; starts task review and readiness verification when the host runtime allows; handles feedback; and hands off evidence, review output, and verify output. The coordinator owns merge, complete, and cleanup.
- **leaf worker** — a bounded helper for one stage or artifact, used only when the current host runtime supports delegation from the current actor.
- **reviewer** — an independent actor that writes review results. IV applies to the actor instance whose work is reviewed.

Claude Code `teammate` and Codex subagent are host-specific task driver implementations, not BF core roles. If a task driver cannot spawn nested workers or reviewers, it hands the need back to the coordinator.

## BF Actor Authorization

Using `$bf` or `/bf` is explicit authorization for the coordinator to dispatch host-compatible actor instances required by the BF workflow: task drivers, leaf workers, and reviewers.
Codex uses subagent actors for task drivers, leaf workers, and reviewers.
Claude Code uses `teammate` for task drivers.
Claude Code uses subagents for leaf workers and reviewers.

This authorization is BF-scoped. It does not authorize unrelated background work, non-BF automation, or bypassing the recorded host-runtime strategy, Independent Verification, lifecycle/closure accounting, or user confirmation gates.

## When Not To Use

Do not start or mutate a BF work object for read-only questions, explanations, audits, status checks, or advice unless the user asks to turn the result into implementation work. In read-only mode, answer from the current repo context and name any BF follow-up separately.

Do not use BF for non-software work, casual conversation, simple one-command answers, or user requests that explicitly ask to avoid workflow overhead.

## Entry Protocol

On every `$bf` or `/bf` turn, classify the request before loading deeper references:

1. **Pending phase confirmation** — if the previous BF response asked for approval to enter the next phase, an affirmative reply means: immediately run the next legal BF action and continue to that phase; do not ask for another phase command. If the reply changes scope or objects, append it to `discussion.md` and do not advance.
2. **Feedback issue** — if the user explicitly asks to prepare, file, or comment on BF GitHub issue feedback, read `references/feedback.md`.
3. **Read-only / advisory** — if the user asks to explain, audit, inspect, compare, or discuss without asking for changes, do not create a work object. Load only the references needed to answer.
4. **Resume existing work** — if the user says continue/resume or names a bf-wo, load `.bf/works/<bf-wo>`. Read `bf.md`, `discussion.md`, task specs, and latest review or verify results, then route by state to spec authoring or execution.
5. **New software change / brainstorm** — read `references/brainstorm.md` first.
   Brainstorm owns pack selection, bootstrap, and the first accepted discussion entry.
   Do not create a work object or write `discussion.md` before following the brainstorm reference unless you are resuming existing work.
6. **Spec / accept / execute request** — load the existing work object first. Then read `references/spec-authoring.md` or `references/execution.md` based on `bf.md` state. Do not skip unresolved brainstorm source coverage.

If the route is ambiguous and the choice changes state, scope, or external side effects, ask the user before mutating BF state.

## Pointers

- `references/brainstorm.md` — drive the discussion, pick a pack, append `discussion.md`.
- `references/project-docs.md` — discover project design docs, use them as design authority, and stop on design drift.
- `references/spec-authoring.md` — author `bf.md` + per-task `spec.md`, lint, Spec Review loop, `accept`.
- `references/execution.md` — `next -> do -> review/verify -> complete` loop, Task Verification and Final Acceptance.
- `references/feedback.md` — prepare user-requested GitHub issue feedback with duplicate checks, filing boundaries, redaction, and final user confirmation.
- `templates/` — frozen file shapes (`bf.md`, `task-spec.md`, `discussion.md`, `review-result.md`, `role.md`, `pack.md`). Copy these when authoring; do not improvise.
- `roles/` — Core roles (`architect`, `engineer`, `tester`, `security`, …). Each pack's `pack.md` declares which role plays which phase. Packs may add private roles under `packs/<id>/roles/`.
- `packs/` — installed packs. Each `pack.md` has `When to Use` + the three phase guidances. Pack pipelines live under `packs/<id>/pipelines/*.yml` and are discoverable with `bf list-pipelines --pack <id>`. The engineering pack includes `feature`, `bugfix`, and review-only `code-deep-audit`.
- `extensions/` (optional) — user-supplied roles and packs. Global extensions live at `~/.bf/extensions/`; project extensions live under the normal project BF state home at `.bf/extensions/`. Project beats global beats selected pack-private roles and Core roles; same id wins by precedence.
- BF state — Git projects store BF state under the primary worktree `.bf`, even when commands run from linked worktrees. Work objects live under `.bf/works/<bf-wo>`. Non-Git directories fall back to `<cwd>/.bf`.
- Run `bf --help` and `bf-harness --help` for the authoritative command reference.
