# Spec Authoring

Goal: produce a locked `bf.md` + one `<task-id>/spec.md` per task, with every AC reviewed and accepted by the user.

## Phase Gate

Before role lookup, pipeline lookup, `bf.md` drafting, task spec drafting, local pipeline drafting, lint, Spec Review, or `accept`:

1. Read `discussion.md`.
2. Report discussion source coverage for Goal, Requirement, Acceptance Criteria, Boundary, and Task List rationale.
3. If any source material is missing, do not write `bf.md` or task specs. Return to [brainstorm.md](brainstorm.md), append the missing question, decision, or proposal to `discussion.md`, and continue only after the gap is resolved.
4. Continue only when source coverage is complete and the user explicitly agreed to enter spec authoring.

## User Decision Briefs

Before asking the user to choose between materially different spec-authoring paths, present a concise decision brief. Name the decision, relevant context and current evidence, realistic options, tradeoffs or consequences, and a recommendation when evidence supports one. Present the relevant plan, design, diff, or artifact content inline or as a faithful, decision-sufficient summary; a bare file or path pointer may supplement it but must not replace the shown content.

Use decision briefs for material user decision gates such as entering spec authoring, resolving contract gaps, choosing provider roles when the choice changes review coverage, handling design-doc authority conflicts, and deciding whether to accept the reviewed contract. Lightweight prompts remain valid for simple factual clarifications, status updates, and obvious yes/no confirmations where the context is already clear.

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

## Discussion Source Coverage

Before authoring `bf.md`, verify that discussion.md contains source material for
the concise contract: Goal, Requirement, Acceptance Criteria, Boundary, and Task
List rationale. The source material may be direct user input or a confirmed or
accepted assistant proposal.

If source material is missing, stop before task breakdown. Return to
brainstorm, append the missing question, decision, or proposal to
`discussion.md`, and continue only after the gap is resolved.

This traceability does not belong in the contract text. bf.md must not cite or quote discussion.md by default. It should distill the recorded discussion into a short scope contract.

## Steps

1. `bf list-roles --pack <id>` — get the available roles and the capabilities they provide.
2. `bf list-pipelines --pack <id>` — get the available task execution pipelines for this pack.
3. Follow [project-docs.md](project-docs.md). If confirmed project design docs exist, treat them as design authority while drafting. If the work changes accepted system design, add design-doc update AC and Evidence to the relevant task specs.
4. Confirm discussion source coverage before task breakdown. Do not author `bf.md` until the coverage check is satisfied.
5. Author `bf.md` with `State: Draft` using `templates/bf.md`. Every AC must carry `{id}|{capability}`, and the capability must be declared in some role's `Capabilities:` list. Decide the optional `Integration` mode here (default `per-task-pr`; set `single-pr` only for a cohesive or phased change that should be reviewed as ONE PR **and** with at least one `Requires-Worktree: true` task — finalize the choice once the task specs in step 6 are drafted). The mode is **accept-locked** and cannot change later; record the rationale in `discussion.md`. See the engineering pack's *Integration mode* guidance.
6. Author each `<task>/spec.md` with `State: Draft` using `templates/task-spec.md`. Each task spec has exactly one `Pipeline`, a required `Requires-Worktree: true|false`, empty `Branch` / `Worktree` / `Pull-Request` metadata, AC lines with their own `{capability}` markers (review capability), and an explicit `Evidence` section that maps each task AC to one or more required evidence items. Keep the task spec at contract granularity; leave detailed design to the task pipeline.
7. If no pack pipeline fits a task, create a bf-wo local pipeline under `<work-object>/pipelines/<id>.yml`. The local pipeline must be designed by a `pipeline-designer` actor. The designer must include terminal-state closure for every external artifact or side effect the pipeline creates, so the pipeline cannot reach user-perspective completion with dangling work. The parent orchestrator may only make mechanical path/format fixes; substantive stage, gate, capability, artifact, closure, handoff, or stop-condition changes go back to the designer.
8. `bf-harness lint <bf-wo>` — fix every error and re-run until SUCCESS.
9. Record the **host-runtime strategy** in `discussion.md` before Spec Review:
   host runtime, task driver type, nested-delegation limit, lifecycle or
   closure rule, and reviewer spawning owner. Use generic BF actor names in the
   contract; map host-specific names such as Claude Code `teammate` or
   `Codex subagent` only as runtime guidance.
10. **Spec Review loop:**
   1. `bf-harness start-review <bf-wo>` — returns the round directory `<work-object>/runs/reviews/round_N/`.
   2. For each review capability used in the spec, select one provider role from `bf list-roles --pack <id>` unless the accepted design explicitly needs multiple provider roles for distinct perspectives.
   3. For each selected review role, dispatch exactly three independent reviewer actor instances. Every reviewer in the same spec review round must be a distinct actor instance. Give each reviewer covering the same scope a distinct review lens — a different angle to attack the spec from — rather than identical prompts; this is in addition to the distinct-actor-instance rule, not a replacement for it. Each reviewer writes `result_<role>_<idx>.md` into the round dir using `templates/review-result.md`; `<idx>` starts at 1 for each selected role.
   4. If the bf-wo has local pipelines, include three independent reviewer actor instances with the `pipeline-review` capability. Each `pipeline-review` reviewer must be a different actor instance from the pipeline designer and from every other reviewer in the same Spec Review round. The reviewers must reject any bf-wo local pipeline that creates external artifacts or side effects without a terminal-state closure path, handoff, or explicit stop condition for dangling work.
   5. Tell reviewers to reject contract gaps, not missing implementation-design detail. A reviewer may reject a detail that is already locked and wrong, but must not require file-level investigation before `accept` when the selected pipeline owns that design work.
   6. `bf-harness verify <bf-wo>` (Spec Review) — `SUCCESS <path>` or `FAIL <path>`. On FAIL, read the verify-result file, fix `bf.md` / `spec.md` / local pipelines, then start a new round.
11. When verify returns SUCCESS and the user agrees with the plan, `bf-harness accept <bf-wo>`. `bf.md` → `Accepted`; all tasks cascade `Draft` → `Ready`. **Contract is now locked.**

## Mutation whitelist after accept

After accept, you MUST NEVER edit State, AC checkboxes, Updated, task execution metadata (Branch/Worktree/Pull-Request), or the work-object `Integration` mode and its harness-owned `Mode-Lock` anchor in `bf.md` / `spec.md` directly — only the harness writes those. You continue to write `discussion.md`, review results, and code. If a locked field looks wrong, STOP and route the change through the harness command or the coordinator; do not hand-edit it, even to fix an obvious error. If the integration mode itself must change after accept, stop and escalate to the user: the harness wrote `Mode-Lock` at accept and rejects a changed (or anchor-deleted) mode with `INTEGRATION_LOCKED`; the recovery is a new work object, not a hand-edit.

## Authoring rules

- Every AC capability must be discoverable via `bf list-roles --pack <id>`. Lint will fail otherwise.
- Each task spec's `Pipeline:` selects the **execution pipeline**. Stage-owner and reviewer capabilities for execution stages live in the pipeline file, not in task frontmatter.
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
