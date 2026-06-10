# Execution

Goal: drive one accepted BF work object to `Completed` through harness gates.

## Phase Gate

Before any implementation, fix, commit, push, PR, or cleanup:

1. Read `bf.md`.
2. Report `bf.md.State` and the next legal action.
3. If `bf.md.State` is `Draft`, stop. Execution is illegal before Spec Review
   succeeds and `bf-harness accept <bf-wo>` runs.
4. If `bf.md.State` is `Accepted` or `Implementing`, run the task loop. Let
   `bf-harness next <bf-wo>` select the task.
5. If `bf.md.State` is `Completed`, do not implement. Report status. Task
   cleanup should already have run at task closure.

User approval to continue does not replace harness transitions. Continue means:
run the next legal BF command.

## Hard Gates

- The coordinator is the main session. It runs `next`, `start-review`, `verify`,
  Final Acceptance, cleanup, reviewer dispatch, and actor lifecycle accounting.
- Using `$bf` or `/bf` is explicit authorization for BF-scoped
  host-compatible task drivers, leaf workers, and independent reviewers. It
  does not authorize skipping harness gates.
- Do not edit project files for a BF task until `bf-harness next <bf-wo>`
  returns that task.
- Do not inspect all task specs to choose work. The harness selects the task.
- Read a task spec only after `next` returns that task.
- If the task has `Requires-Worktree: true`, work only in the returned or
  recorded `Worktree`.
- Assign claimed task work and verification fixes to a host-compatible task
  driver. The coordinator does not do task leaf work unless the user explicitly
  overrides this gate.
- Reviewers must be different actor instances from the actor whose work is
  reviewed.
- If accepted scope, boundary, acceptance, or design intent is unclear, read
  `discussion.md`. If the answer is still missing, append the ambiguity and
  stop for clarification.
- For project design-doc discovery, authority, or drift handling, follow
  `project-docs.md`.
- If accepted design authority conflicts with implementation reality, record
  the drift and stop for clarification.
- Do not edit locked `bf.md` or task `spec.md` fields. Only the harness changes
  state, AC checkboxes, timestamps, and task execution metadata.

## Task Loop

Repeat until no task remains:

1. Run `bf-harness next <bf-wo>`.
2. If `next` returns no eligible task, stop and run Final Acceptance only when
   `bf-harness status <bf-wo>` says all tasks are completed. Do not manually
   pick a task.
3. Read only the returned task `spec.md` and pipeline.
4. Give the returned task, spec, pipeline, and worktree to a task driver.
5. The task driver follows the pipeline and produces required evidence.
6. If the task has a PR, run
   `bf-harness attach-pr <bf-wo>/<task> <github-pr-url>`.
7. Check task-local terminal-state closure before BF acceptance review. Do not
   clean BF-owned task worktrees or task branches before verification.
8. Run `bf-harness start-review <bf-wo>/<task>`.
9. Dispatch independent BF acceptance reviewers for the task AC capabilities.
10. Run `bf-harness verify <bf-wo>/<task>`.
11. On FAIL, read the verify result, dispatch fixes to a task driver, open a new
   review round, and verify again.
12. On SUCCESS, confirm the task PR is merged when the task produced a PR.
13. Run `bf-harness cleanup <bf-wo>/<task>` immediately after the task is
   verified and any task PR is merged. It removes only the recorded task
   worktree and uses safe local branch deletion.
14. Report retained task worktrees or branches. Do not force-delete them.
15. Return to step 1.

## Final Acceptance

Before Final Acceptance, run `bf-harness status <bf-wo>`. Enter Final
Acceptance only when status says all tasks are completed.

1. Check whole-work-object terminal-state closure.
2. Run `bf-harness start-review <bf-wo>`.
3. Dispatch independent reviewers for the `bf.md` AC capabilities.
4. Run `bf-harness verify <bf-wo>`.
5. On SUCCESS, report completion. Do not defer task worktree cleanup to Final
   Acceptance.

## Pipeline promotion suggestions

After Final Acceptance, you may note that a bf-wo local pipeline appears
reusable. This is advisory only.

Without an explicit user request:

- You must not promote local pipelines.
- You must not edit extension packs.
- You must not create files.
- You must not open a PR.

## PR Readiness

Before opening or updating a PR:

- Name the BF work object id and current state.
- Record task verification evidence or explain why BF was not required.
- Record validation evidence.
- Confirm required checks, reviews, and blocking conversations are clear or
  explicitly pending.

## Stop Conditions

Stop instead of continuing when:

- `bf.md.State` is `Draft` and the request is to execute, fix, commit, push, PR,
  or cleanup.
- No task has been claimed by `bf-harness next`.
- You are about to choose a task by reading task specs instead of using `next`.
- Current directory is not the recorded task worktree for a worktree-required
  task.
- A verified task with a merged PR still has its recorded worktree or branch.
- `next` reports Git, worktree, metadata, dependency, or phase conflict.
- Review or verify returns FAIL.
- Required evidence is missing or mismatched.
- The accepted contract is ambiguous and `discussion.md` does not answer it.
- A task remains blocked on the same AC across 3 or more verification rounds.
- Task cleanup retains a dirty worktree, path conflict, checked-out branch, or
  unmerged branch.
