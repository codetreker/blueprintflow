# Phase 2 — Spec

Goal: produce a locked `bf.md` + one `<task-id>/spec.md` per task, with every AC reviewed and accepted by the user.

## Steps

1. `bf list-roles --pack <id>` — get the available roles and the capabilities they provide.
2. `bf list-pipelines --pack <id>` — get the available task execution pipelines for this pack.
3. Author `bf.md` with `State: Draft` using `templates/bf.md`. Every AC must carry `{id}|{capability}`, and the capability must be declared in some role's `Capabilities:` list.
4. Author each `<task>/spec.md` with `State: Draft` using `templates/task-spec.md`. Each task spec has exactly one `Pipeline` in frontmatter, AC lines with their own `{capability}` markers (review capability), and an explicit `Evidence` section that maps each task AC to one or more required evidence items.
5. `bf-harness lint <bf-wo>` — fix every error and re-run until SUCCESS.
6. **Spec Review loop:**
   1. `bf-harness start-review <bf-wo>` — returns the round directory `<bf-wo>/runs/reviews/round_N/`.
   2. For each role returned by `bf list-roles --pack <id>` that provides a review capability used in the spec, spawn 1–3 reviewer subagents (cap total at 10). Each subagent writes `result_<role>_<idx>.md` into the round dir using `templates/review-result.md`.
   3. `bf-harness verify <bf-wo>` (Spec Review) — `SUCCESS <path>` or `FAIL <path>`. On FAIL, read the verify-result file, fix `bf.md` / `spec.md`, then start a new round.
7. When verify returns SUCCESS and the user agrees with the plan, `bf-harness accept <bf-wo>`. `bf.md` → `Accepted`; all tasks cascade `Draft` → `Ready`. **Contract is now locked.**

## Mutation whitelist after accept

Once `accept` runs, the LLM no longer edits `State`, AC checkboxes, or `Updated` fields in `bf.md` / `spec.md`. Only the harness writes those. The LLM continues to write `discussion.md`, review results, and code.

## Authoring rules

- Every AC capability must be discoverable via `bf list-roles --pack <id>`. Lint will fail otherwise.
- Each task spec's `Pipeline:` selects the **execution pipeline**. Doer/reviewer capabilities for execution stages live in the pipeline file, not in task frontmatter.
- Each AC's `{capability}` is the **review** capability (what the reviewer needs for that AC). It must be discoverable via `bf list-roles --pack <id>`.
- Each task spec must include `## Evidence`. Each task AC must have at least one Evidence entry in the form `EV-1|AC-1|kind: requirement`.
- Evidence ids must be unique within the task spec. Evidence `AC` references must point to AC ids in the same task spec.
- Evidence kind must be one of `command`, `file`, `artifact`, `review-note`, or `screenshot`; the requirement text after `:` must be non-empty.
- Evidence entries are locked with the task spec; execution produces evidence artifacts, not new evidence requirements.
- Task dependencies are declared in `bf.md` `Task List`; lint catches cycles and unknown task ids.

## Exit

Phase 2 ends after `accept` returns success. Move to [phase-3-execute.md](phase-3-execute.md).
