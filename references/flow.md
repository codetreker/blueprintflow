# Flow

> How a Work Object is advanced. A directed graph of typed nodes connected
> by verdict-keyed edges.

## Concept

A **Flow** is the executable recipe that moves a Work Object from one state toward the next. It is a directed graph: nodes do the work (discussing, building, reviewing, executing, gating), and edges — keyed by the verdict a node emits — decide where to go next. When `bf-run` advances a WO, it picks a Flow whose `accepts` shape matches the WO's current state and schema, runs the graph node-by-node until a terminal edge fires, then writes the resulting `desired_state` back into `wo.md`.

BF inherits OPC's `flow-template` JSON model verbatim — same `nodes` / `edges` / `nodeTypes` / `limits` / handshake mechanics — and adds three small fields that make Flows routable by Packs. The most important of these is `core_type`, which constrains every Flow to one of four well-known kinds. Anything you can plausibly do to a WO falls into one of those four kinds, so a Pack author composes the WO lifecycle by picking (or writing) one Flow per `core_type` per schema they care about.

Flow definitions live in a Pack. Flow run state — the per-step handshakes, artifacts, verdicts, and resumable position — lives next to the WO it is advancing, under `runs/run-<id>/`.

## The four core types

| Type | Purpose | Typical node skeleton |
|---|---|---|
| `brainstorm` | Raw input or vague WO → shaped WO with full `wo.md` content | discuss → write-criteria → criteria-lint → gate |
| `breakdown` | Shaped WO → child WOs in sub-directories, each with their own shaped `wo.md` (OR decision: "this is a leaf, no children") | plan-children → write-children → review-breakdown → gate |
| `loop` | WO with children → all children at `done` | dispatch (parallel respecting `depends_on`) → wait → aggregate |
| `close` | WO whose children are done (or leaf done implementation) → WO done | review-overall → exit-gate |

Plus implementation-style flows that `close` internally invokes for leaves (build / review / verify / gate sequence — inherited verbatim from OPC `build-verify`).

- **brainstorm** turns ambiguity into a shaped WO. It is where `acceptance_criteria` get written and linted.
- **breakdown** decides whether a shaped WO needs children, and if so writes them. A breakdown can legitimately conclude "this is a leaf" and emit no children.
- **loop** is the scheduler for a non-leaf WO's children. It dispatches them respecting `depends_on` and waits for everything to reach `done`.
- **close** is the terminal flow. For a leaf it includes the implementation work itself; for a non-leaf it is a final review over the assembled children.

## Field reference

Inherits OPC `flow-template` JSON; BF additions in **bold**.

| Field | Type | Required | Notes |
|---|---|---|---|
| `bf_compat` | string | yes | semver range like `>=0.1` |
| **`id`** | string | yes | Flow ID, unique within pack |
| **`core_type`** | enum | yes | One of `brainstorm` / `breakdown` / `loop` / `close` |
| **`accepts`** | object | yes | `{ current_state: [...], schema: [...] }` — when this flow can run |
| **`produces`** | object | yes | `{ desired_state: <state> }` — what state advancement this flow makes |
| `nodes` | array<string> | yes | (OPC) |
| `edges` | object | yes | (OPC) `{ node: { verdict: next_node \| null } }` |
| `nodeTypes` | object | yes | (OPC) `discussion \| build \| review \| execute \| gate` |
| `nodeCapabilities` | object | optional | (OPC) per-node capability declarations |
| `limits` | object | yes | (OPC) maxLoopsPerEdge / maxTotalSteps / maxNodeReentry |
| `contextSchema` | object | optional | (OPC) per-node context validation |
| `softEvidence` | boolean | optional | (OPC) warn vs error on missing evidence |
| `rolesDir` | string | optional | (OPC) relative to flow file |
| `protocolDir` | string | optional | (OPC) relative to flow file |
| `unitHandlers` | object | optional | (OPC) Loop-mode dispatch — see external-skill integration in [layering-principles.md](../../../docs/specs/2026-05-16-bf-fork-design/layering-principles.md) §8 |

## Lifecycle

1. **Selection** — `bf-run` looks at the WO's `current_state` + `schema` and finds an `accepts`-matching flow within the WO's Pack.
2. **Init** — `bf-harness init --flow-file <pack>/flows/<id>.json --entry <node> --dir <wo home>/runs/run-<id>/`.
3. **Step** — orchestrator executes node, writes handshake, calls `bf-harness transition`.
4. **Terminal** — `bf-harness finalize`; WO's `runtime.current_state` updated to flow's `produces.desired_state` in `wo.md`.

## Where stored

- Definition: `<pack>/flows/<id>.json`
- Run state: `<wo home>/runs/run-<id>/flow-state.json` (high-frequency write area)

## Example

A `close`-type flow that implements a leaf task:

```jsonc
{
  "bf_compat": ">=0.1",
  "id": "task-implementation",
  "core_type": "close",
  "accepts": { "schema": ["task"], "current_state": ["doing"] },
  "produces": { "desired_state": "done" },
  "nodes": ["implement", "code-review", "verify", "gate"],
  "edges": {
    "implement":   { "PASS": "code-review" },
    "code-review": { "PASS": "verify", "ITERATE": "implement" },
    "verify":      { "PASS": "gate", "ITERATE": "implement" },
    "gate":        { "PASS": null, "FAIL": "implement", "ITERATE": "code-review" }
  },
  "nodeTypes": {
    "implement": "build", "code-review": "review", "verify": "execute", "gate": "gate"
  },
  "limits": { "maxLoopsPerEdge": 3, "maxTotalSteps": 25, "maxNodeReentry": 5 },
  "rolesDir": "../roles",
  "protocolDir": "../protocols"
}
```

## Artifact (sub-contract)

Artifacts are part of Flow, not a separate top-level contract. They are entries in a node's `handshake.json` that describe evidence files produced during a run.

### Purpose

An **Artifact** is a single piece of evidence emitted by a node — an eval, a screenshot, a test result, a code diff, a chunk of CLI output. Artifacts let downstream nodes (and gates) reason about what happened in earlier nodes without having to re-execute them. They are process trace, not deliverable: when the WO is eventually discarded, its artifacts go with it.

### Fields

Inherits OPC handshake `artifacts[]`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | enum | yes | `eval \| evaluation \| screenshot \| test-result \| cli-output \| source \| code-diff` |
| `path` | string | yes | Relative to the run directory |
| `role` | string | optional | For `eval` type, which role produced it |
| `description` | string | optional | |

### Lifecycle

1. Node execution emits files into `<wo home>/runs/run-<id>/nodes/<node>/run_<N>/`.
2. Orchestrator writes `handshake.json` listing them.
3. `bf-harness validate` checks files exist and types match constraints (e.g. review nodes need ≥2 evals).
4. `synthesize` reads eval artifacts to compute the gate verdict.
5. When the WO is discarded, artifacts go with it (process trace, not deliverable).

### Where stored

- Files: `<wo home>/runs/run-<id>/nodes/<node>/run_<N>/<file>`
- Reference: `handshake.json` next to the run dir

### Example

A review node's handshake artifacts block:

```jsonc
{
  "artifacts": [
    { "type": "eval", "role": "code-quality", "path": "nodes/code-review/run_1/eval-code-quality.md" },
    { "type": "eval", "role": "test-coverage", "path": "nodes/code-review/run_1/eval-test-coverage.md" },
    { "type": "code-diff", "path": "nodes/code-review/run_1/diff.patch" }
  ]
}
```

### Note on "artifact as product"

If a node directly produces what is conceptually the work product (e.g. a `report.md` from a research task), the implementer should write the file to where it belongs in its natural habitat (e.g. `docs/research/`), not place it under `runs/`. The `acceptance_criteria` then says "report exists at `docs/research/foo.md` with content covering X/Y/Z". BF does not move files — the work product lives where it lives, and the WO asserts its existence via acceptance criteria.

## Open questions

- **`core_type` enum stability**: would `verify-only` (re-running just verification without implementation) be a 5th type, or a flag on `close`? (Lean: flag.)
- **Mid-loop pivot**: a child WO's failure forces re-brainstorm of parent — how is this expressed? (Lean: gate FAIL on close → parent goes back to `shaped`, breakdown is re-run.)
- **"Leaf" signal from breakdown**: how does breakdown declare "this is a leaf, no children needed"? (Lean: a flag emitted by the gate handshake; `bf-run` short-circuits to `doing`.)
- **Artifact type extensibility**: should Packs be allowed to add custom artifact `type` values, or is the enum closed at Core? (Deferred.)

## See also

- [work-object.md](./work-object.md) — what a Flow advances
- [gate.md](./gate.md) — how flow transitions are decided
- [wo-home.md](./wo-home.md) — where flow runs are recorded
- [pack.md](./pack.md) — Pack-defined routing and roles
