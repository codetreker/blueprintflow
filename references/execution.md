# Execution

Goal: loop until `bf-harness verify <bf-wo>` returns Final Acceptance SUCCESS.

## Host-runtime strategy

Before task execution, read `discussion.md` and record or confirm the
host-runtime strategy: host runtime, task driver type, nested-delegation limit,
lifecycle or closure rule, and reviewer spawning owner.

Use these actor boundaries:

- The **coordinator** is the main session. The coordinator runs `next`,
  `start-review`, task-level `verify`, bf-level Final Acceptance, and actor
  lifecycle accounting.
- A **task driver** may execute one concrete task by following its selected
  pipeline. The task driver produces artifacts, evidence, pipeline review
  outputs, closure evidence, and a review-ready handoff.
- A **leaf worker** is a bounded helper for one stage or artifact, used only
  when the host runtime supports that delegation from the current actor.
- A **reviewer** is an independent actor that writes review results.

Claude Code `teammate` and Codex subagent are host-specific task driver
implementations. If a task driver cannot spawn a nested worker or reviewer,
it hands that need back to the coordinator.

After `bf-harness next` claims a task, the coordinator must assign the claimed
task work to a host-compatible task driver before leaf work starts. In Codex,
that actor is a Codex subagent task driver for the claimed task. The coordinator
does not implement, test-fix, refactor, edit task-scoped code or docs, produce
task-driver-owned evidence, write task review results, or directly patch
verification findings for a claimed task. If task-driver capacity or tooling is
unavailable, stop instead of doing the leaf work in the coordinator unless the
user explicitly overrides the delegation rule.

## Outer loop (per task)

1. `bf-harness next <bf-wo>` — coordinator command. It prints labeled lines for one ready task: `Task:`, `Pipeline:`, `Pipeline path:`, `Pack:`, `Spec:`, `Dir:`, and for worktree-required tasks also `Branch:` and `Worktree:`. The harness flips the returned task to `Tasking` and (on the first call) flips `bf.md` to `Implementing`. For `Requires-Worktree: true` tasks in managed Git mode, `next` creates branch `bf/<bf-wo>/<task-id>` from `origin/HEAD`, creates worktree `<primary-worktree>/.worktrees/works/<bf-wo>/<task-id>`, and records task-level `Branch:` / `Worktree:` metadata before claiming. For `Requires-Worktree: false` tasks, `next` does not create or require execution metadata. If no task is ready (deps unmet), Git setup is unavailable, or existing branch/worktree/metadata conflicts with the expected task, `next` exits non-zero before contract mutation.
2. Assign a host-compatible task driver for the claimed task. The task driver reads the returned pipeline file and follows the top-level pipeline instruction first, then follows each stage instruction in order. Do not assume every stage requires a leaf worker; use one only when the pipeline or stage instruction asks for one and the host-runtime strategy allows the current actor to spawn it. Stop when a stage instruction says to stop, including any Blocker or High review finding.
3. When accepted contract intent is unclear, read discussion.md first. If
   it answers the ambiguity, proceed from the recorded answer. If it does not
   answer, and the ambiguity affects scope, boundary, acceptance, or design intent, append the ambiguity to `discussion.md` and stop for collaborative clarification.
4. Follow [project-docs.md](project-docs.md) during execution. If code and confirmed design docs disagree, record design drift and stop for user clarification. If implementation exposes a design gap in the accepted contract, stop and return to design discussion.
5. The implementation stage reads the pack's `Execute Guidance`, the task spec, and every `Evidence` entry, makes the changes, and produces evidence artifacts that satisfy the locked evidence requirements (commits, command output, screenshots, reviewer notes, or named files).
6. If a worktree-required task has a GitHub PR, run `bf-harness attach-pr <bf-wo>/<task> <github-pr-url>` after the task is claimed. The harness records task-level `Pull-Request:` only for a `Tasking` task with `Requires-Worktree: true`, matching `Branch:` / `Worktree:` metadata, and a PR from the same GitHub repository.
7. The task driver gives the coordinator a review-ready handoff: task summary, changed artifacts, Evidence outputs, pipeline review outputs, and any closure evidence or side-effect list.
8. Run acceptance-readiness terminal-state closure before BF acceptance review. The coordinator confirms every task-local external artifact or side effect has a terminal state, handoff owner, or explicit stop condition. If the side effect spans tasks or the whole work object, record it for bf-level Final Acceptance closure too.
9. `bf-harness start-review <bf-wo>/<task>` — coordinator command. It returns the task-level round dir.
10. Coordinator dispatches BF acceptance reviewers for each AC's review capability. Each reviewer must be a different actor instance than the actor whose work is reviewed (IV — see SKILL.md). Each writes `result_<role>_<idx>.md` into the round dir. If a task driver cannot spawn a needed independent reviewer, the coordinator dispatches that reviewer.
11. `bf-harness verify <bf-wo>/<task>` (Task Verification) — coordinator command. On FAIL, read the verify-result file. Verification-fix work is claimed task work: dispatch fixes to the same task driver or a new task driver, open a new review round, and re-verify. Do not patch the fix directly in the coordinator. For GitHub repositories, worktree-required task verification also requires recorded same-repository `Pull-Request:` metadata and confirms the PR is merged. Non-GitHub providers remain pipeline/process gated; the harness does not mechanically check provider completion there. The task stays in `Tasking` until verify SUCCESS, at which point the harness flips its AC and sets `State: Completed`.

## Final acceptance

12. When all task `spec.md` are `Completed`, run one more bf-level review pass:
   1. The coordinator confirms whole-work-object terminal-state closure for external artifacts or side effects that span tasks.
   2. `bf-harness start-review <bf-wo>` — coordinator command. Spawn reviewers against the `bf.md` AC.
   3. `bf-harness verify <bf-wo>` (Final Acceptance) — coordinator command. On SUCCESS the harness flips all `bf.md` AC and sets `State: Completed`.

Final Acceptance remains an integrative bf-level review. This runtime guidance
does not add a requirement to track every task driver across bf-level Final
Acceptance.

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
