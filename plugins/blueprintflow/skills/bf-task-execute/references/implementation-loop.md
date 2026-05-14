# Implementation Loop

Use inside `bf-task-execute` after four-piece and implementation design are ready.

## Inputs

- `task.md`
- `spec.md`
- `stance.md`
- `acceptance.md`
- `design.md` for code tasks
- `docs/tasks/README.md` Active Task Resume row
- cited `docs/blueprint/next` anchors

## Loop

1. Confirm worktree/branch from `bf-git-workflow`.
2. Read task inputs and write a short local implementation checklist in `progress.md`.
3. Change code/docs only inside task scope.
4. Update `docs/current` through `bf-current-doc-standard` when current behavior changes.
5. Run targeted local verification before PR open.
6. Record commands, failures, fixes, and remaining blockers in `progress.md`.
7. Commit coherent checkpoints to the task branch.
8. Hand back to Teamlead with `READY_FOR_PR`, `HOLD`, or `BLOCK`. Teamlead opens the PR only for `READY_FOR_PR`.

## Test Selection

| Change | Minimum local evidence before PR |
|---|---|
| UI | component/unit checks plus `bf-verification` UI reference when runnable |
| API/server | targeted unit/integration/API checks |
| Data/migration | migration apply plus data assertions |
| CLI/operator | command success and failure cases |
| Background job | trigger, processing, retry/failure case |
| Docs-only | link/render/lint check when available |

## Progress Checkpoint

Add or update this in `progress.md`:

```markdown
## Implementation Evidence

| Item | Evidence | Result |
|---|---|---|
| Scope check | task/spec/design reviewed | PASS |
| Local verification | <command/test> | PASS / HOLD / BLOCK |
| Current-doc sync | <path or N/A - reason> | PASS |
| Acceptance evidence | <acceptance.md/progress.md section> | PASS / HOLD / BLOCK |
```

## Handoff To PR Open

Required:
- implementation matches `task.md` and `design.md`
- acceptance evidence block exists
- current-doc sync is done or has explicit N/A reason
- known blockers are recorded with owner and next action
- no task scope expansion without returning to milestone progress or blueprint iteration

`HOLD` or `BLOCK` returns to Teamlead for dispatch; it is not PR-ready.
