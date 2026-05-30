# Packs And Pipelines

Packs are BF's domain extension model. A pack describes a domain or workflow
pattern, such as engineering, research, incident response, or content production.

## Directory Structure

```text
packs/
  +- engineering/
  |    +- pack.md           # required: pack description + phase guidance
  |    +- pipelines/        # optional: task execution pipelines
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
- Project extension roles under `<project-root>/.bf/extensions/roles` override
  global extension roles.
- The selected pack may use its private roles in brainstorm, spec, and execute phases.

Global extension packs live under `~/.bf/extensions/packs`. Project extension
packs live under `<project-root>/.bf/extensions/packs`. Project packs override
global packs, and global packs override Core packs with the same id.

## Pack Pipelines

Packs may define pipelines under `packs/<pack-id>/pipelines/`.

Pipeline files use `<pipeline-id>.yml`. `bf list-pipelines --pack <id>` lists
pipelines from the effective pack directory only. If an extension overrides a
Core pack, Core pipelines from the overridden pack do not merge into the
extension pack.

The first pipeline version is instruction-only:

- The LLM reads the top-level pipeline `instruction`.
- The LLM follows stage `instruction` values in order.
- Pipeline or stage instructions decide when subagents are preferred or required.
- Pipeline state and stage gates may later move into the harness.

## Work Order Coupling

BF requires one pack per work order. The pack id lives in `bf.md` frontmatter.
Cross-pack work must be split into multiple work orders.

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
