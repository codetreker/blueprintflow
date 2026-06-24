---
Id: <readable work-object id; match the bf-wo directory name, kebab-case recommended>
Desc: <one sentence describing what this work should accomplish>
Pack: <pack id; must appear in bf list-packs output>
State: Draft|Accepted|Implementing|Completed
# Integration: per-task-pr|single-pr
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

<!--
frontmatter field notes:

- Id / Desc / Pack / State: required.
- Integration: Optional. Selects how tasks reach the trunk. Omit (or `per-task-pr`)
  for the default — one branch/worktree/PR per task. Set `single-pr` to collect all
  tasks as commits on one shared branch into ONE work-object PR; pick it by task
  coupling, not size, and only when at least one task is `Requires-Worktree: true`.
  Decide at task-decomposition time. Spec-authored,
  then accept-locked: bf-harness writes a harness-owned `Mode-Lock:` anchor at accept
  and rejects any later change of the effective mode. The LLM never writes `Mode-Lock`.
- Creation / Updated: timestamps; `Updated` is harness-synchronized after accept.
-->

# Goal

The overall goal for this work. Use one or two sentences to state what must be
achieved.

## Requirement

Required outcomes. Each item should be observable by the user, not an
implementation detail.

## Acceptance Criteria

Acceptance criteria for the whole blueprint.

Format rules:
- Use a markdown checkbox list. Pending items use `[ ]`; accepted items use `[x]`.
- Checkbox state is changed by bf-harness during verify. The LLM must not edit it directly.
- Each item includes a stable id, such as AC-1 or AC-2, and the capability needed to review that criterion.
- bf-harness uses the capability to find roles that declare it and route review to the matching role.

- [ ] {id1}|{capability}: One independently verifiable acceptance criterion
- [ ] {id2}|{capability}: Another acceptance criterion

## Boundary

State what is explicitly out of scope for this work. This section keeps task
breakdown focused and lets reviewers judge whether a task has crossed the
accepted boundary.

## Design

High-level design discussion for the work as a whole — orientation, not detailed implementation design. State the overall solution shape and the key cross-cutting decisions that justify the task breakdown: the main approach, the major components or areas touched and how they fit together, and the significant alternatives weighed with the reason for the chosen direction. Length scales with the work — brief for a small change, fuller for a complex one; size it to the actual scope, not a fixed length. Stay at the altitude that explains *why these tasks*; leave exact files, interfaces, flags, and implementation sequence to each task's execution-stage design.

## Task List

An ordered dependency index, not a place for descriptions. Order tasks by execution sequence; put dependencies after a colon, comma-separated. Each task's scope and design live in its `<task-id>/spec.md`, not here — keep ids self-descriptive enough to read order and topic at a glance.

- task-id-1
- task-id-2
- task-id-3: task-id-1, task-id-2
