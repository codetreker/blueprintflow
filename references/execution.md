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

- The coordinator is the main session. It owns harness command sequencing, task-driver assignment or resume, coordinator-only closure gates, Final Acceptance gates, and actor lifecycle accounting.
- Using `$bf` or `/bf` is explicit authorization for BF-scoped host-compatible task drivers, leaf workers, and independent reviewers. It does not authorize skipping harness gates.
- Do not edit project files for a BF task until `bf-harness next <bf-wo>` returns that task block.
- Do not inspect all task specs to choose work. The harness selects the task batch.
- At task entry, a task driver first reads `roles/task-driver.md`, runs the startup capability check, then reads only the spec and pipeline for its returned task block.
- Do not read task specs or pipelines locally as coordinator for returned task blocks.
- If the task has `Requires-Worktree: true`, work only in the returned or recorded `Worktree`.
- Assign claimed task work and verification fixes to a host-compatible task driver. The coordinator does not do task leaf work unless the user explicitly overrides this gate or task-driver proxy mode is active after a missing subagent tool report.
- When starting a task driver, leaf worker, or reviewer, pass the role instruction path and require that actor to read its own role instruction first. Do not read, summarize, or inline the role instruction for that actor.
- Reviewers must be different actor instances from the actor whose work is reviewed. When multiple reviewers cover the same scope, also give each a distinct review lens rather than identical prompts; the distinct-lens rule is in addition to the distinct-actor-instance rule, not a replacement for it.
- If accepted scope, boundary, acceptance, or design intent is unclear, read `discussion.md`. If the answer is still missing, append the ambiguity and stop for clarification.
- For project design-doc discovery, authority, or drift handling, follow `project-docs.md`.
- If accepted design authority conflicts with implementation reality, record the drift and stop for clarification.
- Before asking the user to choose between materially different execution, review, verification, PR, closure, or design-drift paths, present a concise decision brief. Name the decision, relevant context and current evidence, realistic options, tradeoffs or consequences, and a recommendation when evidence supports one. Present the relevant plan, design, diff, or artifact content inline or as a faithful, decision-sufficient summary; a bare file or path pointer may supplement it but must not replace the shown content. Lightweight prompts remain valid for simple factual clarifications, status updates, and obvious yes/no confirmations.
- Task drivers, leaf workers, and reviewers do not ask the user directly from delegated BF work. When delegated work needs a material user decision, the actor stops and returns decision-brief input to the coordinator plus the exact coordinator action needed.
- Do not edit locked `bf.md` or task `spec.md` fields. Only the harness changes state, AC checkboxes, timestamps, and task execution metadata.

## Task Loop

Repeat until no task remains:

1. Run `bf-harness next <bf-wo>`.
2. If `next` returns no eligible task, enter Final Acceptance. Do not manually pick a task.
3. If `next` returns task blocks, assign one task driver to each returned task while normal delegation is available. Each returned task gets one task driver, either new or resumed by coordinator decision.
4. Give each task driver the returned task block, the BF work-object id, the returned worktree if any, and the instruction to read its own role, spec, and pipeline. Use the Task Driver Prompt Template.
5. For review-only pipelines such as engineering `code-deep-audit`, the task driver produces the audit evidence, command evidence, findings triage, and closure artifacts named by the pipeline and task spec without changing the audited code.
6. Wait for each newly started task driver to report its startup capability check before starting other returned task blocks.
7. If a task driver reports missing subagent tool, enter task-driver proxy mode for that task. Defer other returned task blocks and serially perform the task-driver responsibilities for the proxied task before returning to `next`.
8. Wait until each task driver reports completion. Give it enough time to finish and do not terminate it lightly.
9. If the task driver reports a blocker, read the blocker and take the coordinator action it requested, or stop for user clarification. If the blocker includes decision-brief input to the coordinator, present the user-facing decision brief before asking the user to choose.
10. Rerun `bf-harness verify <bf-wo>/<task>` after task-driver handoff.
11. On FAIL, read the verify result and return it to the original task driver. If that instance is no longer running, start a new task driver for the same task block, pass it the prior evidence and the verify result, and note the handoff (next-round reviewers must still be distinct instances per IV).
12. Return to that task driver's handoff and wait for completion before rerunning verify.
13. On SUCCESS, merge the task PR when the task produced a PR.
14. Run `bf-harness complete <bf-wo>/<task>`.
15. Run `bf-harness cleanup <bf-wo>/<task>` after `complete` succeeds and any task PR is merged.
16. Report retained task worktrees or branches. Do not force-delete them.
17. Return to step 1.

Steps 13, 15, and 16 above are the default `per-task-pr` (Mode A) flow. Under `Integration: single-pr` (Mode B) the task loop differs:

- There is NO per-task PR to merge at step 13: every task is a commit on the shared branch `bf/<bf-wo>`, collected into the ONE WO-level PR. The task driver commits its work to the shared branch with a `BF-Task: <bf-wo>/<task>` trailer and pushes; the harness rejects `complete <bf-wo>/<task>` unless a trailered, pushed, non-empty, non-reverted commit for that task exists on `bf/<bf-wo>`.
- The ONE WO-level PR on `bf/<bf-wo>` must be open and recorded BEFORE the first task-level `complete <bf-wo>/<task>` — the commit-presence gate requires the WO PR to be present and OPEN (not yet merged). Ownership and timing: after the first worktree task driver pushes its trailered commit to `bf/<bf-wo>`, the coordinator opens the single WO PR on `bf/<bf-wo>` and records it with `bf-harness attach-pr <bf-wo>/<task> <pr-url>` (pass any `Requires-Worktree: true` task id of this work object; the PR head must be `bf/<bf-wo>`). Do not open per-task PRs and do not open a second WO PR. The WO PR stays OPEN through every task completion and merges only at Final Acceptance.
- There is NO per-task worktree cleanup at steps 15-16: the shared worktree and branch are retained until WO scope (`cleanup <bf-wo>/<task>` is a no-op that reports the retention). Cleaning per task would discard other tasks' in-flight commits on the shared branch.
- The single WO PR merges ONCE at Final Acceptance, and the shared worktree is cleaned at WO scope after the work object completes.

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
1. After reading `roles/task-driver.md`, work only on this returned task. The task block's `Integration` field states the work-object mode: `per-task-pr` (Mode A — open/record a per-task PR) or `single-pr` (Mode B — commit to the shared WO branch `bf/<bf-wo>` with the `BF-Task: <bf-wo>/<task>` trailer; do not open a per-task PR).
2. If a Worktree is provided, run commands from that Worktree.
3. Run the startup capability check from `roles/task-driver.md` before reading the task spec or selected pipeline.
4. If the startup check reports missing subagent tool, stop and request coordinator proxy.
5. Read this task's `spec.md` and selected pipeline only after the startup check passes.
6. Follow `roles/task-driver.md` for task execution, review, readiness verification, and handoff.
7. When blocked, report the blocker, evidence already produced, and the exact coordinator action needed.
8. When complete, report changed files, evidence artifacts, validation output, review round, verify output, commit or branch, PR URL if any, retained risks, and whether task-local terminal-state closure evidence is ready.

Boundaries:
- Do not work outside the returned task.
- Do not merge PRs, run `bf-harness complete`, run cleanup, or perform Final Acceptance.
- Do not edit locked `bf.md` or task `spec.md` fields.
```

## Final Acceptance

Start Final Acceptance by running `bf-harness status <bf-wo>`. Continue only when status says all tasks are completed.

1. Check whole-work-object terminal-state closure.
2. Run `bf-harness start-review <bf-wo>`.
3. Dispatch independent reviewers for the `bf.md` AC capabilities. When multiple reviewers cover the same scope, give each a distinct review lens rather than identical prompts, in addition to keeping them distinct actor instances.
4. Run `bf-harness verify <bf-wo>`.
5. On FAIL, read the verify result, fix through the appropriate task driver or coordinator-owned action, start a fresh review round with fresh independent reviewers, and verify again.
6. On SUCCESS, run `bf-harness complete <bf-wo>`.
7. Report completion. Do not defer task worktree cleanup to Final Acceptance.

Under `Integration: single-pr` (Mode B), Final Acceptance also merges and cleans at WO scope:

- Merge the ONE WO-level PR (`bf/<bf-wo>`) before `complete <bf-wo>`. The harness rejects `complete <bf-wo>` for a single-pr work object until that WO PR is merged onto the harness-owned `bf/<bf-wo>` head.
- After `complete <bf-wo>` succeeds and the WO PR is merged, run `bf-harness cleanup <bf-wo>` to remove the shared worktree and delete `bf/<bf-wo>`. This WO-scope cleanup runs only at WO completion, not per task.

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
