# Execution

Goal: loop until `bf-harness verify <bf-wo>` returns Final Acceptance SUCCESS.

## Outer loop (per task)

1. `bf-harness next <bf-wo>` — prints labeled lines for one ready task: `Task:`, `Pipeline:`, `Pipeline path:`, `Pack:`, `Spec:`, `Dir:`, and for worktree-required tasks also `Branch:` and `Worktree:`. The harness flips the returned task to `Tasking` and (on the first call) flips `bf.md` to `Implementing`. For `Requires-Worktree: true` tasks in managed Git mode, `next` creates branch `bf/<bf-wo>/<task-id>` from `origin/HEAD`, creates worktree `<primary-worktree>/.worktrees/works/<bf-wo>/<task-id>`, and records task-level `Branch:` / `Worktree:` metadata before claiming. For `Requires-Worktree: false` tasks, `next` does not create or require execution metadata. If no task is ready (deps unmet), Git setup is unavailable, or existing branch/worktree/metadata conflicts with the expected task, `next` exits non-zero before contract mutation.
2. Read the returned pipeline file. Follow the top-level pipeline instruction first, then follow each stage instruction in order. Do not assume every stage requires a subagent; use one when the pipeline or stage instruction asks for one or when isolation/review quality requires it. Stop when a stage instruction says to stop, including any Blocker or High review finding.
3. Follow [project-docs.md](project-docs.md) during execution. If code and confirmed design docs disagree, record design drift and stop for user clarification. If implementation exposes a design gap in the accepted contract, stop and return to design discussion.
4. The implementation stage reads the pack's `Execute Guidance`, the task spec, and every `Evidence` entry, makes the changes, and produces evidence artifacts that satisfy the locked evidence requirements (commits, command output, screenshots, reviewer notes, or named files).
5. If a worktree-required task has a GitHub PR, run `bf-harness attach-pr <bf-wo>/<task> <github-pr-url>` after the task is claimed. The harness records task-level `Pull-Request:` only for a `Tasking` task with `Requires-Worktree: true`, matching `Branch:` / `Worktree:` metadata, and a PR from the same GitHub repository.
6. `bf-harness start-review <bf-wo>/<task>` — returns the task-level round dir.
7. For each AC's review capability, spawn one or more **reviewer** subagents — **different subagent instances than the implementation doer** (IV — see SKILL.md). Each writes `result_<role>_<idx>.md` into the round dir.
8. `bf-harness verify <bf-wo>/<task>` (Task Verification). On FAIL, read the verify-result file, dispatch fixes (the same doer subagent or a new one), open a new review round, and re-verify. For GitHub repositories, worktree-required task verification also requires recorded same-repository `Pull-Request:` metadata and confirms the PR is merged. Non-GitHub providers remain pipeline/process gated; the harness does not mechanically check provider completion there. The task stays in `Tasking` until verify SUCCESS, at which point the harness flips its AC and sets `State: Completed`.

## Final acceptance

9. When all task `spec.md` are `Completed`, run one more bf-level review pass:
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
- **Managed Git setup conflict:** if `next` fails because Git setup is
  unavailable or branch/worktree/metadata conflicts with the expected task,
  stop. Do not edit `Branch`, `Worktree`, or `Pull-Request` by hand, do not
  delete or clean up branches/worktrees automatically, and do not continue the
  task in another directory. Repair the Git environment only when the intended
  state is clear; otherwise ask the user. Rerun `next` only after the
  branch/worktree/metadata match the expected task.
- **Evidence mismatch:** if the locked Evidence section is wrong or insufficient, stop and consult the user. Do not edit `spec.md` after accept to fit the implementation.
- **Stuck task:** if Task Verification keeps failing on the same AC across 3+ rounds, stop and consult the user. Do not silently rewrite the AC — the spec is locked content; only the harness flips checkboxes.
- **Dep blocking:** if `next` exits non-zero with a "no eligible task" message but no task is `Tasking`, run `bf-harness verify <bf-wo>` first — there may be a completed task whose state transition has not been picked up.
