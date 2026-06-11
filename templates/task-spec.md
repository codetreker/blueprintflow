---
State: Draft|Ready|Tasking|Completed
Pipeline: <pipeline id>
Pack: <pack id>
Desc: <one sentence describing the task>
Requires-Worktree: true|false
Branch:
Worktree:
Pull-Request:
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

<!--
frontmatter field notes:

- State: Owned by bf-harness. The LLM must not edit it directly.
- Pipeline: The execution flow for this task. It must appear in `bf list-pipelines --pack <pack id>` output.
- Pack: Must match the owning `bf.md` Pack.
- Desc: One-sentence description that lets the task driver quickly understand the task.
- Requires-Worktree: Strictly use `true` or `false`. In a Git project, use `true` for tasks that modify repository code or docs; use `false` for planning, review-only, or non-repository tasks.
- Branch / Worktree / Pull-Request: Harness-owned execution metadata. Keep these empty in Draft/Ready specs. The LLM does not edit them directly.
-->

# Task

The task scope contract. State what this task must accomplish, who owns which
part of the scope, who receives the handoff, and what state counts as done.
This is not detailed implementation design. Exact files, command flags,
internal API shapes, migration strategy, and implementation sequence belong in
execution-stage design artifacts unless they are already accepted user-facing
contract details or required Evidence.

## Requirements

- Specific requirements this task must satisfy
- Each item should be externally observable
- Do not turn unverified implementation details into requirements; write observable outcomes and boundaries

## Acceptance Criteria

Acceptance criteria for this task.

Use the same format as `bf.md`: stable id + capability marker + acceptance
criterion description.

Distinguish these two concepts:
- The `Pipeline` in frontmatter is the execution flow that tells task drivers and reviewers which pipeline to follow.
- The capability on each AC line is the review capability needed to verify that criterion.
- Execution-stage owner capabilities are defined by pipeline stages. Task specs no longer carry one execution `Capability`.

- [ ] {id1}|{capability}: Acceptance criterion 1
- [ ] {id2}|{capability}: Acceptance criterion 2

## Evidence

Each task AC must have at least one evidence requirement. Evidence is the
acceptance-evidence contract written during spec and locked after accept.
Execution can produce evidence, but cannot change these requirements.

Format rules:
- The `## Evidence` section is required and must not be omitted.
- Use a markdown list.
- Each item includes a stable id, corresponding AC id, evidence kind, and evidence requirement.
- Evidence ids must be unique within the task spec.
- The corresponding AC id must exist in this task's `Acceptance Criteria`.
- Evidence kind must be one of `command`, `file`, `artifact`, `review-note`, or `screenshot`.
- Evidence requirement text must be non-empty.

- {evidence-id}|{ac-id}|{kind}: Evidence requirement
- EV-1|AC-1|command: bash test/run-all.sh
- EV-2|AC-2|review-note: reviewer confirms the edge case manually

## Boundary

State what is explicitly out of scope for this task. If the task driver
encounters an ambiguous boundary during execution, check this section first.
If this section does not clarify owner, handoff, or terminal state, spec review
should require clarification.
