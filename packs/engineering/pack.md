---
Id: engineering
Desc: Software engineering work — new features, bug fixes, refactors, libraries, CLIs, APIs.
---

## When to Use

Pick this pack when the work product is source code: a new feature, a bug fix, a refactor, a new library / CLI / API surface, or an infrastructure-as-code change. If the user's request resolves to "change a codebase and ship the diff", this is the pack.

Not for: pure research write-ups, content production, incident response runbooks — those should live in other packs.

## Domain Vocabulary

- **bf-wo** — a single blueprint work object. In normal project work, new work objects live under the primary BF state home at `works/<bf-wo>`; legacy direct `<bf-wo>` directories remain readable.
- **bf.md** — the blueprint contract; locked after `accept`.
- **task spec.md** — per-task contract; locked after `accept`.
- **AC (Acceptance Criterion)** — one checkbox on bf.md or a task spec; carries a stable id and a `capability` marker.
- **Pipeline** — a named execution flow selected by task `Pipeline:` frontmatter and defined under `pipelines/*.yml`.
- **Capability** — a string declared in a role's `Capabilities:` list; pipeline stages use it to pick stage owners, and AC use it to pick reviewers.
- **security-review** — Core security role capability for security baseline review, security-relevant task review, and security AC signoff.
- **coordinator** — the main session that owns task assignment, final task verification, PR merge, harness completion, task cleanup, Final Acceptance, and host actor lifecycle accounting.
- **task driver** — the role-bound actor that executes one concrete task by following its selected pipeline and producing an acceptance-ready handoff. In Codex, this is a Codex subagent assigned to the claimed task.
- **leaf worker** — a bounded helper for one stage or artifact, used only when the host runtime supports delegation from the current actor.
- **reviewer** — an independent actor that reviews a task, artifact, or spec and writes review results.
- **IV (Independent Verification)** — the same actor instance must not both produce work and review that work for the same task.
- **Mutation whitelist** — the only edits the harness will make to locked files: flip AC `[ ]` → `[x]`, update `State`, sync `Updated`, and write task execution metadata.
- **Task worktree contract** — task frontmatter that records whether a task needs an isolated Git worktree and, when applicable, the branch/worktree/PR used to complete it. `Requires-Worktree` is spec-authored and locked after accept; `Branch`, `Worktree`, and `Pull-Request` are harness-owned task execution metadata.

## Brainstorm Guidance

The architect facilitates this phase. Before any breakdown, drive the discussion to nail down:

- **Target users / callers**: who calls this code, in what environment?
- **In scope vs. out of scope**: what is explicitly NOT being built this round? (This becomes `Boundary` in bf.md.)
- **Quality bars**: performance budget, security posture, backward-compat / API stability promises.
- **Evidence shape**: what tests / runs / screenshots will count as "done"? (Pushes the user to write falsifiable AC.)
- **Constraints from the existing codebase**: language, framework, lint/test toolchain, conventions to follow.

Before writing `bf.md`, confirm `discussion.md` has source coverage for the Goal, Requirement, Acceptance Criteria, Boundary, and Task List rationale.
You may propose missing material and append it to `discussion.md`, but only user answers or accepted proposals become source material for the contract.

Record source material so spec authoring can later produce a tight Goal (one or two sentences), a Requirements list that a user could observe, AC that are checkable from the outside, and a Boundary that names at least one tempting-but-deferred adjacent thing.

Anti-patterns to avoid:
- AC that describe the implementation ("uses async/await") instead of the outcome.
- Goals that bundle two unrelated features (split into two bf-wo).
- A Boundary section left empty — usually means scope was not actually discussed.

## Breakdown Guidance

The architect decomposes the accepted Goal/Boundary into a task DAG. A good engineering task:

- Is roughly 1 PR in size — small enough that one host-compatible task driver can finish it and produce evidence in a single session.
- Has a `Pipeline` in its frontmatter. Use `bf list-pipelines --pack engineering` and pick the narrowest matching execution flow.
- Uses `code-deep-audit` only for review-only deep codebase audits. That pipeline reports evidence and findings; it does not fix findings or replace BF Task Verification.
- Has `Requires-Worktree: true|false`. Use `true` for tasks that change repository code or docs in a Git project; use `false` for planning, review-only, or non-repository work.
- Has explicit `depends` edges in `bf.md`'s Task List — no implicit ordering.
- Has AC that are observable from outside the task (a file exists, a command exits 0, a test passes, an endpoint returns X).
- Names what it does not do in its own `Boundary`.
- Defines a scope contract, not implementation design.
  Lock what the task must accomplish, who owns it, what it hands off, and how it will be accepted; leave exact file paths, command flags, internal API shapes, and implementation sequence to the selected pipeline's design stages unless the user already made those details part of the accepted contract.

Typical patterns:

- **Parser → writer → command**: when adding a new CLI subcommand, separate parsing the input format, writing the output, and wiring it into the command surface.
- **Tests live with the code**: each task includes its own tests; do not create a "write all tests" task at the end.
- **One module per task** is a reasonable default; split if a single module has two unrelated AC.
- **Refactor before feature**: if the new feature needs a shape the code does not have yet, the refactor is its own task with its own AC (e.g. "no behavior change; existing tests still pass").

## Spec Review Guidance

Review the task DAG and specs as contracts.
Block unclear ownership, missing handoffs, broken dependencies, overlapping tasks, vague boundaries, unobservable AC, missing Evidence, and user-visible requirements with no task owner.
Do not block only because repository investigation or implementation strategy remains for the task pipeline's architecture/design stages.

## Execute Guidance

The coordinator assigns each claimed engineering task to a host-compatible task driver before implementation, refactor, test-fix, validation, or task-scoped docs work starts.
Start the actor with `roles/task-driver.md`; the task driver reads that role file itself.
If task-driver capacity or tooling is unavailable, stop instead of doing the leaf work in the coordinator unless the user explicitly overrides the delegation rule.
Verification-fix work goes to the same task driver or a new task driver. Prefer the original task driver when available.
The task driver runs task review and readiness verification when the host runtime supports it. After fixes, use a fresh review round with fresh independent reviewers.
The coordinator reruns task `verify` before merge, `complete`, and task-scoped cleanup.

For each task the task driver picks up:

1. Read the pipeline file returned by `bf-harness next`, then read `<task>/spec.md` end-to-end, plus the Goal/Boundary slice of `bf.md` and the relevant parts of `discussion.md` when the spec is ambiguous.
2. Follow the pipeline stages in order. Produce each named artifact or pipeline review result before moving to the next stage. Use leaf workers only when the host-runtime strategy allows the current actor to spawn them.
3. Prefer TDD where it fits: write the failing test that encodes one AC, then make it pass.
4. For `Requires-Worktree: true` tasks, work in the branch/worktree returned by `bf-harness next`. If a GitHub PR is created, record it with `bf-harness attach-pr <bf-wo>/<task> <github-pr-url>`. Non-GitHub providers are process-gated by the pipeline and reviewer evidence instead of mechanically checked by the harness.
5. Commit per task with a descriptive message that names the task id.
6. Evidence to produce:
   - Test output (the command and its result) for every AC that claims behavior.
   - The commit hash(es) for the change.
   - For UI work, a screenshot or an HTML snapshot.
7. Never bypass the mutation whitelist: locked `bf.md` and `spec.md` bodies are off-limits. Only the harness flips checkboxes, State, Updated, and task execution metadata.
8. When the spec is ambiguous and `discussion.md` does not answer it, append a clarifying entry to `discussion.md` and stop to ask the user — do not invent contract.
9. When done, hand an acceptance-ready package back to the coordinator: summary, changed artifacts, Evidence outputs, pipeline review outputs, task review round, verify output, PR URL if any, and closure evidence. The coordinator reruns `verify`, merges the task PR when present, runs `complete`, then runs task-scoped cleanup.

Built-in feature and bugfix pipelines include a `security-review` stage after code review and before terminal-state closure.
The security role owns that stage.
It stops on Blocker or High findings and records not-applicable evidence when the task has no security-relevant change.

## Phase Roles

This pack maps BF's phases to specific Core roles. **Capabilities are skills, not activities** — a phase is the activity (planning, executing, reviewing), and the right role for that phase is the one whose *skills* (capabilities) fit the work. For engineering, the planning phase needs system-architecture skill, so the architect runs it.

| Phase | Role(s) | Capability the phase needs |
|---|---|---|
| Brainstorm | architect | system-architecture |
| Spec / breakdown (write bf.md + task specs) | architect | system-architecture |
| Spec Review | architect, tester | design-review, quality-assurance |
| Execute (per task; pipeline stages) | architect, engineer, tester, security | stage capability from task Pipeline |
| Task Verification (reviewer) | tester, security | quality-assurance (or AC's capability marker) |
| Final Acceptance | architect, tester, security | design-review, quality-assurance, security-review |

Independent Verification still applies: the *actor instance* whose work is reviewed cannot be the reviewer for that work (different instances of the same role are OK).
