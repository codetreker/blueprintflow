# Execution

Goal: drive one accepted BF work object to `Completed` through harness gates.

## Phase Gate

Before any implementation, fix, commit, push, PR, or cleanup:

1. Read `bf.md`.
2. Report `bf.md.State` and the next legal action.
3. If `bf.md.State` is `Draft`, stop. Execution is illegal before Spec Review succeeds and `bf-harness accept <bf-wo>` runs.
4. If `bf.md.State` is `Accepted` or `Implementing`, run the task loop. Let `bf-harness next <bf-wo>` select eligible task blocks.
5. If `bf.md.State` is `Completed`, do not implement. Report status. Task cleanup should already have run at task closure.

User approval to continue does not replace harness transitions. Continue means: run the next legal BF command.

## Hard Gates

- The coordinator is the main session. It runs `next`, assigns or resumes task drivers, reruns task `verify` after task-driver handoff, merges task PRs, runs task `complete`, runs task-scoped `cleanup`, runs Final Acceptance review, runs Final Acceptance `verify`, runs Final Acceptance `complete`, and owns actor lifecycle accounting.
- Using `$bf` or `/bf` is explicit authorization for BF-scoped host-compatible task drivers, leaf workers, and independent reviewers. It does not authorize skipping harness gates.
- Do not edit project files for a BF task until `bf-harness next <bf-wo>` returns that task block.
- Do not inspect all task specs to choose work. The harness selects the task batch.
- At task entry, a task driver first reads `roles/task-driver.md`, then reads only the spec and pipeline for its returned task block.
- If the task has `Requires-Worktree: true`, work only in the returned or recorded `Worktree`.
- Assign claimed task work and verification fixes to a host-compatible task driver. The coordinator does not do task leaf work unless the user explicitly overrides this gate.
- A task driver may run task review and readiness verification when the host runtime supports it. The coordinator still reruns task `verify` before merge, `complete`, and `cleanup`.
- When starting a task driver, leaf worker, or reviewer, pass the role instruction path and require that actor to read its own role instruction first. Do not read, summarize, or inline the role instruction for that actor.
- Reviewers must be different actor instances from the actor whose work is reviewed.
- If accepted scope, boundary, acceptance, or design intent is unclear, read `discussion.md`. If the answer is still missing, append the ambiguity and stop for clarification.
- For project design-doc discovery, authority, or drift handling, follow `project-docs.md`.
- If accepted design authority conflicts with implementation reality, record the drift and stop for clarification.
- Do not edit locked `bf.md` or task `spec.md` fields. Only the harness changes state, AC checkboxes, timestamps, and task execution metadata.

## Task Loop

Repeat until no task remains:

1. Run `bf-harness next <bf-wo>`.
2. If `next` returns no eligible task, enter Final Acceptance. Do not manually pick a task.
3. If `next` returns task blocks, do not read task specs or pipelines locally.
4. Each returned task gets one task driver. The coordinator decides whether that block starts a new driver or resumes an existing one.
5. Give each task driver the returned task block, the BF work-object id, the returned worktree if any, and the instruction to read its own role, spec, and pipeline. Use the Task Driver Prompt Template.
6. Wait until each task driver reports completion. Give it enough time to finish and do not terminate it lightly.
7. If the task driver reports a blocker, read the blocker and take the coordinator action it requested, or stop for user clarification.
8. Rerun `bf-harness verify <bf-wo>/<task>` after task-driver handoff.
9. On FAIL, read the verify result, prefer the original task driver for task implementation, evidence, or AC fixes, require a fresh review round with fresh independent reviewers after fixes, and verify again.
10. On SUCCESS, merge the task PR when the task produced a PR.
11. Run `bf-harness complete <bf-wo>/<task>`.
12. Run `bf-harness cleanup <bf-wo>/<task>` after `complete` succeeds and any task PR is merged.
13. Report retained task worktrees or branches. Do not force-delete them.
14. Return to step 1.

## Task Driver Prompt Template

Use this template when starting or resuming a task driver. Replace placeholders from `bf-harness next <bf-wo>` and the current BF context. Paste the complete task block returned by `bf-harness next`; do not summarize it.

```text
First, read your role instruction: `roles/task-driver.md`.

You are task-driver, working on <bf-wo>/<task-id>.

BF work object: <bf-wo>
Task block:
<paste the complete task block returned by `bf-harness next`>
Worktree: <worktree from the task block, or none>
Resume context: <existing driver context, or new task>

Instructions:
1. After reading `roles/task-driver.md`, work only on this returned task.
2. If a Worktree is provided, run commands from that Worktree.
3. Read this task's `spec.md` and selected pipeline.
4. Follow the pipeline stages in order and produce every required Evidence artifact.
5. Open and record the task PR when the task requires one.
6. Run or coordinate task review and readiness verify when the host runtime allows it. Use independent reviewers.
7. If fixes are required after review or verify, complete the fixes, start a fresh review round with fresh independent reviewers, and verify again.
8. Do not merge PRs, run `bf-harness complete`, run cleanup, or perform Final Acceptance.
9. Do not edit locked `bf.md` or task `spec.md` fields.
10. If blocked, stop and report the blocker, evidence already produced, and the exact coordinator action needed.
11. When complete, report changed files, evidence artifacts, validation output, review round, verify output, commit or branch, PR URL if any, retained risks, and whether task-local terminal-state closure evidence is ready.
```

## Final Acceptance

Start Final Acceptance by running `bf-harness status <bf-wo>`. Continue only when status says all tasks are completed.

1. Check whole-work-object terminal-state closure.
2. Run `bf-harness start-review <bf-wo>`.
3. Dispatch independent reviewers for the `bf.md` AC capabilities.
4. Run `bf-harness verify <bf-wo>`.
5. On FAIL, read the verify result, fix through the appropriate task driver or coordinator-owned action, start a fresh review round with fresh independent reviewers, and verify again.
6. On SUCCESS, run `bf-harness complete <bf-wo>`.
7. Report completion. Do not defer task worktree cleanup to Final Acceptance.

## Pipeline promotion suggestions

After Final Acceptance, you may note that a bf-wo local pipeline appears reusable. This is advisory only.

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
- Confirm required checks, reviews, and blocking conversations are clear or explicitly pending.

## Stop Conditions

Stop instead of continuing when:

- `bf.md.State` is `Draft` and the request is to execute, fix, commit, push, PR, or cleanup.
- Final Acceptance status does not say all tasks are completed.
- You are about to choose a task by reading task specs instead of using `next`.
- Current directory is not the recorded task worktree for a worktree-required task.
- A completed task with a merged PR still has its recorded worktree or branch.
- `next` reports Git, worktree, metadata, dependency, or phase conflict.
- Review or verify returns FAIL and the next fix owner, fresh review round, or verification retry is unclear.
- Required evidence is missing or mismatched.
- The accepted contract is ambiguous and `discussion.md` does not answer it.
- A task remains blocked on the same AC across 3 or more verification rounds.
- Task cleanup retains a dirty worktree, path conflict, checked-out branch, or unmerged branch.
