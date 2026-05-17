# Pack

> Domain-specific instantiation of BF Core. Manifest binding schemas + flows
> + roles + protocols + routing into one installable unit.

## Concept

A Pack is how a particular domain — product engineering, research, marketing,
ops — gets expressed inside the `bf` plugin. Core defines only abstract
machinery (Work Objects, Flows, WO-Homes, Gates); a Pack supplies the
concrete schemas, the four canonical flows tuned for the domain, the role
library that runs them, the protocols those roles follow, and the routing
table `bf-run` uses to pick a flow.

In v1, Packs are embedded under `plugins/bf/packs/<id>/` and ship alongside
the plugin itself. The `bf-run` driver discovers them by scanning that
directory at startup. The Pack manifest carries its own `version` field so
that future external-Pack distribution (`plugins/bf-pack-*/`) can version
independently from Core.

A Pack is purely declarative: it names files, schemas, and routes. It does
not execute anything itself. Execution stays with `bf-run`, which loads the
selected Pack and dispatches Flows against incoming Work Objects.

## Field reference

The Pack manifest lives at `pack.json` in the Pack root.

| Field | Type | Required | Notes |
|---|---|---|---|
| `bf_compat` | string | yes | Semver range of Core versions this Pack supports |
| `id` | string | yes | Pack identifier, e.g. `product-engineering` |
| `version` | string | yes | Semver version of the Pack itself |
| `description` | string | yes | Human-readable summary |
| `schemas` | object | yes | `{ <schema-id>: <path-to-schema.json> }` mapping for WO schemas |
| `flows` | array<string> | yes | Paths to flow JSON files; each declares a `core_type` of `brainstorm`, `breakdown`, `loop`, or `close` |
| `roles_dir` | string | optional | Default `./roles` |
| `protocols_dir` | string | optional | Default `./protocols` |
| `routing` | object | yes | Maps `(schema, current_state) → flow_id` so `bf-run` can select the right Flow |
| `state_aliases` | object | optional | Maps Pack-named states to Core canonical states. Lets a Pack call a state `reviewed_task_ready` while telling Core "this is canonical `shaped`". |
| `entry_skill` | string | optional | Pack-provided orchestration skill (e.g. `using-bf`) |

### No `ledger_conventions`

The Pack manifest deliberately has **no `ledger_conventions` field**. Core
does not track where work product lives. Product habitat (path conventions,
target directory, output artifact location) is expressed in each Work
Object's `acceptance_criteria`, decided during shaping. A Pack's shaping
protocol can guide that decision, but the Pack does not declare a global
product-location pattern. See
[layering-principles.md](../../../docs/specs/2026-05-16-bf-fork-design/layering-principles.md)
for the rationale: Core stays product-shape-agnostic so the same machinery
can drive engineering, research, or any other domain.

## Lifecycle

1. **Registered** — Pack lives at `plugins/bf/packs/<pack-id>/`; `bf-run`
   discovers it by scanning that directory.
2. **Selected** — `bf-run` reads the set of installed Packs and chooses one
   per Work Object via user hint, the WO's `pack` field, or the routing
   default.
3. **Active** — Flows, roles, protocols, and schemas are loaded; `bf-run`
   dispatches them against incoming WOs.
4. **Versioned** — The Pack `version` field is declared in its own
   `pack.json`. In v1 the Pack ships inside `bf`, but the field exists so
   future external Packs can version independently.

## Where stored

- **Manifest:** `plugins/bf/packs/<pack-id>/pack.json`
- **Pack contents:** same directory — typically `flows/`, `schemas/`,
  `roles/`, `protocols/`, `skills/`
- **Discovery:** `bf-run` scans `plugins/bf/packs/*/pack.json` at startup.
  In v2 it will also accept `plugins/bf-pack-*/pack.json` (external Pack
  form distributed as a sibling plugin).

## Role resolution

When a Flow node dispatches roles, resolution walks three layers, with later
layers overriding earlier ones when the same filename appears:

1. **Flow `rolesDir`** — roles bundled with the specific Flow
2. **Pack roles** — `roles_dir` from the Pack manifest
3. **Core roles** — the canonical role library shipped with Core

Flows pick which roles to dispatch by tag-filter on role frontmatter. A Pack
cannot delete or hide a Core role, but a Flow is free to omit any role it
doesn't want — selection is opt-in. See
[layering-principles.md](../../../docs/specs/2026-05-16-bf-fork-design/layering-principles.md)
§4 for the layering rationale.

## Example

A product-engineering Pack manifest:

```jsonc
{
  "bf_compat": ">=0.1",
  "id": "product-engineering",
  "version": "1.0.0-alpha",
  "description": "Blueprint-driven product engineering",
  "schemas": {
    "task":      "./schemas/task.json",
    "milestone": "./schemas/milestone.json",
    "phase":     "./schemas/phase.json",
    "blueprint": "./schemas/blueprint.json"
  },
  "flows": [
    "./flows/brainstorm.json",
    "./flows/breakdown.json",
    "./flows/loop.json",
    "./flows/close-leaf.json",
    "./flows/close-nonleaf.json"
  ],
  "roles_dir": "./roles",
  "protocols_dir": "./protocols",
  "routing": {
    "task,new":                "brainstorm",
    "task,shaped":             "breakdown",
    "task,doing":              "close-leaf",
    "milestone,new":           "brainstorm",
    "milestone,shaped":        "breakdown",
    "milestone,broken_down":   "loop",
    "milestone,children_done": "close-nonleaf"
  },
  "state_aliases": {
    "reviewed_task_ready": "shaped",
    "accepted_task":       "done"
  },
  "entry_skill": "using-bf"
}
```

## Open questions

- **Cross-Pack workflows** (e.g. research Pack hands off to
  product-engineering Pack): deferred to v2.
- **Pack dependencies** (one Pack importing another's schemas or roles):
  deferred.
- **Multi-Pack same-schema clash:** the Pack `id` namespaces its schemas;
  cross-Pack references use the `<pack>/<schema>` form.

## See also

- [work-object.md](./work-object.md) — Packs declare WO schemas
- [flow.md](./flow.md) — Packs declare flows
- [wo-home.md](./wo-home.md) — Packs declare schema-level state vocabulary
- [gate.md](./gate.md) — Packs can override gate logic per node
- Design rationale: [`../../../docs/specs/2026-05-16-bf-fork-design/layering-principles.md`](../../../docs/specs/2026-05-16-bf-fork-design/layering-principles.md)
