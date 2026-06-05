# Spec Authoring

Goal: produce a locked `bf.md` + one `<task-id>/spec.md` per task, with every AC reviewed and accepted by the user.

## Steps

1. `bf list-roles --pack <id>` — get the available roles and the capabilities they provide.
2. `bf list-pipelines --pack <id>` — get the available task execution pipelines for this pack.
3. Follow [project-docs.md](project-docs.md). If confirmed project design docs exist, treat them as design authority while drafting. If the work changes accepted system design, add design-doc update AC and Evidence to the relevant task specs.
4. Author `bf.md` with `State: Draft` using `templates/bf.md`. Every AC must carry `{id}|{capability}`, and the capability must be declared in some role's `Capabilities:` list.
5. Author each `<task>/spec.md` with `State: Draft` using `templates/task-spec.md`. Each task spec has exactly one `Pipeline` in frontmatter, AC lines with their own `{capability}` markers (review capability), and an explicit `Evidence` section that maps each task AC to one or more required evidence items.
6. If no pack pipeline fits a task, create a bf-wo local pipeline under `<bf-wo>/pipelines/<id>.yml`. The local pipeline must be designed by a `pipeline-designer` subagent. The designer must include terminal-state closure for every external artifact or side effect the pipeline creates, so the pipeline cannot reach user-perspective completion with dangling work. The parent orchestrator may only make mechanical path/format fixes; substantive stage, gate, capability, artifact, closure, handoff, or stop-condition changes go back to the designer.
7. `bf-harness lint <bf-wo>` — fix every error and re-run until SUCCESS.
8. **Spec Review loop:**
   1. `bf-harness start-review <bf-wo>` — returns the round directory `<bf-wo>/runs/reviews/round_N/`.
   2. For each role returned by `bf list-roles --pack <id>` that provides a review capability used in the spec, spawn 1–3 reviewer subagents (cap total at 10). Each subagent writes `result_<role>_<idx>.md` into the round dir using `templates/review-result.md`.
   3. If the bf-wo has local pipelines, include an independent reviewer with `pipeline-review` capability. This reviewer must be a different subagent instance from the pipeline designer. The reviewer must reject any bf-wo local pipeline that creates external artifacts or side effects without a terminal-state closure path, handoff, or explicit stop condition for dangling work.
   4. `bf-harness verify <bf-wo>` (Spec Review) — `SUCCESS <path>` or `FAIL <path>`. On FAIL, read the verify-result file, fix `bf.md` / `spec.md` / local pipelines, then start a new round.
9. When verify returns SUCCESS and the user agrees with the plan, `bf-harness accept <bf-wo>`. `bf.md` → `Accepted`; all tasks cascade `Draft` → `Ready`. **Contract is now locked.**

## Mutation whitelist after accept

Once `accept` runs, the LLM no longer edits `State`, AC checkboxes, or `Updated` fields in `bf.md` / `spec.md`. Only the harness writes those. The LLM continues to write `discussion.md`, review results, and code.

## Authoring rules

- Every AC capability must be discoverable via `bf list-roles --pack <id>`. Lint will fail otherwise.
- Each task spec's `Pipeline:` selects the **execution pipeline**. Doer/reviewer capabilities for execution stages live in the pipeline file, not in task frontmatter.
- `Pipeline:` may reference a selected pack pipeline or a bf-wo local pipeline under `<bf-wo>/pipelines/<id>.yml`.
- A bf-wo local pipeline id must not collide with a selected pack pipeline id, and each local pipeline must be referenced by at least one task.
- A bf-wo local pipeline that creates external artifacts or side effects must
  describe terminal-state closure for each one: close it in a later stage, hand
  it off to a named owner, or stop before the task is considered complete.
- Each AC's `{capability}` is the **review** capability (what the reviewer needs for that AC). It must be discoverable via `bf list-roles --pack <id>`.
- Each task spec must include `## Evidence`. Each task AC must have at least one Evidence entry in the form `EV-1|AC-1|kind: requirement`.
- Evidence ids must be unique within the task spec. Evidence `AC` references must point to AC ids in the same task spec.
- Evidence kind must be one of `command`, `file`, `artifact`, `review-note`, or `screenshot`; the requirement text after `:` must be non-empty.
- Evidence entries are locked with the task spec; execution produces evidence artifacts, not new evidence requirements.
- Task dependencies are declared in `bf.md` `Task List`; lint catches cycles and unknown task ids.
- `pipelines` is a reserved task id.

## Exit

Spec Authoring ends after `accept` returns success. Move to [execution.md](execution.md).
