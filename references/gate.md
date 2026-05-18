# Gate

> Contract version: **v0.3** (Stage 6 — no behavioral change; version
> bumped for consistency. See `flow.md` for gate auto-synthesis.)

> Mechanical decision point. Computes PASS / ITERATE / FAIL / BLOCKED from
> upstream node findings. No LLM judgement.

## Concept

A **Gate** is the node type that decides what a Flow does next. Every Flow ends with a gate, and most non-trivial Flows have intermediate gates between major phases (build, review, execute). When the orchestrator reaches a gate, it does not ask a model anything — it reads the `eval-*.md` and evidence artifacts produced by the upstream node, counts severity markers, and emits a verdict that the Flow's edges turn into a routing decision.

The point of the gate is to keep judgement *upstream* (in review-node role agents and execute-node evidence) and keep *routing* mechanical and reproducible. Two runs that produce the same set of evals must produce the same gate verdict. That guarantee is what makes Flows replayable and what makes loop-limits meaningful.

BF inherits OPC's `synthesize` step verbatim — same emoji counts, same compound-D2 rule, same verdict alphabet — and adds two small things on top: PASS at a Flow's terminal gate advances the WO's `runtime.current_state`, and Packs may declare a custom gate protocol per node.

## Mechanism

Inherits OPC `synthesize`.

- Reads upstream node's `eval-*.md` files.
- Counts severity emojis: 🔴 critical / 🟡 warning / 🔵 suggestion.
- Rules:
  - any 🔴 → **FAIL**
  - any 🟡 → **ITERATE**
  - all 🔵 / LGTM → **PASS**
  - any explicit `BLOCKED` in eval → **BLOCKED**
- Compound D2 rule (OPC): ≥3 layers of unresolved findings across iterations → forced FAIL.

### Bigger picture

Gate alone is the mechanical aggregation step. The full acceptance judgement is distributed across criteria-lint (mechanical, before flow starts), review-node role agents (LLM, during flow), execute-node evidence (during flow), and this gate (mechanical, end of flow). See [acceptance-judgement.md](../../../docs/specs/2026-05-16-bf-fork-design/acceptance-judgement.md) for the full model.

## Where stored

- Gate handshake auto-written by `bf-harness transition` into `<wo home>/runs/run-<id>/nodes/gate/handshake.json`.
- Verdict recorded in `flow-state.json.history[]` (in the run directory).
- On PASS that produces a Core state transition, harness updates `runtime.current_state` in the WO's `wo.md`.

## BF additions

| Addition | Purpose |
|---|---|
| State advancement on PASS | When a flow's terminal gate PASSes, BF updates `runtime.current_state` in `wo.md` to the flow's `produces.desired_state` |
| Pack-level gate override hook | Pack may declare custom gate logic per flow node via `protocols/gate-<node>.md` (optional) |

## Open questions

- `BLOCKED` propagation up the WO tree (parent WO's loop sees child BLOCKED): pause vs continue with other children? (lean: pause)
- Cross-flow chain: if leaf `close` PASSes, does it auto-trigger parent's `loop` reconciliation? (lean: yes — orchestrator polls parent's children states when re-entering the parent)

## See also

- [flow.md](./flow.md) — gates are nodes in a Flow
- [work-object.md](./work-object.md) — gate PASS advances `current_state`
- [wo-home.md](./wo-home.md) — where gate verdicts are recorded
