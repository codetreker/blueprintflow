# Stage 4 Retrospective

> Captures what worked, what stayed broken, and what Stage 5 demo
> needs to address. Companion to the Stage 4 plan
> (`docs/specs/2026-05-17-bf-stage-4-dispatcher-plan.md`).

Stage 4 shipped the `bf` dispatcher: 18 known verbs, a hardened
`bf-harness`, an npm-packable bare skill, and a deterministic NL
front-end. Real role-agent dispatch and child-run primitives stayed
stubbed — that is Stage 5's domain.

## What's working

**The 18 verbs** wired through `bin/bf.mjs` + `bin/lib/dispatcher/arg-parser.mjs::KNOWN_VERBS`:

| Group | Verbs | Test |
|---|---|---|
| Lifecycle | `execute`, `create`, `brainstorm`, `breakdown`, `loop`, `close` | `test/verbs/test-{create,brainstorm,breakdown,loop,close,execute-leaf}.sh` |
| Inspection | `show`, `tree`, `list`, `discard` | `test/verbs/test-show-tree-list.sh` |
| Escape | `skip`, `pass`, `stop`, `goto`, `resume` | `test/verbs/test-escape.sh` |
| Meta | `pack`, `flow`, `help` | `test/verbs/test-pack-flow.sh`, `test-help.sh` |

All verbs return a JSON envelope; the 12 production verbs route to
`bin/lib/verbs/<verb>.mjs`, the 5 escape verbs share `escape.mjs`.

**Harness hardening — 6 sub-tasks, all green:**

| 4.2 | Commit | Test |
|---|---|---|
| a — `--dir` sandbox widening to `/tmp/bf-*` | `998abe2` | `test/harness-hardening/test-a-dir-sandbox.sh` |
| b — `seal` auto-creates `nodes/<id>/run_1/` | `d108969` | `test-b-auto-run-dir.sh` |
| c — `seal` accepts bare `eval.md` as type `eval` | `708e14b` | `test-c-eval-md-alias.sh` |
| d — `seal` returns `sealed:false` on validation errors | `c7dd08b` | `test-d-seal-validation-errors.sh` |
| e — Pack-overridable mandatory-role list | `7bedcb0` | `test-e-pack-mandatory-roles.sh` |
| f — `viz` renders ITERATE and FAIL back-edges | `5dc70dc` | `test-f-viz-back-edges.sh` |

**Dispatcher scaffold (commits `f95017b`, `1c72e15`, `3da08cb`, `2596e76`):**
`arg-parser` → `pack-discovery` → `wo-resolver` → `flow-selector`, each
with its own test under `test/dispatcher/`. The node-runner
(`610a261`) drives `bf-harness init/seal/transition` for one step.

**Packaging** (commit `158bbc0`, then docs `cb99d4d`): `npm pack
--dry-run` produces a clean tarball; `test/test-package-dryrun.sh`
guards file inclusion/exclusion. README (`cb99d4d`) names every verb
and calls out v0.2 limits honestly.

**Test suite:** `bash test/run-all.sh` → **132 files passed, 0 failed**
(108 baseline + 6 harness + 5 dispatcher + 11 verbs + 1 pack-dryrun +
1 regression). One test deferred: `test-install-hooks.sh` (depends on
upstream `bin/opc.mjs`, see `test/deferred-tests.txt`).

## What stayed broken

For each unresolved item: symptom / workaround / source.

**1. Stub role-evaluator inside node-runner.**
Symptom: `node-runner` emits a synthetic `verdict: PASS` evaluator
output rather than calling a real Claude subagent. `bf execute`
therefore "drives" a leaf to `done` without any acceptance-criteria
work happening.
Workaround: the orchestrator agent (you, in /bf context) does the
substantive work by hand and seals artifacts; the harness is honest
about state.
Traces to: `bin/lib/dispatcher/node-runner.mjs` (commit `610a261`);
plan § Out of Scope item 1.

**2. Child-run dispatch for `loop.dispatch-children`.**
Symptom: `bf loop <wo>` short-circuits with `{deferred: "stage-5",
reason: "child-run dispatch not implemented"}`. A milestone with
children cannot reconcile.
Workaround: run each child WO manually via `bf execute <child-id>`.
Traces to: Stage 3 finding §251; `bin/lib/verbs/loop.mjs` (commit
`325dca4`); core-contracts.md `Flow.Open` "Node-spawns-child-runs not
supported".

**3. Per-WO live-state file.**
Symptom: a parent's `await-children` node has no canonical place to
read each child's terminal verdict; today's only signal is the
child's `wo.md` frontmatter (state-only, lossy).
Workaround: parent agents poll `<wo>/runs/run-*/flow-state.json`
manually.
Traces to: Stage 3 finding §251; core-contracts.md `WO.Open`
"Per-WO live-state file for parent-watching-children".

**4. Structured edge payloads `{verdict, scope}`.**
Symptom: `aggregate.FAIL` routes to one node; the failed-subset
information is lost. A loop must re-dispatch the entire ready set.
Workaround: rely on build-agent idempotency.
Traces to: Stage 3 finding §252; core-contracts.md `Flow.Open` edge
schema bullet.

**5. NL transcription is deterministic-only.**
Symptom: `bf "ship the login form"` returns `needs-llm`, falling
through to a "use a verb" error in CLI mode.
Workaround: invoke via Claude Code skill context, which performs the
LLM transcription before calling `bf <verb>`.
Traces to: `bin/lib/dispatcher/nl-parse.mjs` (commit `d2d6ebb`); plan
§ 4.6.

**6. `bf resume` without `--wo` arg unsupported.**
Symptom: `bf resume` with no positional id returns a "missing wo id"
error rather than enumerating in-flight runs.
Workaround: pass an explicit WO id; or use `bf list` to find one.
Traces to: `bin/lib/verbs/escape.mjs` (commit `6a3e077`).

**7. `wo.md` frontmatter parser is line-based.**
Symptom: multi-line YAML values (list items on subsequent lines,
nested maps, block scalars) are silently dropped when the resolver
reads `wo.md`. Today's WO schemas only declare scalar frontmatter, so
no failure is observable — but the parser will quietly truncate as
soon as a Pack defines a list-shaped runtime field.
Workaround: keep frontmatter values on one line each.
Traces to: `bin/lib/dispatcher/wo-resolver.mjs::parseFrontmatter`
(commit `3da08cb`); now logged in core-contracts.md `WO.Open`.

## Stage 5 must-do list

Carried forward from Stage 3 (still relevant) + Stage 4 discoveries:

- [ ] **Real agent dispatch** — replace node-runner's stub evaluator
  emitter with Claude subagent calls per the role file under each
  Pack's `roles/`.
- [ ] **Child-run dispatch** for `loop.dispatch-children`, plus a
  `bf-harness create-child-wo` primitive (Stage 3 §251, §254).
- [ ] **Per-WO live-state file** with chosen poll/notify semantics
  (Stage 3 §251).
- [ ] **Structured edge payloads `{verdict, scope}`** so loops can
  re-dispatch failed subsets only (Stage 3 §252).
- [ ] **Loop-type-aware default budgets** sized at
  `dispatch-children` entry (Stage 3 §253).
- [ ] **LLM-driven NL transcription** — replace the deterministic
  `transcribeDeterministic` stub with a Claude call in skill context
  (Stage 4 §4.6).
- [ ] **`bf resume` ergonomics** — enumerate in-flight runs when no
  WO id given; or `bf resume --last` (Stage 4 discovery).
- [ ] **Schema completeness check at dispatcher init** — fail fast
  if a Pack's `routing` references schemas not present under
  `schemas/` (Stage 3 §474).
- [ ] **Multi-line YAML support in `wo.md`** — drop the regex
  frontmatter parser for a real YAML library before any Pack adds
  list/map runtime fields (Stage 4 discovery).
- [ ] **Sibling-Pack npm discovery** — `pack-discovery` currently
  scans repo-local Packs only.

## Stage 5 demo target

End-to-end: a fresh `bf "implement auth login form"` invocation
runs brainstorm with a real role-evaluator subagent that writes
shaped acceptance criteria, then `bf close <wo>` drives the leaf
through implement / review / verify / gate with real agents at each
node and lands at `done` with sealed artifacts under
`runs/run-*/nodes/*/run_*/`.

## Test result

`bash test/run-all.sh` → **132 files passed, 0 files failed**.
Plus `test/test-stage4-regression.sh` → `PASS:
create→show→execute→tree→discard regression`.
One test deferred (`test-install-hooks.sh`, see
`test/deferred-tests.txt`).
