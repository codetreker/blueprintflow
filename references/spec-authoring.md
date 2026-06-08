# Spec Authoring

Goal: produce a locked `bf.md` + one `<task-id>/spec.md` per task, with every AC reviewed and accepted by the user.

## Spec Granularity

Write `bf.md` and task `spec.md` as a **scope contract**.
It is not implementation design.
Lock the shape of the work: task decomposition, dependencies, scope,
boundaries, ownership or handoff expectations, observable AC, and evidence
intent.

Do not lock unverified implementation details in the spec. Exact file paths,
command flags, internal API shapes, migration strategy, grep/cat findings, and
step-by-step implementation sequence belong to the selected task pipeline's
execution design stages unless the user has already accepted them as
user-facing contract or required Evidence.

Spec Review blocks **contract gaps**: unclear task ownership, broken dependency
or handoff chains, missing terminal-state expectations, vague boundaries,
unobservable AC, missing Evidence, or task overlap. Spec Review does not block
only because implementation investigation remains for execution design.

## Steps

1. `bf list-roles --pack <id>` — get the available roles and the capabilities they provide.
2. `bf list-pipelines --pack <id>` — get the available task execution pipelines for this pack.
3. Follow [project-docs.md](project-docs.md). If confirmed project design docs exist, treat them as design authority while drafting. If the work changes accepted system design, add design-doc update AC and Evidence to the relevant task specs.
4. Author `bf.md` with `State: Draft` using `templates/bf.md`. Every AC must carry `{id}|{capability}`, and the capability must be declared in some role's `Capabilities:` list.
5. Author each `<task>/spec.md` with `State: Draft` using `templates/task-spec.md`. Each task spec has exactly one `Pipeline`, a required `Requires-Worktree: true|false`, empty `Branch` / `Worktree` / `Pull-Request` metadata, AC lines with their own `{capability}` markers (review capability), and an explicit `Evidence` section that maps each task AC to one or more required evidence items. Keep the task spec at contract granularity; leave detailed design to the task pipeline.
6. If no pack pipeline fits a task, create a bf-wo local pipeline under `<work-object>/pipelines/<id>.yml`. The local pipeline must be designed by a `pipeline-designer` subagent. The designer must include terminal-state closure for every external artifact or side effect the pipeline creates, so the pipeline cannot reach user-perspective completion with dangling work. The parent orchestrator may only make mechanical path/format fixes; substantive stage, gate, capability, artifact, closure, handoff, or stop-condition changes go back to the designer.
7. `bf-harness lint <bf-wo>` — fix every error and re-run until SUCCESS.
8. **Spec Review loop:**
   1. `bf-harness start-review <bf-wo>` — returns the round directory `<work-object>/runs/reviews/round_N/`.
   2. For each role returned by `bf list-roles --pack <id>` that provides a review capability used in the spec, spawn exactly three reviewer subagents. Every reviewer in the same Spec Review round must be a distinct subagent instance. Each subagent writes `result_<role>_<idx>.md` into the round dir using `templates/review-result.md`; `<idx>` starts at 1 for each role.
   3. If the bf-wo has local pipelines, include three independent reviewer subagents with the `pipeline-review` capability. Each `pipeline-review` reviewer must be a different subagent instance from the pipeline designer and from every other reviewer in the same Spec Review round. The reviewers must reject any bf-wo local pipeline that creates external artifacts or side effects without a terminal-state closure path, handoff, or explicit stop condition for dangling work.
   4. Tell reviewers to reject contract gaps, not missing implementation-design detail. A reviewer may reject a detail that is already locked and wrong, but must not require file-level investigation before `accept` when the selected pipeline owns that design work.
   5. `bf-harness verify <bf-wo>` (Spec Review) — `SUCCESS <path>` or `FAIL <path>`. On FAIL, read the verify-result file, fix `bf.md` / `spec.md` / local pipelines, then start a new round.
9. When verify returns SUCCESS and the user agrees with the plan, `bf-harness accept <bf-wo>`. `bf.md` → `Accepted`; all tasks cascade `Draft` → `Ready`. **Contract is now locked.**

## Mutation whitelist after accept

Once `accept` runs, the LLM no longer edits `State`, AC checkboxes, `Updated`, or task execution metadata in `bf.md` / `spec.md`. Only the harness writes those. The LLM continues to write `discussion.md`, review results, and code.

## Authoring rules

- Every AC capability must be discoverable via `bf list-roles --pack <id>`. Lint will fail otherwise.
- Each task spec's `Pipeline:` selects the **execution pipeline**. Doer/reviewer capabilities for execution stages live in the pipeline file, not in task frontmatter.
- `Requires-Worktree:` is required. Use `true` for tasks that change repository code or docs in a Git project; use `false` for planning, review-only, and non-repository work.
- `Branch:`, `Worktree:`, and `Pull-Request:` are harness-owned metadata. Keep them empty while drafting.
- `Pipeline:` may reference a selected pack pipeline or a bf-wo local pipeline under `<work-object>/pipelines/<id>.yml`.
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
- A task spec may lock an implementation detail only when that detail is part of
  the accepted user-facing contract or required Evidence. Otherwise, state the
  outcome and leave the detail to execution design.

## Exit

Spec Authoring ends after `accept` returns success. Move to [execution.md](execution.md).
