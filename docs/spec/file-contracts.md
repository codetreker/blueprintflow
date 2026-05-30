# File Contracts

This page records the durable BF file contracts. Exact frontmatter fields,
section shapes, and comment rules live in `templates/`.

## Task Shape

Each task is a child directory of `<bf-wo>/`:

```text
<bf-wo>/<task-id>/
  spec.md
  runs/
  ...
```

`spec.md` is the task contract: goal, scope, acceptance criteria, evidence
requirements, and selected execution pipeline.

## bf.md

- Location: `<project-root>/.bf/<bf-wo>/bf.md`
- Role: structured work-order contract.
- Template: [`templates/bf.md`](../../templates/bf.md)
- State values: `Draft`, `Accepted`, `Implementing`, `Completed`.
- Acceptance Criteria lines must carry `{id}|{capability}` markers.
- Each AC capability must be declared by some role.
- After accept, only the harness may mutate checkbox state, `State`, and `Updated`.

## discussion.md

- Location: `<project-root>/.bf/<bf-wo>/discussion.md`
- Role: brainstorm and spec rationale archive.
- Template: [`templates/discussion.md`](../../templates/discussion.md)
- Locking: never locked; appendable throughout the work order.
- Relationship: `bf.md` is derived from `discussion.md`.

## `<task-id>/spec.md`

- Location: `<project-root>/.bf/<bf-wo>/<task-id>/spec.md`
- Role: task-level contract.
- Template: [`templates/task-spec.md`](../../templates/task-spec.md)
- State values: `Draft`, `Ready`, `Tasking`, `Completed`.
- The `Pipeline` field must reference a pipeline in the selected pack.
- Task frontmatter must not contain execution `Capability`.
- Acceptance Criteria lines carry `{id}|{capability}` review markers.
- `## Evidence` is required.
- Each task AC must have at least one Evidence entry.
- Evidence entries use `{evidence-id}|{ac-id}|{kind}: requirement`.
- Evidence ids are unique within the task.
- Evidence AC references must point to AC ids in the same task spec.
- Evidence kind is one of `command`, `file`, `artifact`, `review-note`, or `screenshot`.
- Evidence requirement text must be non-empty.
- After accept, only the harness may mutate checkbox state, `State`, and `Updated`.

## Review Result

- Location for bf-level review: `<bf-wo>/runs/reviews/round_N/result_<role>_<idx>.md`
- Location for task-level review: `<bf-wo>/<task>/runs/reviews/round_N/result_<role>_<idx>.md`
- Role: one reviewer subagent's result for one review round.
- Template: [`templates/review-result.md`](../../templates/review-result.md)
- Multiple same-role reviewers in one round use different `idx` values starting at 1.
- `## Results` must group findings by severity: Blocker, High, Minor, Nit.
- `## Accepted Criteria` may only reference AC ids that exist in the reviewed scope.

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
