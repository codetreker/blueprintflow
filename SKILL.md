---
name: bf
description: "Use when the user types /bf, asks to brainstorm a software change, decompose a feature into tasks, draft a spec, or ship work behind an explicit review-and-verify gate. Trigger symptoms: a multi-task feature needs structured planning, the user wants every acceptance criterion signed off by an independent reviewer, the user wants an audit trail of decisions and trade-offs, or strict separation between the agent doing the work and the agent reviewing it is required. Applies to any software task — new feature, bugfix, refactor, library/CLI/API."
---

# BF — Blueprintflow

Evidence-gated work loop for LLM orchestrators. BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next → do → review → verify` loop until every Acceptance Criterion is signed off by a reviewer subagent.

This document is the operator runbook for the orchestrating LLM (you). Read `docs/spec.md` for the full contract; read `docs/template/*.md` for the exact file shapes.

## Core idea

- **Independent Verification (IV) is the axis.** Every claim of "done" is signed off by a reviewer subagent that is not the same subagent instance that did the work. Same `role` is fine (e.g. `engineer` does and `engineer` reviews — two different subagents). Same subagent is not.
- **The harness owns the mutation whitelist; the LLM owns the content.** After `accept`, only the harness can flip `[ ]` → `[x]`, advance `State`, or sync `Updated` in `bf.md` / `spec.md`. The LLM never edits those files directly again. Everything else (discussion, review results, code) is LLM-written.
- **Three phases:** brainstorm → spec → execute. Each phase has a clear handoff and a clear set of harness commands.

## Phases

### Phase 1 — Brainstorm

Goal: produce `discussion.md` capturing the user's intent, decisions, and trade-offs.

| Actor | Action |
|---|---|
| Harness | `bf list-packs` — enumerate installed packs (JSON). |
| LLM | Pick the pack whose `Desc` / `When to Use` matches the request. |
| LLM | Drive an interactive discussion with the user, shaped by the chosen pack's `Brainstorm Guidance`. |
| LLM | Append to `~/.bf/projects/<slug>/<bf-wo>/discussion.md` as the discussion happens (crash-safe — write incrementally, not at the end). |

`discussion.md` is never locked; you can append to it at any phase.

### Phase 2 — Spec

Goal: produce a locked `bf.md` + one `<task-id>/spec.md` per task, with every AC reviewed and accepted by the user.

1. `bf list-roles --pack <id>` → get the available roles and the capabilities they provide.
2. Author `bf.md` with `State: Draft`. Use `docs/template/bf.md`. Every AC must carry `{id}|{capability}` and the capability must be declared in some role's `Capabilities:` list.
3. Author each `<task>/spec.md` with `State: Draft`. Use `docs/template/task-spec.md`. Each task spec has exactly one `Capability` in frontmatter (execution capability) and AC lines with their own `{capability}` markers (review capability).
4. `bf-harness lint <bf-wo>` — fix every error and re-run until SUCCESS.
5. Spec review loop (Mode A):
   1. `bf-harness start-review <bf-wo>` → returns the round directory `<bf-wo>/runs/reviews/round_N/`.
   2. For each role returned by `bf list-roles --pack <id>` that provides a review capability used in the spec, spawn 1–3 reviewer subagents (cap total at 10). Each subagent writes `result_<role>_<idx>.md` into the round dir using `docs/template/review-result.md`.
   3. `bf-harness verify <bf-wo>` (Mode A) → `SUCCESS <path>` or `FAIL <path>`. On FAIL, read the verify-result file, fix `bf.md` / `spec.md`, then start a new round.
6. When verify returns SUCCESS and the user agrees with the plan, `bf-harness accept <bf-wo>`. `bf.md` → `Accepted`; all tasks cascade `Draft` → `Ready`. Contract is now locked.

### Phase 3 — Execute

Goal: loop until `bf-harness verify <bf-wo>` returns Mode C SUCCESS.

Outer loop (per task):

1. `bf-harness next <bf-wo>` → returns one ready task with `capability_required`, `candidate_roles`, spec path, and pack id. The harness flips the returned task to `Tasking` and (on the first call) flips `bf.md` to `Implementing`. If no task is ready (deps unmet) it returns `ok: false`; wait or `verify` first.
2. Pick one `candidate_role` and spawn a **doer** subagent of that role. Doer reads the pack's `Execute Guidance` and the task spec, makes the changes, and produces evidence (commits, test output, screenshots).
3. `bf-harness start-review <bf-wo>/<task>` → returns the task-level round dir.
4. For each AC's review capability, spawn one or more **reviewer** subagents — **different subagent instances than the doer** (IV). Each writes `result_<role>_<idx>.md` into the round dir.
5. `bf-harness verify <bf-wo>/<task>` (Mode B). On FAIL, read the verify-result file, dispatch fixes (the same doer subagent or a new one), open a new review round, and re-verify. The task stays in `Tasking` until verify SUCCESS, at which point the harness flips its AC and sets `State: Completed`.

Final acceptance:

6. When all task spec.md are `Completed`, run one more bf-level review pass: `bf-harness start-review <bf-wo>` → spawn reviewers against the `bf.md` AC → `bf-harness verify <bf-wo>` (Mode C). On SUCCESS the harness flips all bf.md AC and sets `State: Completed`.

## Independent Verification — reminder

The harness cannot see subagent identity (review filenames are role-level). IV is enforced **only by you** when you spawn subagents:

- For any given task, the doer subagent and any reviewer subagent for that task must be **different subagent instances**.
- The same `role` may appear on both sides. `engineer` doing the task and a separate `engineer` reviewing it is fine.
- The same subagent instance doing both is a contract violation even though the harness will not catch it.

## Command cheat sheet

```
# bf (read-only metadata)
bf list-packs                              # JSON: installed packs
bf list-roles                              # JSON: Core roles
bf list-roles --pack <pack-id>             # Core ∪ pack-private roles (pack wins on name collision)

# bf-harness (state-mutating; --project <slug> overrides cwd basename)
bf-harness list                            # all bf-wo under current project
bf-harness lint <bf-wo>                    # validate Draft bf.md + task specs
bf-harness start-review <bf-wo>            # new spec-review round; prints round dir
bf-harness start-review <bf-wo>/<task>     # new task-review round; prints round dir
bf-harness accept <bf-wo>                  # Draft → Accepted; tasks Draft → Ready
bf-harness next <bf-wo>                    # claim ready task(s); flips to Tasking
bf-harness verify <bf-wo>                  # Mode A (bf Draft) or Mode C (bf Implementing + all tasks done)
bf-harness verify <bf-wo>/<task>           # Mode B (task verification)
bf-harness discard <bf-wo>                 # delete the whole bf-wo
```

`verify` always prints exactly one line: `SUCCESS <abs-path>` or `FAIL <abs-path>`. The path points at a `verify-result.md` you can hand to a subagent verbatim.

## Pointers

- `docs/spec.md` — full contract: state machine, mutation whitelist, verify modes, pack semantics. The source of truth.
- `docs/template/bf.md`, `docs/template/task-spec.md`, `docs/template/discussion.md`, `docs/template/review-result.md`, `docs/template/role.md`, `docs/template/pack.md` — frozen file shapes. Copy these when authoring; do not improvise.
- `roles/` — Core roles (`architect`, `engineer`, `tester`, …) — concrete skill identities reused across packs. Each pack's `pack.md` declares which role plays which phase (planning role for an engineering pack is `architect`; another pack might map planning to a different role). Packs may add private roles under `packs/<id>/roles/`.
- `packs/` — installed packs. Each has a `pack.md` with `When to Use` + the three phase guidances.
