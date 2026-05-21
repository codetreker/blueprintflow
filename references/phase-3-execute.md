# Phase 3 — Execute

Goal: loop until `bf-harness verify <bf-wo>` returns Mode C SUCCESS.

## Outer loop (per task)

1. `bf-harness next <bf-wo>` — returns one ready task with `capability_required`, `candidate_roles`, spec path, and pack id. The harness flips the returned task to `Tasking` and (on the first call) flips `bf.md` to `Implementing`. If no task is ready (deps unmet) it returns `ok: false`; wait or `verify` first.
2. Pick one `candidate_role` and spawn a **doer** subagent of that role. Doer reads the pack's `Execute Guidance` and the task spec, makes the changes, and produces evidence (commits, test output, screenshots).
3. `bf-harness start-review <bf-wo>/<task>` — returns the task-level round dir.
4. For each AC's review capability, spawn one or more **reviewer** subagents — **different subagent instances than the doer** (IV — see SKILL.md). Each writes `result_<role>_<idx>.md` into the round dir.
5. `bf-harness verify <bf-wo>/<task>` (Mode B). On FAIL, read the verify-result file, dispatch fixes (the same doer subagent or a new one), open a new review round, and re-verify. The task stays in `Tasking` until verify SUCCESS, at which point the harness flips its AC and sets `State: Completed`.

## Final acceptance (Mode C)

6. When all task `spec.md` are `Completed`, run one more bf-level review pass:
   1. `bf-harness start-review <bf-wo>` — spawn reviewers against the `bf.md` AC.
   2. `bf-harness verify <bf-wo>` (Mode C). On SUCCESS the harness flips all `bf.md` AC and sets `State: Completed`.

## Verify output contract

`verify` always prints exactly one line: `SUCCESS <abs-path>` or `FAIL <abs-path>`. The path points at a `verify-result.md` you can hand to a subagent verbatim. Do not parse anything else from stdout.

## Failure handling

- **Lint regression after a fix:** if a task spec edit during Mode B causes lint to fail, the next `verify` will refuse to run. Fix lint first, then re-open a review round.
- **Stuck task:** if Mode B keeps failing on the same AC across 3+ rounds, stop and consult the user. Do not silently rewrite the AC — the spec is locked content; only the harness flips checkboxes.
- **Dep blocking:** if `next` returns `ok: false` because deps are unmet but no task is `Tasking`, run `bf-harness verify <bf-wo>` first — there may be a completed task whose state transition has not been picked up.
