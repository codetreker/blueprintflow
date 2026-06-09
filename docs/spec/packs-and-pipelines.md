# Packs And Pipelines

Packs are BF's domain extension model. A pack describes a domain or workflow
pattern, such as engineering, research, incident response, or content production.

## Directory Structure

```text
packs/
  +- engineering/
  |    +- pack.md           # required: pack description + phase guidance
  |    +- pipelines/        # optional: task execution pipelines
  |    |    +- bugfix.yml
  |    |    +- feature.yml
  |    +- roles/            # optional: pack-private roles
  |        +- designer.md
  +- research/
  +- ...
```

## pack.md

Each pack must have `pack.md`. The template is [`templates/pack.md`](../../templates/pack.md).

Sections:

1. `When to Use` is required. It describes which work fits this pack.
2. `Domain Vocabulary` defines domain terms and concepts.
3. `Brainstorm Guidance` tells the LLM what to ask and what the blueprint should look like.
4. `Breakdown Guidance` defines task size, dependency patterns, and task boundaries.
5. `Execute Guidance` gives task execution guidance, common patterns, and anti-patterns.

## Pack-Private Roles

Packs may define roles under `packs/<pack-id>/roles/`. Role files use the same
template as Core roles: [`templates/role.md`](../../templates/role.md).

Merge rules:

- `bf list-roles` merges Core roles and roles from the selected pack.
- Pack-private roles override Core roles with the same id.
- Global extension roles under `~/.bf/extensions/roles` override selected
  pack-private roles.
- Project extension roles under `<state-home>/extensions/roles` override
  global extension roles.
- The selected pack may use its private roles in brainstorm, spec, and execute phases.

Global extension packs live under `~/.bf/extensions/packs`. Project extension
packs live under `<state-home>/extensions/packs`; in normal Git work, that is
the primary worktree `.bf/extensions/packs`. Same-id packs merge into one
effective pack. `bf list-packs` returns every `pack.md` path in layer order:
Core, global extension, then project extension. The LLM reads all paths in
order; later paths have higher priority when guidance conflicts.

## Pack Pipelines

Packs may define pipelines under `packs/<pack-id>/pipelines/`.

Pipeline files use `<pipeline-id>.yml`. `bf list-pipelines --pack <id>` lists
pipelines from the effective pack layers. Same-id pipelines in higher-priority
extension layers override lower-priority pipelines.

The first pipeline version is instruction-only:

- The LLM reads the top-level pipeline `instruction`.
- The LLM follows stage `instruction` values in order.
- During execute, the coordinator assigns every claimed task and verification
  fix to a host-compatible task driver.
- Pipeline or stage instructions decide when task drivers, leaf workers, or
  reviewers are preferred or required.
- Pipeline state and stage gates may later move into the harness.

When a coordinator or task driver starts a role-bound actor, the prompt includes
the role id and role instruction file path. The actor must read that role
instruction before following the stage instruction. If the runtime cannot
guarantee local file access, the coordinator or task driver inlines the role
instruction content in the prompt.

Stage `capability` remains a single owner or coordinator capability. When a
review stage needs multiple perspectives, the pipeline records those
perspectives in the stage instruction instead of changing `capability` to an
array. For example, the built-in engineering `feature` pipeline keeps
`code-review.capability` as `quality-assurance` and asks the orchestrator to
gather implementation, architecture, and QA perspectives in the instruction.
Schema-level reviewer arrays are deferred until a pattern is stable and needs a
harness-enforced mechanical gate.

Built-in pack pipelines may include terminal-state closure stages. The built-in
engineering `feature` pipeline ends with `terminal-state-closure`, a
`quality-assurance` stage after `code-review`. That stage checks external
artifacts and side effects from the user's perspective and stops on dangling
work unless every item has reached a terminal state, has an explicit handoff
owner, or is blocked by an explicit stop condition. This remains an
instruction-level contract: BF does not add harness stage enforcement, infer side
effects, require a schema field, add new capabilities, or hard-code
merge/deploy/publish behavior.

Pipeline review, acceptance-readiness closure, and BF acceptance are separate
layers. Pipeline review checks task-driver artifacts such as architecture,
implementation design, code, tests, and evidence before the task is handed back
to the coordinator. Acceptance-readiness terminal-state closure checks whether
external artifacts and side effects are terminal, handed off, or explicitly
stopped before BF acceptance review starts. BF acceptance is the coordinator-run
`start-review` plus reviewer sign-off plus `verify` gate that can advance
locked task or bf state.

## Built-In Engineering Pipelines

The engineering pack ships separate pipelines for feature work and defect fixes.

`feature.yml` is design-first. It requires architecture/design artifacts,
pre-implementation review, implementation, design-doc sync when accepted system
design changes, task-appropriate validation, multi-perspective independent
review, and terminal-state closure. It does not require red-first TDD for every
feature task; the task contract chooses the evidence and validation boundary.
The accepted task spec supplies the scope contract. The pipeline's
architecture-design and implementation-design stages own file-level
investigation, exact commands, API shapes, migration strategy, and implementation
sequence unless those details were already accepted as user-facing contract or
required Evidence.

`bugfix.yml` is regression red-green. It requires a focused failing regression
test or reproduction before implementation, expected-failure review, the
smallest fix, a focused passing test, design-doc sync when the clarified path or
locked task scope changes accepted behavior contracts, validation, independent
review, and terminal-state closure. If the bug exposes design drift, the
pipeline stops for user clarification before changing docs.

Both pipelines read confirmed project design docs as external design authority.
Both require not-applicable evidence when design-doc sync or full validation is
outside the locked task boundary.

## BF-WO Local Pipelines

A bf-wo may define local pipelines under `<work-object>/pipelines/*.yml`. Tasks
in that bf-wo reference them with the normal `Pipeline:` frontmatter.

Rules:

- Local pipeline ids must not collide with the effective selected pack's pipeline ids.
- Every local pipeline must be referenced by at least one task.
- `pipelines` is a reserved task id.
- Local pipelines use the same YAML contract as pack pipelines.
- Local pipelines are contract files after Spec Review and `accept`.

Local pipeline design must account for terminal-state closure. When a pipeline
creates an external artifact or side effect, such as a PR, deploy, release,
ticket, published package, or handoff document, the pipeline must describe how
that item reaches a terminal state before the task is complete from the user's
perspective. The closure path can be a later stage, a named handoff owner, or an
explicit stop condition that prevents BF from treating dangling work as done.

Spec Review includes three independent reviewer subagents with the
`pipeline-review` capability for bf-wo local pipelines. Each reviewer is
distinct from the pipeline designer and from every other reviewer in the same
Spec Review round. The reviewers reject local pipelines that create external
artifacts or side effects without terminal-state closure. This is currently an
instruction-level contract: the harness does not infer side effects from
free-form YAML instructions, add a built-in merge stage, validate
project-specific PR body conventions, or require a `terminal_state` schema
field.

Local pipelines are for one bf-wo only. If the flow appears reusable across
bf-wos, the orchestrator may mention that after Final Acceptance as advisory
follow-up. It must not promote local pipelines, edit extension packs, create
files, or open a PR unless there is an explicit user request for promotion.

## Pipeline Designer

The Core `pipeline-designer` role designs bf-wo local pipelines and reviews
pipeline structure. It provides `pipeline-design` and `pipeline-review`.

When Spec Authoring creates a bf-wo local pipeline, a `pipeline-designer` actor
designs it. Spec Review includes three independent reviewer subagents
with the `pipeline-review` capability; the orchestrator enforces
subagent-instance independence.

## Work Object Coupling

BF requires one pack per work object. The pack id lives in `bf.md` frontmatter.
Cross-pack work must be split into multiple work objects.

## List Command Tolerance

`bf list-packs` scans `packs/` and performs basic structure checks:

- `pack.md` exists;
- frontmatter is complete;
- `Id` matches the directory name.

Invalid packs are skipped and reported as warnings. The command does not fail the
whole list operation.

`bf list-pipelines` scans `pipelines/*.yml` for the final effective pack
registry. Pipelines with parse errors or mismatched ids are skipped with
warnings. The list operation continues.

Reason: pack authoring happens outside the BF runtime. BF only needs to expose
usable packs and pipelines at runtime; warnings are enough for invalid
development-time entries.
