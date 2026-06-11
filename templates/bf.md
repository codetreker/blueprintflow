---
Id: <readable work-object id; match the bf-wo directory name, kebab-case recommended>
Desc: <one sentence describing what this work should accomplish>
Pack: <pack id; must appear in bf list-packs output>
State: Draft|Accepted|Implementing|Completed
Creation: <yyyy-mm-dd hh:MM>
Updated: <yyyy-mm-dd hh:MM>
---

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

## Task List

Task list. Order tasks by execution sequence. Put dependencies after a colon;
separate multiple dependencies with commas.

- task-id-1
- task-id-2
- task-id-3: task-id-1, task-id-2   // task-id-3 depends on both task-id-1 and task-id-2
