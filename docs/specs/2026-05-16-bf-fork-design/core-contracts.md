# BF Core Contracts — v0.2 Draft

Companion to [../2026-05-16-bf-fork-design.md](../2026-05-16-bf-fork-design.md).

**Five contracts** (Artifact is no longer a top-level contract — it's a sub-shape of handshake, documented within Flow). Each section: **Purpose / Fields / Lifecycle / Where stored / Example / Open**.

v0.2 reflects the discussions of 2026-05-16/17:
- Work Object is a **directory** containing `wo.md`; recursion is filesystem-native (a sub-WO is just a sub-directory with its own `wo.md`)
- Persistent state lives in `wo.md` YAML frontmatter; no separate `state.json` or `history.jsonl`
- Core has **four flow types**: `brainstorm` / `breakdown` / `loop` / `close`
- BF tracks process, not product; product lives in its natural habitat (git, PR, doc)
- Acceptance judgement is distributed (criteria-lint + review-roles + evidence + gate)

These are v0.2 drafts. Stage 3 implementation pressure-tests them; Stage 6 produces v0.3+.

---

## 1. Work Object

### Purpose
The bounded piece of uncertain or incomplete work that BF advances. **The primary citizen.** Routable, gateable, resumable.

**Semi-persistent**: A WO lives in BF's local store while in progress, surviving session restarts. Once `current_state == desired_state`, it can be discarded — the **work product** (code, PR, document, behavior change) lives in its natural habitat, not inside the WO. BF asserts product existence via `acceptance_criteria` passing; it does not store products.

**Recursive**: A WO is a directory containing `wo.md`. A sub-directory that also contains `wo.md` is a child WO. The filesystem expresses parent-child relations — no `parent` field is needed.

### Storage shape

```
~/.bf/wo/<id-segment-1>/                  ← top-level WO
├── wo.md                                  ← required; presence = "this directory is a WO"
├── runs/                                   ← this WO's own flow runs
│   └── run-<timestamp>/
└── <id-segment-2>/                        ← child WO (created by breakdown flow)
    ├── wo.md
    ├── runs/
    └── <id-segment-3>/                    ← grandchild WO
        ├── wo.md
        └── runs/
```

**Rule**: A directory with `wo.md` is a WO. Its parent WO is the nearest ancestor directory that also has `wo.md`. No other markers. `bf-run` discovers WO tree by `find ~/.bf/wo -name wo.md`.

### `wo.md` structure

```markdown
---
# Identity (set by shaping flow, rarely changes)
id: auth-v1/login/login-form
pack: product-engineering
schema: task
capability_required: [frontend, test-design]
created_at: 2026-05-17T10:00:00Z

# Optional sibling dependency declaration
depends_on:
  - auth-v1/login/session-cookie

# Runtime (maintained by harness; users may edit but harness re-writes on transition)
runtime:
  current_state: in_progress
  desired_state: done
  active_run: run-2026-05-17T10-23-45
  updated_at: 2026-05-17T11:42:00Z
---

# <Objective — H1 is short title>

## Objective
<paragraph; what's being advanced and why>

## Boundary
- In scope: ...
- Out of scope: ...

## Acceptance criteria
- <observable criterion 1>
- <observable criterion 2>
- ...

## Notes
<free-form user notes>
```

**Fields by section**:

| Section | Authored by | Read by |
|---|---|---|
| YAML `id` / `pack` / `schema` / `capability_required` / `created_at` | Shaping flow | Pack flow selection, role dispatch, listing |
| YAML `depends_on` | Breakdown flow (siblings only; pure id list) | Parent's `loop` flow scheduler |
| YAML `runtime` block | Harness (transition handlers) | `bf-run resume`, `bf-run show` |
| H2 sections (Objective, Boundary, Acceptance, Notes) | Shaping flow, user edits, breakdown flow | Review-role agents (evaluation baseline), `criteria-lint` |

### Lifecycle

State machine (Pack may extend, but the canonical Core states are):

```
new            ← created, no shaping done
shaped         ← brainstorm flow PASSed; acceptance_criteria written and linted
broken_down    ← breakdown flow PASSed; children/ now contain child WOs (skipped if leaf)
doing          ← (leaf only) implementation flow running
children_done  ← (non-leaf) all children at desired_state
done           ← close flow PASSed; ready to discard
```

The four Core flow types map to these transitions:

| Flow type | from → to |
|---|---|
| `brainstorm` | new → shaped |
| `breakdown` | shaped → broken_down (or → doing for leaves) |
| `loop` | broken_down → children_done (recursive; runs child execute) |
| `close` | children_done → done (non-leaf) OR doing → done (leaf, includes implementation) |

A **leaf** WO is one whose breakdown flow decided "no children needed" — it goes straight `shaped → doing → done`. A **non-leaf** WO goes through all four. The decision happens inside `breakdown` flow's review nodes.

### Where stored

- Default WO root: `~/.bf/wo/` (configurable; can point to shared storage)
- A WO at path `~/.bf/wo/a/b/c/` has id `a/b/c`
- Discoverable via `find ~/.bf/wo -name wo.md`

### Example: a `task`-level (leaf) WO

```markdown
---
id: auth-v1/login/login-form
pack: product-engineering
schema: task
capability_required: [frontend, test-design]
created_at: 2026-05-17T10:00:00Z

runtime:
  current_state: shaped
  desired_state: done
  active_run: null
  updated_at: 2026-05-17T10:15:00Z
---

# Email/password login form

## Objective
Implement the email/password login form on `/login`, with session cookie persistence and a working logout. This is the visible piece of v1 auth.

## Boundary
- In scope: form UI, submit handler, session cookie, logout button
- Out of scope: password reset, OAuth, MFA, account creation

## Acceptance criteria
- User can log in with email/password (manual browser test; screenshot captured)
- Session persists across page refresh
- Logout clears session and redirects to /login
- `tests/auth/*` all pass
- PR opened, CI green

## Notes
(user/agent notes go here over time)
```

### Open

- Pack-defined state extensions: how do Packs add intermediate states without breaking Core flow-routing? (lean: Core defines canonical state set; Pack can add states that map to canonical ones, but must declare the mapping in pack.json)
- Resume vs new-run when `runtime.active_run` is non-null and process restarts: prompt user, or auto-resume? (lean: auto-resume if no stale-detection signal; prompt otherwise)
- `depends_on` resolution: cross-tree references (`other-wo-id`) or only siblings? (lean: siblings-only in v1; cross-tree deferred)
- "child WO has stale state because user manually edited its `wo.md`" — harness should detect by file mtime vs `runtime.updated_at`? (deferred)

---

## 2. Flow

### Purpose
How a Work Object is advanced. A directed graph of typed nodes connected by verdict-keyed edges. Inherits OPC's flow-template JSON model; BF restricts the **type** to one of four Core flow types.

### Core flow types

| Type | Purpose | Typical node skeleton |
|---|---|---|
| `brainstorm` | Raw input or vague WO → shaped WO with full `wo.md` content | discuss → write-criteria → criteria-lint → gate |
| `breakdown` | Shaped WO → child WOs in sub-directories, each with their own shaped `wo.md` (OR decision: "this is a leaf, no children") | plan-children → write-children → review-breakdown → gate |
| `loop` | WO with children → all children at `done` | dispatch (parallel respecting `depends_on`) → wait → aggregate |
| `close` | WO whose children are done (or leaf done implementation) → WO done | review-overall → exit-gate |

Plus implementation-style flows that close-flow internally invokes for leaves (build / review / verify / gate sequence — inherited verbatim from OPC `build-verify`).

### Fields (inherits OPC `flow-template` JSON; BF additions in **bold**)

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
| `unitHandlers` | object | optional | (OPC) Loop-mode dispatch — see external-skill integration in [layering-principles.md](./layering-principles.md) §8 |

### Lifecycle

1. **Selection** — `bf-run` looks at the WO's `current_state` + `schema` and finds an `accepts`-matching flow within the WO's Pack
2. **Init** — `bf-harness init --flow-file <pack>/flows/<id>.json --entry <node> --dir <wo home>/runs/run-<id>/`
3. **Step** — orchestrator executes node, writes handshake, calls `bf-harness transition`
4. **Terminal** — `bf-harness finalize`; WO's `runtime.current_state` updated to flow's `produces.desired_state` in `wo.md`

### Where stored

- Definition: `<pack>/flows/<id>.json`
- Run state: `<wo home>/runs/run-<id>/flow-state.json` (high-frequency write area)

### Example

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

### Open

- `core_type` enum stability: would `verify-only` (re-running just verification without implementation) be a 5th type, or a flag on `close`? (lean: flag)
- Mid-loop pivot (a child WO's failure forces re-brainstorm of parent): how is this expressed? (lean: gate FAIL on close → parent goes back to `shaped`, breakdown is re-run)
- How does breakdown declare "this is a leaf, no children needed"? (lean: a flag emitted by the gate handshake; `bf-run` short-circuits to `doing`)

---

## 3. Artifact (sub-contract within Flow)

Artifacts are entries in a node's `handshake.json` describing evidence files produced during the run. **Not a top-level Core contract** — they are an internal shape of Flow.

### Fields (inherits OPC handshake `artifacts[]`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | enum | yes | `eval \| evaluation \| screenshot \| test-result \| cli-output \| source \| code-diff` |
| `path` | string | yes | Relative to the run directory |
| `role` | string | optional | For `eval` type, which role produced it |
| `description` | string | optional | |

### Lifecycle

1. Node execution emits files into `<wo home>/runs/run-<id>/nodes/<node>/run_<N>/`
2. Orchestrator writes `handshake.json` listing them
3. `bf-harness validate` checks files exist and types match constraints (e.g. review nodes need ≥2 evals)
4. `synthesize` reads eval artifacts to compute gate verdict
5. When the WO is discarded, artifacts go with it (process trace, not deliverable)

### Where stored

- Files: `<wo home>/runs/run-<id>/nodes/<node>/run_<N>/<file>`
- Reference: `handshake.json` next to the run dir

### Note on "artifact as product"

If a node directly produces what is conceptually the work product (e.g. a `report.md` from a research task), the implementer should write the file to where it belongs in its natural habitat (e.g. `docs/research/`), not place it under `runs/`. The `acceptance_criteria` then says "report exists at `docs/research/foo.md` with content covering X/Y/Z". BF does not move files.

---

## 4. Gate

### Purpose
Mechanical decision point. Computes `PASS | ITERATE | FAIL | BLOCKED` from upstream node's findings. **No LLM judgment.**

### Mechanism (inherits OPC `synthesize`)

- Reads upstream node's `eval-*.md` files
- Counts severity emojis: 🔴 critical / 🟡 warning / 🔵 suggestion
- Rules:
  - any 🔴 → **FAIL**
  - any 🟡 → **ITERATE**
  - all 🔵 / LGTM → **PASS**
  - any explicit `BLOCKED` in eval → **BLOCKED**
- Compound D2 rule (OPC): ≥3 layers of unresolved findings across iterations → forced FAIL

### Where stored

- Gate handshake auto-written by `bf-harness transition` into `<wo home>/runs/run-<id>/nodes/gate/handshake.json`
- Verdict recorded in `flow-state.json.history[]` (in the run directory)
- On PASS that produces a Core state transition, harness updates `runtime.current_state` in the WO's `wo.md`

### BF additions

| Addition | Purpose |
|---|---|
| State advancement on PASS | When a flow's terminal gate PASSes, BF updates `runtime.current_state` in `wo.md` to the flow's `produces.desired_state` |
| Pack-level gate override hook | Pack may declare custom gate logic per flow node via `protocols/gate-<node>.md` (optional) |

### Open

- `BLOCKED` propagation up the WO tree (parent WO's loop sees child BLOCKED): pause vs continue with other children? (lean: pause)
- Cross-flow chain: if leaf `close` PASSes, does it auto-trigger parent's `loop` reconciliation? (lean: yes — orchestrator polls parent's children states when re-entering the parent)

---

## 5. WO Home

### Purpose
The **semi-persistent local directory** holding a WO's complete state. Replaces what earlier drafts called "Ledger". Survives session restarts; is deleted when the WO is discarded.

### Distinction from runs

| Dimension | `<wo home>/runs/run-<id>/` | `<wo home>/` itself |
|---|---|---|
| Lifetime | One flow run | One WO (can span many runs and resumes) |
| Contents | flow-state, handshakes, node artifacts | `wo.md`, `runs/`, optional child sub-directories |
| Discardable | After WO is done, with the WO | When WO reaches `done` or user `discard`s |
| Frequency of write | High (every transition) | Low (once per flow completion + user edits) |

### Files / structure

```
<wo home>/                                  ← e.g. ~/.bf/wo/auth-v1/login/login-form/
├── wo.md                                   ← persistent WO description; YAML + markdown
└── runs/
    └── run-<timestamp>/
        ├── flow-state.json                 ← OPC schema; harness manages
        ├── flow-context.json               ← (optional) per-flow context object
        └── nodes/
            └── <nodeId>/
                ├── handshake.json
                └── run_<N>/                ← per iteration of this node
                    ├── eval-*.md
                    ├── screenshot-*.png
                    ├── cli-output-*.txt
                    └── ...
```

**No `state.json`**: identity + runtime state are in `wo.md`'s YAML head.
**No `history.jsonl`**: event trace is the union of all `runs/*/flow-state.json.history[]` plus per-node `handshake.json` files. `bf-run show` renders this on demand; nothing is duplicated to a single file.

### Child WOs

A sub-directory `<wo home>/<child-id>/` that also contains `wo.md` is a **child WO**. Its full id = parent id + sub-directory name. Multiple levels nest freely. No `parent` field needed — relation is filesystem-native.

### Lifecycle

1. **Created** — shaping flow creates `~/.bf/wo/<id>/`, writes initial `wo.md` (state = `new`)
2. **Shaped** — brainstorm flow fills in `wo.md` H2 sections, `runtime.current_state` → `shaped`
3. **Broken down** — breakdown flow `mkdir`s child WOs under this directory and writes their `wo.md`s (or marks parent as leaf)
4. **Loop** — for each child (filesystem listing of `<wo home>/*/wo.md`), recurse `execute`
5. **Close** — close flow runs final review/gate, sets `runtime.current_state` → `done`
6. **Discarded** — `bf-run discard <id>` removes `<wo home>/` (and all descendants). Work product is untouched.

### Where stored

- Default root: `~/.bf/wo/`
- Configurable for shared storage (e.g. `~/Dropbox/bf-wo/` or NFS mount)
- BF does not implement sync; the directory is whatever the OS gives it

### Open

- Pruning old runs in the same WO (after iteration loops): on-discard only, or proactive `bf-run prune-runs`? (defer)
- Cross-WO indices (e.g. "all WOs in `pack:research`"): scanner walks `~/.bf/wo`; cached? (lean: no cache for v1; the tree is small)

---

## 6. Pack

### Purpose
Domain-specific instantiation of BF Core. Manifest binding schemas + flows + roles + protocols + routing into one installable unit.

### Fields (`pack.json`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `bf_compat` | string | yes | semver range |
| `id` | string | yes | e.g. `product-engineering` |
| `version` | string | yes | semver |
| `description` | string | yes | |
| `schemas` | object | yes | `{ <schema-id>: <path-to-schema.json> }` for WO schemas |
| `flows` | array<string> | yes | Paths to flow JSON files; each declares `core_type` (one of brainstorm/breakdown/loop/close) |
| `roles_dir` | string | optional | Default: `./roles` |
| `protocols_dir` | string | optional | Default: `./protocols` |
| `routing` | object | yes | Maps `(schema, current_state) → flow_id` for `bf-run` selection |
| `state_aliases` | object | optional | Maps Pack-named states to Core canonical states. Lets a Pack call states `reviewed_task_ready` etc. but tell Core "this is canonical `shaped`". |
| `entry_skill` | string | optional | Pack-provided skill for orchestration (e.g. `using-bf`) |

**No `ledger_conventions`.** Core does not track product location. Work product habitat is expressed in each WO's `acceptance_criteria`, decided during shaping. Pack helps via its shaping protocol but does not declare a global pattern.

### Lifecycle

1. **Registered** — Pack lives at `plugins/bf/packs/<pack-id>/`; bf-run discovers by scanning that directory
2. **Selected** — `bf-run` reads installed Packs; chooses one by user hint, by WO's `pack` field, or by routing default
3. **Active** — flows / roles / protocols / schemas loaded
4. **Versioned** — Pack `version` declared in its own `pack.json`; in v1 ships inside `bf`, but the field exists so future external Packs version independently

### Where stored

- Manifest: `plugins/bf/packs/<pack-id>/pack.json`
- Pack contents: same directory (`flows/`, `schemas/`, `roles/`, `protocols/`, `skills/`)
- Discovery: `bf-run` scans `plugins/bf/packs/*/pack.json` at startup. Also accepts `plugins/bf-pack-*/pack.json` in the future (external Pack form, v2).

### Role resolution

Flow node → roles: **flow rolesDir → Pack roles → Core roles** (later overrides earlier when same filename). Flows pick which roles to dispatch by tag-filter on the role frontmatter; Packs cannot exclude Core roles, but a flow simply doesn't have to select a Core role it doesn't want. See [layering-principles.md](./layering-principles.md) §4.

### Example

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
    "task,new":            "brainstorm",
    "task,shaped":         "breakdown",
    "task,doing":          "close-leaf",
    "milestone,new":       "brainstorm",
    "milestone,shaped":    "breakdown",
    "milestone,broken_down": "loop",
    "milestone,children_done": "close-nonleaf"
  },
  "state_aliases": {
    "reviewed_task_ready": "shaped",
    "accepted_task":       "done"
  },
  "entry_skill": "using-bf"
}
```

### Open

- Cross-Pack workflows (research → product-engineering handoff): defer to v2
- Pack dependencies (one Pack imports another's schemas / roles): defer
- Multi-Pack same-schema clash: Pack id namespaces schemas; cross-Pack references use `<pack>/<schema>` form
