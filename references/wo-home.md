# WO Home

> The semi-persistent local directory holding a Work Object's complete state
> while in progress. Replaces the earlier "Ledger" concept; deleted when the
> WO is discarded.

## Concept

A **WO Home** is the on-disk directory that owns a single Work Object while it
is alive. It contains the `wo.md` description, the `runs/` tree of flow
executions, and any child WO sub-directories. The WO Home is where BF reaches
when it needs to know what the WO is, where it stands, and what has happened
to it so far.

The WO Home is **semi-persistent**. It survives session restarts, machine
reboots, and arbitrary pauses between runs — but it is not the work product
and it is not git-versioned. When the WO is `done` or the user explicitly
`discard`s it, the directory is removed. The product the WO produced lives in
its natural habitat (the source repo, a doc, a deployed service); only the
scaffolding around producing it lives here.

Think of the WO Home as a workshop bench, not an archive. The artifact leaves
the workshop when finished; the bench gets cleared for the next job.

## Distinction from runs

| Dimension | `<wo home>/runs/run-<id>/` | `<wo home>/` itself |
|---|---|---|
| Lifetime | One flow run | One WO (can span many runs and resumes) |
| Contents | flow-state, handshakes, node artifacts | `wo.md`, `runs/`, optional child sub-directories |
| Discardable | After WO is done, with the WO | When WO reaches `done` or user `discard`s |
| Frequency of write | High (every transition) | Low (once per flow completion + user edits) |

## Files / structure

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

**No `history.jsonl`**: event trace is the union of all
`runs/*/flow-state.json.history[]` plus per-node `handshake.json` files.
`bf-run show` renders this on demand; nothing is duplicated to a single file.

## Child WOs

A sub-directory `<wo home>/<child-id>/` that also contains `wo.md` is a
**child WO**. Its full id is the parent id joined with the sub-directory
name (e.g. `auth-v1/login/login-form`). Multiple levels nest freely.

There is no `parent` field anywhere — the parent/child relation is
filesystem-native. To list a WO's children, list its sub-directories that
contain a `wo.md`. To find a WO's parent, walk up one directory. Recursion
is just `find` over the tree.

## Lifecycle

1. **Created** — shaping flow creates `~/.bf/wo/<id>/`, writes initial
   `wo.md` (state = `new`)
2. **Shaped** — brainstorm flow fills in `wo.md` H2 sections,
   `runtime.current_state` → `shaped`
3. **Broken down** — breakdown flow `mkdir`s child WOs under this directory
   and writes their `wo.md`s (or marks parent as leaf)
4. **Loop** — for each child (filesystem listing of `<wo home>/*/wo.md`),
   recurse `execute`
5. **Close** — close flow runs final review/gate, sets
   `runtime.current_state` → `done`
6. **Discarded** — `bf-run discard <id>` removes `<wo home>/` (and all
   descendants). Work product is untouched.

## Where stored

- Default root: `~/.bf/wo/`
- Configurable for shared storage (e.g. `~/Dropbox/bf-wo/` or NFS mount)
- BF does not implement sync; the directory is whatever the OS gives it

If two machines both write into the same shared root, conflict resolution
is the storage layer's problem (Dropbox, NFS lock semantics, etc.), not BF's.

## Open questions

- Pruning old runs in the same WO (after iteration loops): on-discard only,
  or proactive `bf-run prune-runs`? (defer)
- Cross-WO indices (e.g. "all WOs in `pack:research`"): scanner walks
  `~/.bf/wo`; cached? (lean: no cache for v1; the tree is small)

## See also

- [work-object.md](./work-object.md) — what lives in this home
- [flow.md](./flow.md) — flows write into `runs/`
- [gate.md](./gate.md) — state transitions update `wo.md` runtime block
- [pack.md](./pack.md) — Pack-defined schema files for `wo.md`
