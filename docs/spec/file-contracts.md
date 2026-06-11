# File Contracts

This page records the durable BF file contracts. Exact frontmatter fields,
section shapes, and comment rules live in `templates/`. Shipped runtime
templates are English-language file shapes. They remain self-contained runtime
artifacts and do not depend on the `docs/` design record.

## Task Shape

Each task is a child directory of a BF work object under
`<state-home>/works/<bf-wo>/`.

```text
<state-home>/works/<bf-wo>/<task-id>/
  spec.md
  runs/
  ...
```

`spec.md` is the task contract: task goal, scope, boundary, dependencies,
handoff or terminal-state expectations, acceptance criteria, evidence
requirements, and selected execution pipeline. It is not implementation design.
File-level investigation, exact command flags, internal API shapes, migration
strategy, and implementation sequence belong to execution design unless they
are already accepted user-facing contract or required Evidence.

## bf.md

- Location: `<state-home>/works/<bf-wo>/bf.md` for new work objects.
- Role: structured work-object contract.
- Template: [`templates/bf.md`](../../templates/bf.md)
- State values: `Draft`, `Accepted`, `Implementing`, `Completed`.
- Acceptance Criteria lines must carry `{id}|{capability}` markers.
- Each AC capability must be declared by some role.
- After accept, only the harness may mutate checkbox state, `State`, and `Updated`.

## discussion.md

- Location: `<state-home>/works/<bf-wo>/discussion.md` for new work objects.
- Role: brainstorm and spec rationale archive.
- Template: [`templates/discussion.md`](../../templates/discussion.md)
- Locking: never locked; appendable throughout the work object.
- Relationship: `bf.md` is derived from `discussion.md`.

## `<task-id>/spec.md`

- Location: `<state-home>/works/<bf-wo>/<task-id>/spec.md` for new work objects.
- Role: task-level contract.
- Template: [`templates/task-spec.md`](../../templates/task-spec.md)
- State values: `Draft`, `Ready`, `Tasking`, `Completed`.
- The `Pipeline` field must reference a pipeline in the selected pack or a
  bf-wo local pipeline under `<state-home>/works/<bf-wo>/pipelines/<id>.yml`.
- The `Requires-Worktree` field is required and must be `true` or `false`.
  Use `true` for tasks that change repository code or docs in a Git project.
- `Branch`, `Worktree`, and `Pull-Request` are task execution metadata fields
  owned by the harness. They are empty in Draft/Ready specs and are populated
  only by `next` and `attach-pr`.
- Task frontmatter must not contain execution `Capability`.
- Acceptance Criteria lines carry `{id}|{capability}` review markers.
- `## Evidence` is required.
- Each task AC must have at least one Evidence entry.
- Evidence entries use `{evidence-id}|{ac-id}|{kind}: requirement`.
- Evidence ids are unique within the task.
- Evidence AC references must point to AC ids in the same task spec.
- Evidence kind is one of `command`, `file`, `artifact`, `review-note`, or `screenshot`.
- Evidence requirement text must be non-empty.
- After accept, only the harness may mutate checkbox state, `State`, `Updated`,
  and task execution metadata.
- Spec review rejects contract gaps such as unclear ownership, broken handoffs,
  vague boundaries, unobservable AC, or missing Evidence. It does not require
  detailed implementation design before accept when the selected pipeline owns
  that design work.

## Review Result

- Location for bf-level review: `<work-object>/runs/reviews/round_N/result_<role>_<idx>.md`
- Location for task-level review: `<work-object>/<task>/runs/reviews/round_N/result_<role>_<idx>.md`
- Role: one reviewer actor's result for one review round.
- Template: [`templates/review-result.md`](../../templates/review-result.md)
- Multiple same-role reviewers in one round use different `idx` values starting at 1.
- `## Results` must group findings by severity: Blocker, High, Minor, Nit.
- `## Accepted Criteria` may only reference AC ids that exist in the reviewed scope.
- For Task Verification and Final Acceptance, an AC is signed when at least one
  provider-role review file accepts that AC id and the round has no Blocker or
  High finding. Actor-instance independence is an orchestrator rule, not a
  filename field.

## Role

- Location: `roles/<role>.md` or `packs/<pack-id>/roles/<role>.md`
- Role: declare a role identity and capability list.
- Template: [`templates/role.md`](../../templates/role.md)
- Capabilities are implicitly registered by role files and used by lint/review selection.

## Pack

- Location: `packs/<pack-id>/pack.md`
- Role: describe a work domain and its phase guidance.
- Template: [`templates/pack.md`](../../templates/pack.md)

## Pipeline

- Location: `packs/<pack-id>/pipelines/<pipeline-id>.yml`
- Role: declare a task execution pipeline.
- The filename must be a valid pipeline id.
- The YAML `id` must match the filename.
- `desc` is shown by `bf list-pipelines`.
- Top-level `instruction` describes the whole pipeline.
- Each stage `instruction` describes that stage.
- `stages` are currently orchestrated by the LLM; later versions may migrate stage state and gates into the harness.

## BF-WO Local Pipeline

- Location: `<state-home>/works/<bf-wo>/pipelines/<pipeline-id>.yml`
- Role: declare a task execution pipeline usable only inside one bf-wo.
- Shape: same YAML shape as pack pipelines.
- Key constraints: filename and `id` match; `desc`, top-level `instruction`, and
  at least one stage are required; stage ids are unique; stage instructions are
  non-empty; stage capabilities must exist in the role registry.
- Locking: referenced local pipelines are contract files after accept.
