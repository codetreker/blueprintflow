# breakdown-milestone-to-task — Node Protocol

Flow: [`../flows/breakdown-milestone-to-task.json`](../flows/breakdown-milestone-to-task.json)
`core_type: breakdown` · accepts `milestone` WO in state `shaped` · produces `broken_down`.

Purpose: take a single shaped milestone WO and decompose it into N child
`task` WOs, each materialized as its own sub-directory under the
milestone's WO directory with a freshly-authored `wo.md`. Derived from
v6 `bf-milestone-breakdown` (task boundary contracts) and
`bf-implementation-design` (per-task shaping rigor pulled forward into
boundary-level review).

Node graph:
`plan-children → write-children → review-breakdown → gate`.

The flow does not shape each child task to the four-piece level — that
is the downstream `brainstorm-task` flow's job. Output here is a set of
**boundary-level** child task WOs: Objective, Boundary, Acceptance
criteria stub, plus inter-task `depends_on` edges.

## Node: `plan-children` (discussion)

Goal: converge on the task list — how many children, what each one
owns, and the dependency order. Not implementation; only boundaries.

Default roles to dispatch (from Core `roles/`):

- `planner` — owns sizing (each child fits a single PR / single
  reviewer pass), owns dependency order, and flags when the milestone
  is genuinely a leaf (no children needed → emit a single signal that
  the gate translates to a leaf decision).
- `architect` — owns structural decomposition: does this split match
  the system's seams, or does it create artificial fan-out?
- `devil-advocate` (optional but recommended) — pressure-tests the
  cut: are two "tasks" actually one? Is one "task" really three?

Use the multi-role review template at
[`../../../pipeline/role-evaluator-prompt.md`](../../../pipeline/role-evaluator-prompt.md)
to format each role's input.

Round structure (scoped down from `bf-brainstorm`):

- Round 1 (Scope): each role proposes a task list with name +
  one-line Objective + `depends_on` per item.
- Round 2 (Reconcile): only if Round 1 produced incompatible cuts.
  Reconcile to a single ordered list. Hard cap: 3 rounds.
- Freeze: orchestrator records the agreed task list (names,
  one-line objectives, dependency edges) into the milestone WO's
  `discussion.md` for `write-children` to consume.

Exit signal: PASS — task list frozen with ≥1 entry (1 = leaf-or-near-
leaf milestone; the breakdown still runs to formalize the single
child). The "this is a leaf, no children needed" decision is escalated
through the `gate` node (see core-contracts §247), not emitted here.

## Node: `write-children` (build)

Goal: materialize the frozen task list as N child WO directories on
disk, each with a self-contained `wo.md` matching
[`../schemas/task.json`](../schemas/task.json) (sections: Objective,
Boundary, Acceptance criteria).

Per `core-contracts.md` §Work Object (recursive directory pattern),
each child WO lives at:

```
<milestone-wo-dir>/<child-id-segment>/wo.md
```

For each frozen task:

1. `mkdir <milestone-wo-dir>/<child-id-segment>` — id segment is a
   kebab-case slug derived from the planned task name.
2. Author `<milestone-wo-dir>/<child-id-segment>/wo.md` with:
   - `# <Task name>` H1.
   - `## Objective` — one-paragraph user-visible outcome (≤30 words).
     Lifted from `plan-children`'s frozen one-liner, expanded with the
     parent milestone's Why.
   - `## Boundary` — explicit out-of-scope items. At minimum, name the
     adjacent sibling tasks and assert "owned by `<sibling-id>`".
   - `## Acceptance criteria` — checklist stub (`- [ ]` items). At
     least one item per "How to verify" the planner identified. May be
     skeletal; downstream `brainstorm-task` will harden it.
   - `## Notes` (optional) — any unresolved questions the planner
     flagged for downstream shaping.
3. If the planner declared `depends_on` for this child, embed it as
   YAML frontmatter at the top of `wo.md` (`depends_on: [<sibling-id>,
   ...]`) per `core-contracts.md` §90.

The build agent performs the `mkdir` and file write directly — the
harness does not own child WO directory creation (see Findings #1).

Emit PASS once every frozen child has a corresponding directory + a
`wo.md` that self-reads as complete (no empty required sections, no
TODO placeholders).

## Node: `review-breakdown` (review)

Goal: multi-role review of the materialized task set as a whole — not
of each child WO in isolation, but of the decomposition's coverage,
sizing, and dependency soundness.

Default roles to dispatch:

- `planner` — verifies coverage (the union of child Objectives covers
  the parent milestone's Objective) and sizing (no child is obviously
  two tasks, none is trivially small).
- `architect` — verifies dependency edges are acyclic and reflect
  actual technical coupling, not just narrative order.
- `tester` — verifies acceptance stubs are testable in principle (each
  child has at least one externally-observable signal).
- `skeptic-owner` — **mandatory**. Owns the "did we cut this the
  right way?" question and the "is there a hidden child we missed?"
  question. Per Core's review-role conventions, the skeptic-owner's
  NOT_LGTM is sticky and forces FAIL routing.

Use [`../../../pipeline/role-evaluator-prompt.md`](../../../pipeline/role-evaluator-prompt.md)
with the **Review Output Format** section.

**Output filename convention:** Each reviewer writes their eval as
`eval-<role>.md` (e.g. `eval-tester.md`, `eval-skeptic-owner.md`) so
the harness can distinguish independent agents. A bare `eval.md` also
works for single-reviewer nodes but cannot satisfy review nodes that
require ≥2 distinct evals.

Verdict mapping:

- **PASS** — all roles LGTM (or only 🔵 suggestions outstanding) →
  forward to `gate`.
- **ITERATE** — issues are localized to specific child WO files
  (wording, missing acceptance stub) and can be fixed by re-running
  the build step → back to `write-children` with the findings
  attached to the handshake's `notes`.
- **FAIL** — issues are structural (wrong decomposition, missing
  whole child, cycle in `depends_on`, skeptic-owner NOT_LGTM) → back
  to `plan-children` to redo the cut.

## Node: `gate` (gate)

Goal: synthesize the prior nodes' verdicts and decide WO transition.
The orchestrator runs this directly via harness (no subagent
dispatch), per [`../../../pipeline/gate-protocol.md`](../../../pipeline/gate-protocol.md).

Procedure:

1. `node bin/bf-harness.mjs synthesize <run-dir> --node review-breakdown`
   — aggregate the upstream verdict (with D2 compound eval quality
   gate).
2. Inspect the synthesized output: verdict, totals, per-role notes,
   plus `evalQualityGate` / `evaluatorGuidance` if triggered.
3. Verify on-disk state matches the planned task list: every frozen
   child name has a corresponding `<child>/wo.md`, no orphan
   directories.
4. Decide:
   - **PASS** — milestone WO transitions `shaped → broken_down`. The
     `children/` set is now authoritative; downstream `loop` flow can
     pick them up. Flow terminates.
   - **ITERATE** — minor drift between plan and on-disk set, or
     review surfaced fixable per-child issues → back to
     `write-children`.
   - **FAIL** — structural issue or D2 gate tripped on
     `review-breakdown` → back to `plan-children` for a fresh cut.

Special case — **leaf decision**: if `plan-children` froze a single
trivial child that is really the milestone itself, the gate may emit
a `leaf: true` flag in its handshake. `bf-run` short-circuits the
milestone to `doing` instead of `broken_down` (see core-contracts
§247). Not exercised in the default loop above; documented here for
the downstream `loop` flow to honor.

Loop / reentry budget enforced by flow `limits`
(`maxLoopsPerEdge: 3`, `maxTotalSteps: 18`, `maxNodeReentry: 5`).

## Findings

(probe output captured while wiring this flow under bf-harness)

- **#1 — `mkdir` ownership unspecified in Core.** `core-contracts.md`
  §180 names breakdown's job as "Shaped WO → child WOs in
  sub-directories, each with their own shaped `wo.md`", and §363
  describes the state as "breakdown flow `mkdir`s child WOs under
  this directory". Both phrasings are flow-scoped, not
  harness-scoped — there is no `bf-harness create-child-wo`
  subcommand today. This protocol therefore assigns the `mkdir` +
  initial `wo.md` write to the `write-children` build node's agent.
  Stage 4 should either (a) add a harness command to formalize child
  WO creation (so the build agent only authors content, not
  directory layout) or (b) explicitly document agent-side filesystem
  ownership in `core-contracts.md`. Flagged for Stage 4 harness work.
- **#2 — `milestone.json` schema was missing.** The flow's
  `accepts.schema: ["milestone"]` referenced a schema that did not
  exist in `packs/product-engineering/schemas/` (only `task.json`
  was present). Authored a minimal
  `packs/product-engineering/schemas/milestone.json` inline as part
  of this sub-task: states `new → shaped → broken_down →
  children_done → done`, sections mirror `task.json` with `Task
  index` added as optional. Unblocks 3.6c; revisit during Stage 6
  schema hardening.
- **#3 — `rolesDir` / `protocolDir` omitted (carried from 3.6a).**
  The current harness rejects `../` escapes when resolving those
  keys, and Pack flows need to share Core roles. Omitted here for
  the same reason as `brainstorm-task.json`; dispatcher should
  resolve roles, not the flow file.
