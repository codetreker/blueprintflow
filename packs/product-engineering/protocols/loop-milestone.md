# loop-milestone — Node Protocol

Flow: [`../flows/loop-milestone.json`](../flows/loop-milestone.json)
`core_type: loop` · accepts `milestone` WO in state `broken_down` · produces `children_done`.

Purpose: drive a `broken_down` milestone WO to `children_done` by
recursively executing each child task WO under it, respecting
sibling-only `depends_on` edges (per
[`core-contracts.md`](../../../docs/specs/2026-05-16-bf-fork-design/core-contracts.md)
§90). Derived from v6 `bf-milestone-progress` (task selection,
acceptance reconciliation, milestone closure readiness) with the
loop-specific dispatch/await/aggregate semantics pulled in from Core's
`loop` core_type contract (core-contracts §181).

Node graph:
`dispatch-children → await-children → aggregate → gate`,
with `await-children → ITERATE → dispatch-children` and gate-level
back-edges for FAIL/ITERATE.

This flow does **not** brainstorm or break down anything — those are
upstream (`brainstorm-task`, `breakdown-milestone-to-task`). It does
**not** close the milestone — that is the downstream `close` flow's
job. It only owns: "are all my children done yet, and if not, drive
the ready ones forward."

## Node: `dispatch-children` (execute)

Goal: enumerate the milestone's child task WOs (filesystem listing of
`<milestone-wo-dir>/*/wo.md` per core-contracts §357), select the
**ready** ones (state ∈ {`shaped`, or `doing` that was interrupted}
AND every id in their `depends_on` is at the child's
`produces.desired_state`), and trigger each one's `execute` cycle.

Per core-contracts §181 the canonical loop core dispatches children
"in parallel respecting `depends_on`". In practice, dispatch means:
for each ready child, invoke `bf <execute-subverb> <child-wo-id>`
(Stage 4 `bf-run` will provide the concrete subverb).

Procedure:

1. List `<milestone-wo-dir>/*/wo.md`; for each, read state from the
   YAML frontmatter or `runs/current/state.json`.
2. Build the ready-set: children whose `depends_on` siblings are all
   at their `desired_state`, and whose own state is not yet
   `desired_state` and not currently in-flight.
3. For each ready child, dispatch its execute cycle. The build agent
   issues this as a sub-run; the harness (Stage 4) is expected to
   register each dispatch as a tracked subordinate run under the
   parent loop run's directory.
4. Emit PASS once every currently-ready child has been dispatched
   (zero ready children also PASSes — proceed to `await-children`).

Exit signal: PASS — ready-set dispatched (possibly empty).

## Node: `await-children` (execute)

Goal: wait until the dispatched children reach a terminal state
(`done` or `BLOCKED`), then decide whether more work is ready to
dispatch or aggregation can begin.

Polling mechanism (target, see Findings #2):

1. For each dispatched child, poll `<child-wo-dir>/wo.md` or
   `<child-wo-dir>/runs/current/state.json` for terminal state.
2. When all dispatched children are terminal, re-evaluate the
   sibling ready-set (a child finishing may have unblocked siblings
   that were previously waiting on `depends_on`).
3. If new siblings are now ready → ITERATE back to
   `dispatch-children` to fan them out.
4. If no new siblings are ready AND no children are in-flight →
   PASS forward to `aggregate`.

Verdict mapping:

- **PASS** — all reachable children are terminal; nothing left to
  dispatch. Forward to `aggregate`.
- **ITERATE** — children terminated, but newly-unblocked siblings
  exist. Back to `dispatch-children`.

(No FAIL emitted here; a failed child surfaces during `aggregate`
review, not at the polling layer.)

## Node: `aggregate` (review)

Goal: multi-role review of the **set** of child outcomes — not of
each child WO individually (its own `close` flow already did that) —
asking: did all required children reach `done`, are there integration
issues across them, and is the milestone's Objective now realized?

Default roles to dispatch:

- `planner` — verifies acceptance coverage: every Acceptance
  criterion on the milestone WO maps to evidence in at least one
  child's accepted outcome.
- `tester` — verifies integration-level signals (cross-child seams
  that no individual child's review could see).
- `skeptic-owner` — **mandatory**. Owns the "did we actually
  deliver the milestone, or just the tasks we happened to cut?"
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

- **PASS** — all required children at `done`, integration LGTM →
  forward to `gate`.
- **FAIL** — one or more children failed acceptance, OR
  integration-level defect found, OR skeptic-owner NOT_LGTM. Routes
  back to `dispatch-children` so the failed/affected child(ren) get
  re-executed. See Findings #3 — current edge map re-dispatches the
  entire ready-set; protocol-level guidance is for the build agent
  to scope re-dispatch to only the failed children by setting their
  WO state back to `shaped` before re-entering `dispatch-children`.

(No ITERATE from this node; aggregation either passes the milestone
to the gate or sends work back into the dispatch loop.)

## Node: `gate` (gate)

Goal: synthesize the prior nodes' verdicts and decide milestone WO
transition. The orchestrator runs this directly via harness (no
subagent dispatch), per
[`../../../pipeline/gate-protocol.md`](../../../pipeline/gate-protocol.md).

Procedure:

1. `node bin/bf-harness.mjs synthesize <run-dir> --node aggregate`
   — aggregate the upstream verdict (with D2 compound eval quality
   gate).
2. Verify on-disk state: every child WO under
   `<milestone-wo-dir>/*/wo.md` is at its `desired_state`.
3. Decide:
   - **PASS** — milestone WO transitions `broken_down →
     children_done`. The downstream `close` flow picks it up. Flow
     terminates.
   - **ITERATE** — aggregation was marginal (e.g., D2 evaluator
     quality gate tripped on `aggregate`) but no concrete child
     failed → re-run `aggregate` with refreshed evaluator guidance.
   - **FAIL** — concrete child failure or structural defect → back
     to `dispatch-children` to re-execute the affected child(ren).

Loop / reentry budget enforced by flow `limits`
(`maxLoopsPerEdge: 5`, `maxTotalSteps: 30`, `maxNodeReentry: 10`).
Per Findings #4, these are deliberately larger than the
`breakdown-milestone-to-task` flow's because a loop with N children
naturally re-enters `dispatch-children` ~N times even on a happy
path.

## Findings

(probe output captured while wiring this flow under bf-harness)

- **#1 — "node spawns child runs" not supported by current
  harness.** The `dispatch-children` execute node, as described,
  needs to spawn N sub-runs (one per child WO) under the parent
  loop run. Today's `bin/bf-harness.mjs` has no `dispatch-child-wo`
  subcommand and no notion of nested runs — it operates one run at
  a time on a flat directory. This protocol describes the **target**
  behavior; Stage 4 `bf-run` must implement child-run dispatch
  (likely as `bf-run execute --parent-run <run-id> <child-wo-id>`
  with the child run nested under
  `<parent-run-dir>/children/<child-id>/`).
- **#2 — No polling/notify mechanism for child-run terminal
  state.** `await-children` assumes it can read child state from
  `<child-wo-dir>/wo.md` frontmatter or
  `<child-wo-dir>/runs/current/state.json`, but core-contracts §357
  is the only place a stable on-disk state location is hinted at,
  and `runs/current/state.json` is not yet specified anywhere in
  Core. Stage 4 needs to (a) standardize the per-WO live-state
  file, and (b) decide whether await is a true poll loop or whether
  child runs PUT a `done` marker the parent watches via inotify /
  next-cycle scan. Flagged as a contract gap, not just a harness
  gap.
- **#3 — `aggregate.FAIL` re-dispatches the whole ready-set, not
  just the failed child.** The loop's edge map only lets `aggregate`
  route to one downstream node on FAIL. Today that's
  `dispatch-children`, which will re-enumerate every ready child —
  including ones that already succeeded. Protocol-level workaround:
  the build agent at re-dispatch time consults each child's current
  state and skips children already at `desired_state` (idempotent
  dispatch). Cleaner alternative for Stage 4: edge values become
  structured ({"verdict": "FAIL", "scope": [child-id, ...]}) so
  the dispatcher can target the affected subset. Documented as a
  Core flow-edge schema limitation.
- **#4 — Loop limits are inherently larger than non-loop flows.**
  A milestone with N children naturally re-enters `dispatch-children`
  on the order of N times (once per dependency wavefront). `breakdown`
  uses `maxLoopsPerEdge: 3, maxTotalSteps: 18`; this flow uses 5/30.
  For very wide milestones (>10 children) even 5/30 may trip — Stage 4
  may want loop-type-aware default budgets that scale with the child
  count discovered at `dispatch-children` entry, rather than static
  flow-file caps. Logged for harness limits review.
- **#5 — Carried from 3.6a/b: `rolesDir` / `protocolDir` omitted.**
  Same Pack-vs-Core resolution gap as
  [`brainstorm-task.json`](../flows/brainstorm-task.json) and
  [`breakdown-milestone-to-task.json`](../flows/breakdown-milestone-to-task.json).
  Dispatcher should resolve roles; flow file should not need to
  declare them.
