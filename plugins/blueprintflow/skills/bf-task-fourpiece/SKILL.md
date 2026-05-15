---
name: bf-task-fourpiece
description: "Part of the Blueprintflow methodology. Use when a reviewed task.md exists, concrete task work is starting, and task baseline docs are missing."
---

# Task Four-Piece

Create the task baseline docs. Do not start implementation.

## Direct Invocation Guard

If `using-plueprint` is not active, STOP here. Load `using-plueprint` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use when all are true:

- The milestone is `TASK_SET_READY` or the task is starting.
- The task folder exists under `docs/tasks/<phase>/<milestone>/<task>/`.
- `task.md` exists and was reviewed by milestone breakdown.
- The four-piece baseline docs do not exist or need repair before code starts.

## Outputs

Create or repair only these task baseline docs:

| File | Owner | Required content |
|---|---|---|
| `spec.md` | Architect | Spec brief sections 0-4 only: constraints, segmentation, carry-over, reverse checks, out-of-scope |
| `stance.md` | PM | 5-7 stances anchored to blueprint sections, with constraints and blacklist grep |
| `acceptance.md` | QA | Acceptance checks aligned 1:1 with spec segments |
| `content-lock.md` | PM | UI text/DOM literal locks, UI tasks only |

Do not create `design.md`, implementation files, task PR state, worktree state, or merge/cleanup instructions in this skill.

## Steps

1. Read `task.md` first.
2. Read the cited locked next-blueprint anchors.
3. Create `spec.md` from the task scope, anchors, out-of-scope, dependencies, and acceptance slice.
4. Create `stance.md` from the locked product stance and explicit anti-constraints.
5. Create `acceptance.md` aligned with `spec.md` segments.
6. Create `content-lock.md` only when the task changes UI copy or DOM literals.
7. Cross-check the four files against each other and against `task.md`.
8. Record the handoff: four-piece baseline ready; code-facing design is next.

## Checks

- Every four-piece file cites the relevant blueprint anchor or task contract section.
- `acceptance.md` has one checkable outcome per spec segment.
- `stance.md` names what the task is not allowed to become.
- `content-lock.md` is absent or explicit; no empty placeholder file.
- No file broadens the reviewed `task.md` scope.

## Anti-patterns

- Skipping one of the required baseline files.
- Rewriting `task.md` inside this skill; send scope changes back to milestone breakdown.
- Writing implementation design or code here.
- Writing PR, worktree, branch, merge, or cleanup procedure here.
- Treating a milestone as the task scope.

## How to invoke

```
follow skill bf-task-fourpiece
```
