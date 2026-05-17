# brainstorm-task — Node Protocol

Flow: [`../flows/brainstorm-task.json`](../flows/brainstorm-task.json)
`core_type: brainstorm` · accepts `task` WO in state `new` · produces `shaped`.

Purpose: take a fuzzy task WO from `new` to `shaped` by surfacing the
four-piece (what / why / boundary / how-to-verify) and writing concrete
acceptance criteria into `wo.md`. Derived from v6 `bf-task-fourpiece`
and `bf-brainstorm`.

Node graph: `discuss → write-criteria → criteria-lint → gate`.

## Node: `discuss` (discussion)

Goal: converge on the four-piece for this single task. Not a full
blueprint brainstorm — scoped to one leaf task, usually 1–3 rounds.

Surface and answer:

1. **What** — the Objective. ≤30 words, the smallest user-visible
   outcome this task delivers.
2. **Why** — the rationale that ties Objective to the parent milestone
   / blueprint stance. Name the stance anchor.
3. **Boundary** — what is explicitly NOT in scope. Out-of-scope items
   that a reasonable reader might assume are included.
4. **How to verify** — the observable signal that proves Objective is
   met. Becomes the seed of `Acceptance criteria` in the next node.

Default roles to dispatch (from Core `roles/`):

- `architect` — owns Boundary and verifies the task is technically
  coherent at this size.
- `planner` — owns Objective phrasing and sizing; flags if this is
  really two tasks.
- `devil-advocate` — pressure-tests Why and Boundary; surfaces hidden
  scope creep and "what about X" cases.

These three cover claim, structural soundness, and adversarial review
without dragging in domain specialists (which belong in later nodes of
breakdown / close flows). Pull in `security` or `a11y` only if the
discussion explicitly raises those concerns.

Use the multi-role review template at
[`../../../pipeline/role-evaluator-prompt.md`](../../../pipeline/role-evaluator-prompt.md)
to format each role's input.

Round structure (per `bf-brainstorm` Multi-round structure, scoped
down):

- Round 1 (Scope): each role answers the 4 four-piece questions in
  ≤200 words.
- Round 2+ (Conflict): only if Round 1 surfaced disagreement on
  Objective or Boundary. Each round produces a ≤5-line revised
  four-piece draft. Hard cap: 3 rounds.
- Freeze: orchestrator records the agreed four-piece into the WO's
  `discussion.md` (or notes section) and emits PASS.

Exit signal: a four-piece draft all three roles can sign off, or a
flagged conflict that escalates back via `gate.FAIL`.

## Node: `write-criteria` (build)

Goal: turn the frozen four-piece into the `wo.md` sections required
by `schemas/task.json`: `Objective`, `Boundary`, `Acceptance criteria`.

Author the WO file (typically `wo.md` under the run directory). Use
ATX headers matching the required section names. The acceptance
criteria list must:

- Be a markdown checklist (`- [ ]`).
- Each item: imperative outcome statement, observable from outside the
  implementation (user / API / file / test result).
- Cover every "How to verify" point from the four-piece, 1:1.
- Include the Definition of Done items the downstream `criteria-lint`
  enforces (see next node).

Reference the v6 four-piece file table — Objective / Why / Boundary /
How-to-verify map to spec.md / stance.md / spec.md / acceptance.md in
the original methodology; here they collapse into one `wo.md` with
named sections. Do not split into 4 files at this layer.

Emit PASS once the file passes a self-read: every four-piece element
is present, no section is empty, no acceptance item is aspirational
("should be good") or implementation-prescriptive ("uses Redis").

## Node: `criteria-lint` (execute)

Goal: mechanical check that the acceptance criteria block in `wo.md`
meets the BF Core lint rules. No subjective review at this node — it
either passes the lint or it doesn't.

Invocation:

```bash
node bin/lib/criteria-lint.mjs <path-to-wo.md>
```

or equivalently via the harness:

```bash
node bin/bf-harness.mjs criteria-lint <path-to-wo.md> --tier functional
```

Lint rules enforced (see [`../../../pipeline/criteria-lint.md`](../../../pipeline/criteria-lint.md)):
acceptance items are observable, each is independently checkable,
no duplicates, no nested aspiration.

Verdict mapping:

- **PASS** — lint clean → forward to `gate`.
- **ITERATE** — lint flagged fixable issues (wording, missing
  observability) → back to `write-criteria` with the lint output
  attached to the handshake's `notes`. Edge limit: `maxLoopsPerEdge:
  3`; on overflow the orchestrator must escalate (FAIL up).

This node never emits FAIL directly — structural failure (no
acceptance section at all) is treated as ITERATE so `write-criteria`
can repair it.

## Node: `gate` (gate)

Goal: synthesize the prior nodes' verdicts and decide WO transition.
The orchestrator runs this directly via harness (no subagent
dispatch), per [`../../../pipeline/gate-protocol.md`](../../../pipeline/gate-protocol.md).

Procedure:

1. `node bin/bf-harness.mjs synthesize <run-dir> --node criteria-lint`
   — aggregate the upstream verdict.
2. Inspect the synthesized output: verdict + totals + per-role notes
   from `discuss`.
3. Decide:
   - **PASS** — WO transitions `new → shaped`. Flow terminates.
   - **ITERATE** — minor authoring issue surfaced post-lint (e.g.
     synthesize quality gate tripped on `discuss` eval thinness) →
     back to `write-criteria`.
   - **FAIL** — substantive four-piece disagreement or scope question
     that lint can't fix → back to `discuss` for another round.

Loop / reentry budget enforced by flow `limits`. On terminal PASS,
the orchestrator writes the `shaped` state into the WO state file.

## Findings

(probe output captured while wiring this flow under bf-harness)

- `bf-harness viz` happy-path renderer only shows the PASS edge per
  node — the ITERATE edge from `criteria-lint → write-criteria` and
  the FAIL/ITERATE back-edges from `gate` are present in the JSON but
  do not appear in the ASCII visualization. Not blocking, but Stage 4
  viz should render branching edges so reviewers see the full graph.
- The flow JSON's top-level `core_type`, `accepts`, `produces` fields
  (BF Core additions over OPC's flow JSON) are silently accepted by
  the current `bf-harness` — it loads the graph cleanly and does not
  validate or reject them. Confirms the JSON shape is forward-compat
  with the harness, but also confirms Stage 4 needs a Pack-aware
  validator that enforces these fields.
- `rolesDir` / `protocolDir` in flow JSON must resolve inside the
  flow's own directory (the harness rejects `../` escapes). For
  Pack flows that share Core roles, the resolution must be done by
  the dispatcher, not the flow file — so those keys are omitted here.
