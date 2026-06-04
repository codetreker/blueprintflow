# Execution

Goal: loop until `bf-harness verify <bf-wo>` returns Final Acceptance SUCCESS.

## Outer loop (per task)

1. `bf-harness next <bf-wo>` — prints labeled lines for one ready task: `Task:`, `Pipeline:`, `Pipeline path:`, `Pack:`, `Spec:`, `Dir:`. The harness flips the returned task to `Tasking` and (on the first call) flips `bf.md` to `Implementing`. If no task is ready (deps unmet) `next` exits non-zero with an error message on stdout; wait or run `verify` first.
2. Read the returned pipeline file. Follow the top-level pipeline instruction first, then follow each stage instruction in order. Do not assume every stage requires a subagent; use one when the pipeline or stage instruction asks for one or when isolation/review quality requires it. Stop when a stage instruction says to stop, including any Blocker or High review finding.
3. The implementation stage reads the pack's `Execute Guidance`, the task spec, and every `Evidence` entry, makes the changes, and produces evidence artifacts that satisfy the locked evidence requirements (commits, command output, screenshots, reviewer notes, or named files).
4. `bf-harness start-review <bf-wo>/<task>` — returns the task-level round dir.
5. For each AC's review capability, spawn one or more **reviewer** subagents — **different subagent instances than the implementation doer** (IV — see SKILL.md). Each writes `result_<role>_<idx>.md` into the round dir.
6. `bf-harness verify <bf-wo>/<task>` (Task Verification). On FAIL, read the verify-result file, dispatch fixes (the same doer subagent or a new one), open a new review round, and re-verify. The task stays in `Tasking` until verify SUCCESS, at which point the harness flips its AC and sets `State: Completed`.

## Final acceptance

7. When all task `spec.md` are `Completed`, run one more bf-level review pass:
   1. `bf-harness start-review <bf-wo>` — spawn reviewers against the `bf.md` AC.
   2. `bf-harness verify <bf-wo>` (Final Acceptance). On SUCCESS the harness flips all `bf.md` AC and sets `State: Completed`.

## Pipeline promotion suggestions

After Final Acceptance succeeds, you may mention that a bf-wo local pipeline
appears reusable. This is advisory only.

You must not promote local pipelines, edit extension packs, create files, or
open a PR as part of execution completion. Promotion workflow starts only after
an explicit user request.

## Verify output contract

`verify` has three distinct outcomes; branch on exit code, not on stdout content:

- **SUCCESS**: stdout `SUCCESS <abs-path>`, exit 0. Path points at the `verify-result.md`.
- **Verification FAIL**: stdout `FAIL <abs-path>`, exit 1. Same path shape; the file records the issues.
- **Setup error** (wo not loadable, phase mismatch, no review round, malformed result): stderr `bf-harness verify: <message>`, exit 1, stdout empty. Read stderr to learn what to do next (e.g. run `start-review` first).

## Failure handling

- **Lint regression after a fix:** if a task spec edit during Task Verification causes lint to fail, the next `verify` will refuse to run. Fix lint first, then re-open a review round.
- **Evidence mismatch:** if the locked Evidence section is wrong or insufficient, stop and consult the user. Do not edit `spec.md` after accept to fit the implementation.
- **Stuck task:** if Task Verification keeps failing on the same AC across 3+ rounds, stop and consult the user. Do not silently rewrite the AC — the spec is locked content; only the harness flips checkboxes.
- **Dep blocking:** if `next` exits non-zero with a "no eligible task" message but no task is `Tasking`, run `bf-harness verify <bf-wo>` first — there may be a completed task whose state transition has not been picked up.
