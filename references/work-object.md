# Work Object

> Contract version: **v0.3** (Stage 6 — clarifies acceptance-checklist
> semantics per Stage 5 demo finding #4).

> The primary citizen of BF. A bounded piece of uncertain or incomplete work
> that BF advances through states.

## Concept

A **Work Object** (WO) is the unit BF operates on: a bounded piece of uncertain or incomplete work — a feature to build, a bug to fix, a decision to make, a document to write — that BF advances from a starting state toward a desired state. WOs are routable (a Pack decides which flow to run on them), gateable (state transitions only happen when reviewers pass), and resumable (they survive session restarts).

WOs are **semi-persistent**. A WO lives in BF's local store while it is in progress, and survives across runs, restarts, and crashes. Once its `current_state` reaches its `desired_state`, the WO can be discarded. BF deliberately does not store the **work product** itself — the code, pull request, document, behavior change, or other artifact lives in its natural habitat (a repo, an issue tracker, a wiki, the world). BF asserts that the work product exists by checking that the WO's `acceptance_criteria` pass; it never tries to be a system of record for the product.

WOs are **recursive**. A WO is simply a directory that contains a `wo.md` file. If a sub-directory also contains a `wo.md`, that sub-directory is a child WO. Parent-child relations are expressed by the filesystem layout — there is no `parent` field, and no separate index. To find every WO in your store, look for every `wo.md`. To find a WO's children, look at its immediate sub-directories.

## On-disk shape

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

**Rule**: A directory with `wo.md` is a WO. Its parent WO is the nearest ancestor directory that also has `wo.md`. No other markers. `bf-run` discovers the WO tree by `find ~/.bf/wo -name wo.md`.

## `wo.md` structure

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

## Field reference

| Section | Authored by | Read by |
|---|---|---|
| YAML `id` / `pack` / `schema` / `capability_required` / `created_at` | Shaping flow | Pack flow selection, role dispatch, listing |
| YAML `depends_on` | Breakdown flow (siblings only; pure id list) | Parent's `loop` flow scheduler |
| YAML `runtime` block | Harness (transition handlers) | `bf-run resume`, `bf-run show` |
| H2 sections (Objective, Boundary, Acceptance, Notes) | Shaping flow, user edits, breakdown flow | Review-role agents (evaluation baseline), `criteria-lint` |

## Lifecycle (canonical states)

State machine (a Pack may extend this, but the canonical Core states are):

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

Packs may define additional intermediate states (e.g. `awaiting-review`, `blocked`) for their own routing logic. Those Pack-defined states alias back to one of the canonical Core states via the `state_aliases` declaration in `pack.json`, so Core flow-routing keeps working uniformly across Packs. See [pack.md](./pack.md).

## Where stored

- Default WO root: `~/.bf/wo/` (configurable; can point to shared storage)
- A WO at path `~/.bf/wo/a/b/c/` has id `a/b/c`
- Discoverable via `find ~/.bf/wo -name wo.md`

## Example

A `task`-level (leaf) WO:

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

## Open questions

- **Acceptance-criteria checklist semantics** (Stage 6 v0.3
  clarification): the `## Acceptance criteria` checklist (`- [ ]`
  items) in `wo.md` is **NOT** toggled to `- [x]` during state
  transitions. The `current_state` field IS the acceptance signal —
  a WO is accepted iff `current_state == done`. The checklist is the
  static record of what `done` was defined to mean during shaping,
  and remains useful as a human-readable contract after the fact.
  Lifted from Stage 5 demo finding #4.
- **Pack-defined state extensions**: how do Packs add intermediate states without breaking Core flow-routing? (Working answer: Core defines the canonical state set; Packs may add states that map to canonical ones, but must declare the mapping in `pack.json`.)
- **Resume vs new-run when `runtime.active_run` is non-null and the process restarts**: prompt the user, or auto-resume? (Working answer: auto-resume if no stale-detection signal; prompt otherwise.)
- **`depends_on` resolution**: cross-tree references (`other-wo-id`) or siblings only? (Working answer: siblings-only in v1; cross-tree deferred.)
- **Stale child state when a user manually edits a child's `wo.md`**: should the harness detect this by comparing file mtime against `runtime.updated_at`? (Deferred.)

## See also

- [flow.md](./flow.md) — how a WO is advanced
- [wo-home.md](./wo-home.md) — where a WO lives on disk
- [pack.md](./pack.md) — which Pack a WO belongs to
- [gate.md](./gate.md) — how state transitions are gated
