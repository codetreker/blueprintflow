# Runtime Layout And Workflow

This page describes the BF runtime file layout and the high-level workflow.
BF runtime state lives under `.bf/`. BF does not define `.tasks/` as a runtime
directory for drafts, design notes, or execution artifacts.

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

Every BF work object lives under `<project-root>/.bf/<bf-wo>/`.

```text
<bf-wo>/
  +- bf.md
  +- discussion.md
  +- runs/
  |    +- reviews/
  |         +- round_{N}/
  |              +- result_{role}_{idx}.md
  +- <task-id>/
  |    +- runs/
  |    |    +- reviews/
  |    |    |    +- round_{N}/
  |    |    |         +- result_{role}_{idx}.md
  |    |    +- ...
  |    +- spec.md
  |    +- more files
```

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
   - Write `discussion.md` directly under `<project-root>/.bf/<bf-wo>/` so the discussion is crash-safe and restartable.

2. Write spec.
   - Run `bf list-roles --pack <pack>` to discover available roles and capabilities.
   - Run `bf list-pipelines --pack <pack>` to discover available task pipelines.
   - Treat confirmed project design docs as the external system design
     authority. If the work changes accepted system boundaries, module
     ownership, state authority, cross-module flows, validation boundaries, or
     known gaps, include design-doc update requirements in task AC and Evidence.
   - Write `bf.md` with `State: Draft`.
   - Create one directory per task and write `<task>/spec.md` with `State: Draft`.
   - Keep specs at contract granularity: task decomposition, scope, boundary,
     dependencies, ownership or handoff expectations, observable AC, and
     evidence intent. Do not require implementation design details before
     accept unless those details are accepted user-facing contract or required
     Evidence.
   - Each task spec selects exactly one `Pipeline`.
   - If no selected-pack pipeline fits, spawn a `pipeline-designer` subagent to
     design a bf-wo local pipeline under `<bf-wo>/pipelines/<id>.yml`.
   - Continue discussion with the user until ambiguity is resolved.
   - Run `bf-harness lint <bf-wo>` until it returns success.
   - Run the spec review loop. Spec Review blocks contract gaps, not
     implementation investigation that belongs to task execution design stages.
   - After user approval, run `bf-harness accept <bf-wo>`.
   - After accept, `bf.md` and task `spec.md` content is locked for the LLM. The harness cascades tasks to `Ready`.

3. Execute tasks.
   - Run `bf-harness next <bf-wo>` to claim the next eligible task.
   - Read the returned task spec, pack, and pipeline path.
   - Follow the pipeline instruction and stage instructions.
   - Use confirmed project design docs while executing. If code and confirmed
     design docs disagree, record design drift in `discussion.md` and stop for
     user clarification.
   - If implementation exposes a design gap in the accepted `bf.md` or task
     `spec.md`, stop implementation and return to design discussion instead of
     silently expanding locked scope.
   - Run `bf-harness start-review <bf-wo>/<task>`.
   - Spawn independent reviewer subagents to write review results.
   - Run `bf-harness verify <bf-wo>/<task>` until the task verifies.
   - After all tasks complete, run bf-level final acceptance.
   - After Final Acceptance, the orchestrator may make an advisory note when a
     bf-wo local pipeline appears reusable. This is advisory only.
   - Execution completion must not promote local pipelines, edit extension packs,
     create files, or open a PR. Promotion starts only after an explicit user request.

## Spec Review Flow

1. Run `bf-harness start-review <bf-wo>`.
2. The command returns a review directory: `<bf-wo>/runs/reviews/round_N/`.
3. For each matching reviewer role, spawn one to three subagents, capped at ten total subagents.
4. If the bf-wo has local pipelines, include an independent `pipeline-review` reviewer.
5. Each reviewer writes `result_<role>_<idx>.md`; `<idx>` starts at 1 for each role.
6. Run `bf-harness verify <bf-wo>`.
7. On `FAIL`, read the verify result, update the draft specs/local pipelines, and start a new review round.
8. On `SUCCESS`, wait for user approval before `accept`.

## Task Review Flow

Task review uses the same review-result file shape as spec review, scoped under:

```text
<bf-wo>/<task>/runs/reviews/round_N/
```

Task review must satisfy Independent Verification: the task doer and task
reviewer must be different subagent instances.
