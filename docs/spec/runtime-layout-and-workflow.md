# Runtime Layout And Workflow

This page describes the BF runtime file layout and the high-level workflow.
BF runtime state lives under a resolved state home. Git repositories use the
primary worktree `.bf`, linked worktrees included, and non-Git directories use
`<cwd>/.bf`. BF does not define `.tasks/` as a runtime directory for drafts,
design notes, or execution artifacts.

## Skill Directory Structure

```text
<root>/
  +- SKILL.md
  +- bin/
  |    +- lib/
  |    +- bf.mjs
  |    +- bf-harness.mjs
  +- packs/
  |    +- engineering/
  |    +- ...
  +- references/
  +- roles/
  +- ...
```

## Work Object Layout

New BF work objects live under `<state-home>/works/<bf-wo>/`. Legacy direct
`<state-home>/<bf-wo>/` work objects remain readable; if both layouts contain
the same id, `works/<bf-wo>` wins.

```text
<primary-worktree>/
  +- .bf/
  |    +- extensions/
  |    +- works/
  |         +- <bf-wo>/
  |              +- bf.md
  |              +- discussion.md
  |              +- runs/
  |              |    +- reviews/
  |              |         +- round_{N}/
  |              |              +- result_{role}_{idx}.md
  |              +- <task-id>/
  |                   +- runs/
  |                   |    +- reviews/
  |                   |         +- round_{N}/
  |                   |              +- result_{role}_{idx}.md
  |                   +- spec.md
  +- .worktrees/
       +- works/
            +- <bf-wo>/
                 +- <task-id>/
```

## Host Runtime Actor Model

The host runtime is the orchestration environment that runs BF. It is distinct
from the BF npm runtime and from the target project's application runtime.

BF core uses generic actor names:

- `coordinator`: the main session. The coordinator runs `next`, manages task
  assignment, records host-runtime strategy, accounts for actor lifecycle,
  dispatches BF acceptance reviewers, and owns Final Acceptance.
- `task driver`: an actor that executes one concrete task by following the
  selected task pipeline and producing a review-ready handoff.
- `leaf worker`: a bounded helper for one stage or artifact, used only when the
  current host runtime supports nested delegation from the current actor.
- `reviewer`: an independent actor that writes review results.

Claude Code `teammate` can be a task driver. Codex subagent can be a task
driver when the coordinator can track closure and capacity. Host-specific actor
names do not become BF core roles.

The coordinator runs `start-review` for Spec Review, Task Verification, and
Final Acceptance. The coordinator runs `verify` for Spec Review, Task
Verification, and Final Acceptance. Task drivers do not advance locked BF state.

## End-To-End Workflow

1. Brainstorm.
   - The LLM can be invoked by `/bf brainstorming`, `/bf 我们讨论一个方案`, or an equivalent user request.
   - Run `bf list-packs` to discover installed packs.
   - Select the pack that best fits the user's input.
   - Follow [`references/project-docs.md`](../../references/project-docs.md)
     to discover the project's design-doc root from project instructions,
     repository structure, prompts, workflows, and document content.
   - Record the doc-root discovery result in `discussion.md`. If a single root
     is inferred rather than explicit, ask the user to confirm it before
     treating it as authoritative.
   - Choose a readable kebab-case bf-wo id, create
     `<state-home>/works/<bf-wo>/`, copy `templates/discussion.md`, and append
     the first accepted discussion entry immediately.
   - Write `discussion.md` directly under `<state-home>/works/<bf-wo>/` so the discussion is crash-safe and restartable.
   - Confirm source coverage before spec authoring: recorded discussion must
     support the future `bf.md` Goal, Requirement, Acceptance Criteria,
     Boundary, and Task List rationale. Missing material can be added through
     user answers or accepted assistant-led proposals.

2. Write spec.
   - Run `bf list-roles --pack <pack>` to discover available roles and capabilities.
   - Run `bf list-pipelines --pack <pack>` to discover available task pipelines.
   - Treat confirmed project design docs as the external system design
     authority. If the work changes accepted system boundaries, module
     ownership, state authority, cross-module flows, validation boundaries, or
     known gaps, include design-doc update requirements in task AC and Evidence.
   - Write `bf.md` with `State: Draft`.
   - Create one directory per task and write `<task>/spec.md` with `State: Draft`.
   - Do not start task breakdown when `discussion.md` lacks source material for
     the concise contract. Return to brainstorm first.
   - Keep specs at contract granularity: task decomposition, scope, boundary,
     dependencies, ownership or handoff expectations, observable AC, and
     evidence intent. Do not require implementation design details before
     accept unless those details are accepted user-facing contract or required
     Evidence.
   - Each task spec selects exactly one `Pipeline`.
   - If no selected-pack pipeline fits, assign a `pipeline-designer` actor to
     design a bf-wo local pipeline under `<work-object>/pipelines/<id>.yml`.
   - Each task spec declares `Requires-Worktree: true|false`. Use `true` for
     tasks that change repository code or docs in a Git project; use `false`
     for planning, review-only, and non-repository work.
   - Continue discussion with the user until ambiguity is resolved.
   - Record the host-runtime strategy in `discussion.md`: host runtime, task
     driver type, nested-delegation limit, lifecycle or closure rule, and
     reviewer spawning owner.
   - Run `bf-harness lint <bf-wo>` until it returns success.
   - Run the spec review loop. Spec Review blocks contract gaps, not
     implementation investigation that belongs to task execution design stages.
   - After user approval, run `bf-harness accept <bf-wo>`.
   - After accept, `bf.md` and task `spec.md` content is locked for the LLM. The harness cascades tasks to `Ready`.

3. Execute tasks.
   - Run `bf-harness next <bf-wo>` to return eligible task blocks. Each returned
     task has completed prerequisites, and no returned task depends on another
     returned task.
   - Read only the returned task specs, packs, and pipeline paths.
   - Give each returned task block to one host-compatible task driver.
   - For `Requires-Worktree: true` tasks in managed Git mode, `next` also
     creates or validates branch `bf/<bf-wo>/<task-id>` and worktree
     `<primary-worktree>/.worktrees/works/<bf-wo>/<task-id>`.
   - Each host-compatible task driver must be assigned before claimed task leaf
     work starts. In Codex, that actor is a Codex subagent. The task driver
     follows the pipeline instruction and stage instructions and hands evidence
     back to the coordinator before BF acceptance review. If task-driver
     capacity or tooling is unavailable, the coordinator stops instead of doing
     leaf work unless the user explicitly overrides the delegation rule.
   - When accepted contract intent is unclear, read `discussion.md` before
     inventing scope. If it does not answer an ambiguity that affects scope,
     boundary, acceptance, or design intent, stop for clarification.
   - Use confirmed project design docs while executing. If code and confirmed
     design docs disagree, record design drift in `discussion.md` and stop for
     user clarification.
   - If implementation exposes a design gap in the accepted `bf.md` or task
     `spec.md`, stop implementation and return to design discussion instead of
     silently expanding locked scope.
   - Run acceptance-readiness terminal-state closure before task-level BF
     acceptance review. This task-level closure does not clean BF-owned task
     worktrees or task branches because Task Verification and the PR gate may
     still need them.
   - If the task has a GitHub PR, record it with
     `bf-harness attach-pr <bf-wo>/<task> <github-pr-url>`.
   - The coordinator runs `bf-harness start-review <bf-wo>/<task>`.
   - The coordinator dispatches independent reviewer actors to write review results.
   - The coordinator runs `bf-harness verify <bf-wo>/<task>` until the task verifies. For
     GitHub repositories, worktree-required task verification also checks that
     the recorded same-repository PR is merged. Non-GitHub providers remain
     process-gated by pipeline and review evidence.
   - If task verification fails, verification-fix work goes to the same task
     driver or a new task driver. The coordinator opens a new review round and
     reruns verification after the fix and independent review.
   - After task verification succeeds, run
     `bf-harness cleanup <bf-wo>/<task>` for that task after any task PR is
     merged. Retained dirty worktrees, unmerged branches, and path conflicts
     are reported, not force-deleted.
   - Before bf-level final acceptance, run `bf-harness status <bf-wo>`.
     Enter Final Acceptance only when status says all tasks are completed.
     Final Acceptance uses bf-level reviewers and existing harness verification;
     it does not add cross-task tracking of every task driver.
   - After Final Acceptance, the orchestrator may make an advisory note when a
     bf-wo local pipeline appears reusable. This is advisory only.
   - Execution completion must not promote local pipelines, edit extension packs,
     create files, or open a PR. Promotion starts only after an explicit user request.

## Spec Review Flow

1. Run `bf-harness start-review <bf-wo>`.
2. The command returns a review directory: `<work-object>/runs/reviews/round_N/`.
3. For each review capability used in the spec, select one matching provider role unless the accepted design explicitly needs multiple provider roles for distinct perspectives.
4. For each selected review role, dispatch exactly three independent reviewer actor instances. Every reviewer in the same Spec Review round must be a distinct actor instance.
5. If the bf-wo has local pipelines, include three independent reviewer actor instances with the `pipeline-review` capability. Each must be distinct from the pipeline designer and from every other reviewer in the same Spec Review round.
6. Each reviewer writes `result_<role>_<idx>.md`; `<idx>` starts at 1 for each selected role.
7. Run `bf-harness verify <bf-wo>`.
8. On `FAIL`, read the verify result, update the draft specs/local pipelines, and start a new review round.
9. On `SUCCESS`, wait for user approval before `accept`.

## Task Review Flow

Task review uses the same review-result file shape as spec review, scoped under:

```text
<work-object>/<task>/runs/reviews/round_N/
```

Task review must satisfy Independent Verification: the actor whose work is
reviewed and the reviewer must be different actor instances.
