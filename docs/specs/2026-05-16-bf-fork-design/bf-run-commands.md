# bf-run Command Surface

Companion to [../2026-05-16-bf-fork-design.md](../2026-05-16-bf-fork-design.md).

Defines what `/bf-run <args>` accepts. Two modes coexist: **verb-first commands** (scriptable, predictable) and **natural language** (LLM transcribes to verb form, then executes). Verbs are owned by BF Core; Packs cannot add new verbs.

---

## 1. Two-mode parsing

```
User input → bf-run parser
              │
              ├─ first token is a known verb?
              │      yes → verb-first path (Mode B)
              │      no  → natural language path (Mode A)
              │
              ▼
            verb + parsed args
              │
              ▼
            dispatch (Pack discovery → flow selection → harness)
```

### Mode A — natural language
- User types in any phrasing: `/bf-run 帮我搞定 auth-login-form` or `/bf-run review the auth changes`
- bf-run LLM-parses input, picks a verb, fills args from context
- Before dispatching: **prints the transcribed verb form** so user can see what was decided
- Behavior is fully equivalent to Mode B once transcribed — no separate code path downstream

### Mode B — verb-first
- First token is one of the verbs in §3
- Args parsed by the verb's grammar
- No LLM parsing needed; behavior is deterministic

---

## 2. Verbs are Core-owned

Verbs come from BF Core. A Pack can:

- Introduce new WO schemas (so existing verbs operate on new schema types)
- Introduce new flows (so `execute` routes to new flows for new schemas)
- NOT add new verbs

This keeps the command surface stable across Packs. See [layering-principles.md](./layering-principles.md) §5 for the "command surface" entry in the Core-vs-Pack pattern table.

A Pack-specific operation that doesn't fit any Core verb is a signal that **the verb catalog needs to grow** (Core decision), not that the Pack needs its own verb.

---

## 3. Verb catalog (v0.2)

Verbs group by scope. This catalog is a starting point; additions/removals happen as Stage 3-5 reveals real usage.

### 3a. Lifecycle verbs (one per Core flow type + an orchestrator)

These map directly to BF's four Core flow types. Most users only need `execute` — it drives a WO through all four steps as needed.

| Verb | Form | Behavior |
|---|---|---|
| `execute` | `/bf-run execute <wo-id>` | **Drive the WO toward `desired_state` by invoking whichever Core flow matches its `current_state`.** Recurses into child WOs (where applicable). Exits when `current_state == desired_state` or a safety limit hits. |
| `create` | `/bf-run create <description>` | Create a new top-level WO under `~/.bf/wo/`. Pack chosen by routing or `--pack`. WO starts at `current_state: new` — next `execute` triggers `brainstorm`. |
| `brainstorm` | `/bf-run brainstorm <wo-id>` | Run the brainstorm Core flow once. `new → shaped`. Useful for interactive shaping. |
| `breakdown` | `/bf-run breakdown <wo-id>` | Run the breakdown Core flow once. `shaped → broken_down` (or marks as leaf and `→ doing`). |
| `loop` | `/bf-run loop <wo-id>` | Run the loop Core flow once. Processes all child WOs (parallel where `depends_on` allows). `broken_down → children_done`. |
| `close` | `/bf-run close <wo-id>` | Run the close Core flow once. `doing → done` (leaf) or `children_done → done` (non-leaf). |

The four fine-grained verbs (`brainstorm` / `breakdown` / `loop` / `close`) are for **interactive partial advancement** and scripted orchestration. `execute` is the unattended driver.

### 3b. Inspection / management verbs

| Verb | Form | Behavior |
|---|---|---|
| `show` | `/bf-run show <wo-id>` | Print the WO's `wo.md`, current state, recent transitions (rendered from `runs/`). Indicates child WO summary when applicable. |
| `tree` | `/bf-run tree [<wo-id>]` | Print the WO tree with state per node. Default: full `~/.bf/wo/`. |
| `list` | `/bf-run list [--pack <id>] [--state <state>] [--schema <schema>]` | List WOs matching filters (flat). |
| `discard` | `/bf-run discard <wo-id>` | Remove the WO's directory (and all descendants). Work product elsewhere is untouched. |

### 3c. Running-flow verbs (borrowed from OPC)

Operate on the currently active flow run.

| Verb | Form | Behavior |
|---|---|---|
| `skip` | `/bf-run skip` | Skip current node via its PASS edge. |
| `pass` | `/bf-run pass` | Force the current gate to PASS. Gate-type nodes only. |
| `stop` | `/bf-run stop` | Terminate the current run; state preserved (resumable). |
| `goto` | `/bf-run goto <node>` | Jump to a node in the current flow. Cycle limits still enforced. |
| `resume` | `/bf-run resume [<wo-id>]` | Continue an interrupted run. Without `<wo-id>`, picks the active one. |

### 3d. Meta verbs

| Verb | Form | Behavior |
|---|---|---|
| `pack` | `/bf-run pack list` \| `pack info <id>` | Inspect installed Packs. |
| `flow` | `/bf-run flow list [<pack>]` \| `flow viz <flow-id>` | Inspect flows; print ASCII flow graph. |
| `help` | `/bf-run help [<verb>]` | Usage. Default lists all verbs. |

---

## 4. WO id resolution

`<wo-id>` is a slash-separated path that mirrors the WO's filesystem location under `~/.bf/wo/`:

```
auth-v1                          → ~/.bf/wo/auth-v1/
auth-v1/login                    → ~/.bf/wo/auth-v1/login/
auth-v1/login/login-form         → ~/.bf/wo/auth-v1/login/login-form/
```

Every segment of the path must contain a `wo.md` for it to be valid (otherwise the path is not a WO chain). Discovery: `find ~/.bf/wo -name wo.md`.

### Disambiguation: changing `desired_state`

There's no `retarget` verb. To change a WO's `desired_state`, edit `runtime.desired_state` in `wo.md`'s YAML head directly. The harness reads the current value on every transition.

```bash
$ vim ~/.bf/wo/auth-v1/login/wo.md   # change runtime.desired_state, save
$ /bf-run execute auth-v1/login        # harness reads new target, drives there
```

This is the same pattern as editing acceptance_criteria or boundary — the user owns `wo.md`, harness reads it.

### `execute` flags

| Flag | Behavior |
|---|---|
| `--one-step` | Run only the next Core flow, then exit. For interactive workflows where you want to inspect between steps. |
| `--max-ticks <N>` | Cap total internal flow runs at N. Default is per-Pack/schema; safety guard against runaway recursion. |
| `--pack <id>` | When `<wo-id>` is ambiguous, pick a Pack explicitly. |

---

## 5. Pack selection

For `create` (the only verb that needs Pack selection before WO exists):

1. `--pack <id>` flag (explicit override)
2. The user's most recently used Pack (cached in `~/.bf/last-pack`)
3. The single default Pack (if exactly one Pack is installed, use it; otherwise ask)

For verbs operating on an existing WO, Pack is read from the WO's `pack:` YAML field. No selection needed.

---

## 6. Examples

```bash
# Natural language mode
/bf-run 帮我搞定 auth-v1/login
   # → transcribed to: /bf-run execute auth-v1/login

# Create a new top-level WO
/bf-run create "implement v1 auth"
   # → opens brainstorm flow
   # → after shaping, materializes ~/.bf/wo/auth-v1/wo.md

# Drive a WO to done (auto-runs whichever Core flow matches current_state)
/bf-run execute auth-v1
   # current_state=new        → brainstorm → shaped
   # current_state=shaped     → breakdown  → broken_down (creates children)
   # current_state=broken_down → loop (recurses into each child)
   # current_state=children_done → close → done

# Partial advance: just shape, don't break down yet
/bf-run brainstorm auth-v1
   # exits after one Core flow

# Inspect
/bf-run show auth-v1/login
/bf-run tree
/bf-run list --state in_progress
/bf-run pack list
/bf-run flow viz brainstorm

# Change target without running — edit wo.md
$ vim ~/.bf/wo/auth-v1/login/wo.md   # set runtime.desired_state: shaped
$ /bf-run execute auth-v1/login        # stops at shaped

# Mid-run control
/bf-run pass
/bf-run stop
/bf-run resume

# Clean up when done
/bf-run discard auth-v1/login/login-form
   # → removes ~/.bf/wo/auth-v1/login/login-form/
   # → work product (PR, code, etc.) is untouched
```

---

## 7. Open

- Should `tree` show only "interesting" WOs (in-progress) by default, with a `--all` flag for everything? (lean: yes — full tree is noisy)
- Single-token natural language hint like `/bf-run task` to mean "list tasks": no — natural language should be a phrase; single-word inputs should be unambiguous verbs or explicit `list` calls
- `discard` on a non-`done` WO: confirm first? (lean: yes, with `--force` to skip)
- Cron-driven verbs (sweep, intake) — deferred. Cron schedule is owned by user / OS, not BF. When needed, will add Core verbs and Pack-provided protocols. Out of scope for v1.
