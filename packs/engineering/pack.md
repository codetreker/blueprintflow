---
Id: engineering
Desc: Software engineering work — new features, bug fixes, refactors, libraries, CLIs, APIs.
---

## When to Use

Pick this pack when the work product is source code: a new feature, a bug fix, a refactor, a new library / CLI / API surface, or an infrastructure-as-code change. If the user's request resolves to "change a codebase and ship the diff", this is the pack.

Not for: pure research write-ups, content production, incident response runbooks — those should live in other packs.

## Domain Vocabulary

- **bf-wo** — a single blueprint work object (one directory under `<project-root>/.bf/`).
- **bf.md** — the blueprint contract; locked after `accept`.
- **task spec.md** — per-task contract; locked after `accept`.
- **AC (Acceptance Criterion)** — one checkbox on bf.md or a task spec; carries a stable id and a `capability` marker.
- **Pipeline** — a named execution flow selected by task `Pipeline:` frontmatter and defined under `pipelines/*.yml`.
- **Capability** — a string declared in a role's `Capabilities:` list; pipeline stages use it to pick stage owners, and AC use it to pick reviewers.
- **coordinator** — the main session that owns BF harness commands, acceptance review setup, verification, final acceptance, and host actor lifecycle accounting.
- **task driver** — the actor that executes one concrete task by following its selected pipeline and producing a review-ready handoff.
- **leaf worker** — a bounded helper for one stage or artifact, used only when the host runtime supports delegation from the current actor.
- **reviewer** — an independent actor that reviews a task, artifact, or spec and writes review results.
- **IV (Independent Verification)** — the same actor instance must not both produce work and review that work for the same task.
- **Mutation whitelist** — the only edits the harness will make to locked files: flip AC `[ ]` → `[x]`, update `State`, sync `Updated`.

## Brainstorm Guidance

The architect facilitates this phase. Before any breakdown, drive the discussion to nail down:

- **Target users / callers**: who calls this code, in what environment?
- **In scope vs. out of scope**: what is explicitly NOT being built this round? (This becomes `Boundary` in bf.md.)
- **Quality bars**: performance budget, security posture, backward-compat / API stability promises.
- **Evidence shape**: what tests / runs / screenshots will count as "done"? (Pushes the user to write falsifiable AC.)
- **Constraints from the existing codebase**: language, framework, lint/test toolchain, conventions to follow.

Before writing `bf.md`, confirm `discussion.md` has source coverage for the
Goal, Requirement, Acceptance Criteria, Boundary, and Task List rationale. You
may propose missing material and append it to `discussion.md`, but only user
answers or accepted proposals become source material for the contract.

The bf.md that comes out should have a tight Goal (one or two sentences), a Requirements list that a user could observe, AC that are checkable from the outside, and a Boundary that names at least one tempting-but-deferred adjacent thing.

Anti-patterns to avoid:
- AC that describe the implementation ("uses async/await") instead of the outcome.
- Goals that bundle two unrelated features (split into two bf-wo).
- A Boundary section left empty — usually means scope was not actually discussed.

## Breakdown Guidance

The architect decomposes the accepted Goal/Boundary into a task DAG. A good engineering task:

- Is roughly 1 PR in size — small enough that one host-compatible task driver can finish it and produce evidence in a single session.
- Has a `Pipeline` in its frontmatter. Use `bf list-pipelines --pack engineering` and pick the narrowest matching execution flow.
- Has explicit `depends` edges in `bf.md`'s Task List — no implicit ordering.
- Has AC that are observable from outside the task (a file exists, a command exits 0, a test passes, an endpoint returns X).
- Names what it does not do in its own `Boundary`.
- Defines a scope contract, not implementation design. Lock what the task must
  accomplish, who owns it, what it hands off, and how it will be accepted; leave
  exact file paths, command flags, internal API shapes, and implementation
  sequence to the selected pipeline's design stages unless the user already made
  those details part of the accepted contract.

Typical patterns:

- **Parser → writer → command**: when adding a new CLI subcommand, separate parsing the input format, writing the output, and wiring it into the command surface.
- **Tests live with the code**: each task includes its own tests; do not create a "write all tests" task at the end.
- **One module per task** is a reasonable default; split if a single module has two unrelated AC.
- **Refactor before feature**: if the new feature needs a shape the code does not have yet, the refactor is its own task with its own AC (e.g. "no behavior change; existing tests still pass").

## Spec Review Guidance

Review the task DAG and specs as contracts. Block unclear ownership, missing
handoffs, broken dependencies, overlapping tasks, vague boundaries,
unobservable AC, missing Evidence, and user-visible requirements with no task
owner. Do not block only because repository investigation or implementation
strategy remains for the task pipeline's architecture/design stages.

## Execute Guidance

For each task the task driver picks up:

1. Read the pipeline file returned by `bf-harness next`, then read `<task>/spec.md` end-to-end, plus the Goal/Boundary slice of `bf.md` and the relevant parts of `discussion.md` when the spec is ambiguous.
2. Follow the pipeline stages in order. Produce each named artifact or pipeline review result before moving to the next stage. Use leaf workers only when the host-runtime strategy allows the current actor to spawn them.
3. Prefer TDD where it fits: write the failing test that encodes one AC, then make it pass.
4. Commit per task with a descriptive message that names the task id.
5. Evidence to produce:
   - Test output (the command and its result) for every AC that claims behavior.
   - The commit hash(es) for the change.
   - For UI work, a screenshot or an HTML snapshot.
6. Never bypass the mutation whitelist: locked `bf.md` and `spec.md` bodies are off-limits. Only the harness flips checkboxes, State, and Updated.
7. When the spec is ambiguous and `discussion.md` does not answer it, append a clarifying entry to `discussion.md` and stop to ask the user — do not invent contract.
8. When done, hand a review-ready package back to the coordinator: summary, changed artifacts, Evidence outputs, pipeline review outputs, and closure evidence. The coordinator runs `start-review`, dispatches BF acceptance reviewers, and runs `verify`.

## Phase Roles

This pack maps BF's phases to specific Core roles. **Capabilities are skills, not activities** — a phase is the activity (planning, executing, reviewing), and the right role for that phase is the one whose *skills* (capabilities) fit the work. For engineering, the planning phase needs system-architecture skill, so the architect runs it.

| Phase | Role(s) | Capability the phase needs |
|---|---|---|
| Brainstorm | architect | system-architecture |
| Spec / breakdown (write bf.md + task specs) | architect | system-architecture |
| Spec Review | architect, tester | design-review, quality-assurance |
| Execute (per task; pipeline stages) | architect, engineer, tester | stage capability from task Pipeline |
| Task Verification (reviewer) | tester | quality-assurance (or AC's capability marker) |
| Final Acceptance | architect, tester | design-review, quality-assurance |

Independent Verification still applies: the *actor instance* whose work is reviewed cannot be the reviewer for that work (different instances of the same role are OK).
