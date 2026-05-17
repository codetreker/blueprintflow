# close-leaf-task — Node Protocol

Flow: [`../flows/close-leaf-task.json`](../flows/close-leaf-task.json)
`core_type: close` · accepts `task` WO in state `doing` · produces `done`.

Purpose: take a single shaped task WO from `doing` to `done` by
implementing the change, reviewing it, verifying it independently, and
gating on synthesized evidence. The flagship BF leaf flow — the
analogue of OPC's `build-verify` template, expanded with code-review
and an independent verification pass per BF axiom 5 ("the agent that
does the work does not verify it"). Derived from v6 `bf-task-execute`
(execution loop), `bf-pr-review-flow` (review semantics), and
`bf-verification` (verification semantics); role mapping derived from
`bf-team-roles`.

Node graph: `implement → code-review → verify → gate`.

Edge map (see flow JSON for the canonical):

- `implement: { PASS → code-review }`
- `code-review: { PASS → verify, ITERATE → implement, FAIL → implement }`
- `verify: { PASS → gate, ITERATE → implement, FAIL → implement }`
- `gate: { PASS → null (done), ITERATE → implement, FAIL → implement }`

`implement` is the single re-entry sink — both review and verification
push back to it; there is no "fix it in review" node. Loop budget is
generous (`maxLoopsPerEdge: 4`, `maxNodeReentry: 8`) because two
independent gates can each demand changes.

## Node: `implement` (build)

Goal: execute the change described by the task WO until the
`Acceptance criteria` checklist self-passes locally.

Inputs:

- `wo.md` `Objective`, `Boundary`, `Acceptance criteria` sections
  (frozen by upstream `brainstorm-task` / `breakdown-milestone-to-task`).
- Any `design.md` artifact carried in the WO directory (optional;
  required for v6-style code tasks that already went through
  implementation-design review).
- The worktree at `<repo>/.worktrees/<task>` (one task, one worktree,
  one branch, one PR — see v6 `bf-task-execute` § Steps 6, 13).

Default role: `engineer` (Pack
[`../roles/engineer.md`](../roles/engineer.md), Pack-vendored from OPC).
Single coordinator — implementation is one role's responsibility, not
a multi-role round. Helpers may be dispatched under it for bounded
leaf work (large file reads, mechanical refactors, test scaffolding).

Dispatch envelope: build the prompt from a (forthcoming, deferred to
later vendor pass) `pipeline/implementer-prompt.md`, plus the
`engineer` role file, plus this WO's `Acceptance criteria` block
as the spec. Until the implementer prompt is vendored, the
orchestrator may inline the structure below.

Working loop (subagent-driven-development style — v6
`bf-task-execute` step 10 + the OPC test-driven-development pattern):

1. Read `wo.md` end-to-end. Re-read `Acceptance criteria` separately.
2. For each acceptance item that is not already covered by a test:
   write a failing test that, when green, proves the item observable.
3. Implement the minimum change that turns the new tests green.
4. Run the project's local test command (whatever the repo defines —
   typically `test/run-all.sh`, `npm test`, `pytest`, etc.). Iterate
   until green.
5. Commit on the task branch with a descriptive message. Multiple
   commits are fine within the single task PR.
6. Self-check the `Acceptance criteria` list — every box `- [ ]` either
   has a test or has documented evidence in the handshake `notes`.
7. Emit PASS once all acceptance items self-pass and the working tree
   is clean (committed).

Out of scope at this node:

- Opening a PR (handled by orchestration outside the flow; v6
  `bf-git-workflow` owns it).
- Reviewing the diff (that is the next node).
- Producing the final acceptance evidence (the next-next node).

Anti-patterns (carried from v6 `bf-task-execute` § Anti-patterns):
implementing past `Boundary`, marking acceptance items "done" without
a test, treating the implementer as also the reviewer or verifier.

## Node: `code-review` (review)

Goal: PR-style multi-role review of the diff produced by `implement`.
Independent from the implementer (BF axiom 5). Catches what the
implementer missed across architecture, security, and adversarial
angles.

Default roles to dispatch:

- `engineer` (Core
  [`../../../roles/`](../../../roles/) does not own engineering review —
  Pack [`../roles/engineer.md`](../roles/engineer.md) carries it).
  Owns implementation quality: correctness, readability, edge cases.
  Distinct from the `implement` engineer — must not be the same
  subagent identity (see v6 `bf-pr-review-flow` LGTM rule: author
  cannot self-approve).
- `architect` (Core) — owns architectural consistency, cross-skill
  conflicts, cost reasonableness.
- `security` (Core) — **mandatory and independent**, per v6
  `bf-team-roles` § Security. Walks an injection / authz / data-
  isolation / dependency checklist. May not be merged with Architect.
- `skeptic-owner` (Core) — **mandatory**. Adversarial owner stance,
  per Core review conventions. NOT_LGTM is sticky and forces FAIL.

Optional roles to add when scope warrants (do not pull in by default;
keeps reviewer count manageable):

- `pm` (Pack) — when the change shifts user-visible product behavior.
- `tester` (Core) — when the change touches test infrastructure (the
  verifier-as-reviewer; otherwise reserve `tester` for the `verify`
  node so the two roles stay independent).
- `a11y` (Core) — when the change touches frontend UI.

Each role writes its own `eval-<role>.md` per
[`../../../pipeline/role-evaluator-prompt.md`](../../../pipeline/role-evaluator-prompt.md)
using the **Review Output Format** section. Findings must cite
`file:line`, include `reasoning:` and `fix:`, and obey the severity
calibration (🔴 / 🟡 / 🔵).

Verdict mapping (derived from v6 `bf-pr-review-flow` three-gate
merge rule, scoped to in-flow review only — the PR merge itself is
out of flow):

- **PASS** — every required role LGTM (or only 🔵 suggestions
  outstanding), no 🔴 critical open → forward to `verify`.
- **ITERATE** — fixable issues localized to the diff (specific
  `file:line` Warnings; 🔴 with a clear fix) → back to `implement`
  with the findings attached as `notes`. The implementer addresses
  each finding and re-emits PASS.
- **FAIL** — structural issue (wrong approach, security red line
  crossed, skeptic-owner NOT_LGTM, or the diff is genuinely off-spec
  vs `Boundary`) → back to `implement` for a deeper rework. Same
  destination as ITERATE; the difference is the depth of the cycle.

Note: this node does **not** decide PR-merge gating. The flow
operates inside a single task WO; PR open/merge orchestration sits
outside the flow (v6 `bf-git-workflow` + `bf-pr-review-flow` § three-
gate merge rule). The flow's `gate` node consumes this node's
synthesized verdict — not GitHub's merge state.

## Node: `verify` (execute)

Goal: independent verification that the changed behavior is real,
evidenced, and reproducible — not just that the diff compiles.
Independent from `implement` and ideally from `code-review` (BF
axiom 5 + v6 `bf-verification` § "evidence not assertion").

Default roles to dispatch:

- `tester` (Core
  [`../../../roles/tester.md`](../../../roles/tester.md)) — owns
  acceptance walkthrough: for every checklist item in the WO's
  `Acceptance criteria`, the tester drives the actual product
  surface (UI, API, CLI, data, background job) and captures
  evidence. Verifies that the implementer's tests cover the item;
  also looks for what was not tested (adversarial coverage,
  edge cases the implementer skipped). Per v6 `bf-verification` §
  Anti-patterns: green CI alone is not LGTM.
- `compliance` (Core
  [`../../../roles/compliance.md`](../../../roles/compliance.md))
  — when the change touches data handling, retention, licensing,
  or release-regression scope. Skip otherwise.

Procedure (per v6 `bf-verification` § Select References — pick the
surfaces that apply):

1. Re-read `wo.md` `Acceptance criteria` from scratch (no carry-over
   context from `implement` or `code-review`).
2. Select verification surfaces: UI / API / data / CLI / background.
3. For each acceptance item: drive the real surface, capture evidence
   (screenshot, transcript, exit code, log excerpt) with an
   interpretation sentence — never raw output alone.
4. Run the project's full test suite (not just the implementer's new
   tests). Note any unrelated failures as `threads` (do not block
   on flakes the implementer did not introduce — separately filed).
5. Record the verification report into the WO directory (typically
   `acceptance.md` or appended to `wo.md` § Notes), formatted per
   the v6 `bf-verification/references/acceptance-evidence.md` shape.

Verdict mapping (verifier vocab: LGTM / HOLD / BLOCK mapped to the
BF gate verdicts):

- **PASS** (verifier LGTM) — every required acceptance item has
  reproducible evidence, full test suite is green → forward to
  `gate`.
- **ITERATE** (verifier HOLD) — evidence missing or unclear but
  fixable without implementation change (e.g. tester needs a CLI
  flag added for repro, or the implementer must capture and attach
  evidence the test alone does not preserve) → back to `implement`.
- **FAIL** (verifier BLOCK) — behavior fails an acceptance item,
  exposes drift / security risk, or full test suite fails on
  implementer's code → back to `implement` for substantive rework.

The verifier acts adversarially. Hollow LGTM (no evidence cited)
trips the D2 compound eval quality gate at the next node.

## Node: `gate` (gate)

Goal: synthesize evidence from both `code-review` and `verify` and
decide the WO transition. The orchestrator runs this directly via
harness, per
[`../../../pipeline/gate-protocol.md`](../../../pipeline/gate-protocol.md);
no subagent dispatch.

Procedure:

1. Synthesize the verification node first (the proximate upstream):

   ```bash
   node bin/bf-harness.mjs synthesize <run-dir> --node verify
   ```

2. Also synthesize the upstream `code-review` so its evidence is in
   scope (BF synthesizes per-node; the gate consults both):

   ```bash
   node bin/bf-harness.mjs synthesize <run-dir> --node code-review
   ```

3. Inspect both outputs: verdict, totals, per-role notes, and the
   `evalQualityGate` / `evaluatorGuidance` blocks if the D2 compound
   gate tripped on either node.
4. Mechanical checks (per gate-protocol Step 2): every 🔴 finding has
   `file:line` + `→ Fix:`; hedging language ("might", "could") is
   challenged or downgraded.
5. Decide:
   - **PASS** — both nodes LGTM, no open 🔴, D2 quality gate clean
     on both. Task WO transitions `doing → done`. Flow terminates
     (terminal PASS — this is the last leaf flow for the task).
   - **ITERATE** — minor synthesis drift (e.g. evaluator guidance
     triggered on one role, fixable by re-running with the guidance
     hints injected) → back to `implement` for one tightening pass.
   - **FAIL** — substantive evidence gap, conflicting role verdicts
     the synthesizer could not resolve, or D2 hard-trip on the
     critical path → back to `implement`. Same destination as ITERATE
     because there is no in-flow review/verify rework node; rework
     starts from `implement` and re-flows forward.

Loop / reentry budget enforced by flow `limits`
(`maxLoopsPerEdge: 4`, `maxTotalSteps: 25`, `maxNodeReentry: 8`).
The 8-reentry budget on `implement` accommodates the worst case
where both gates push back twice each before a clean PASS.

On terminal PASS the orchestrator writes the `done` state into the
WO state file. Out-of-flow follow-up (PR merge, milestone roll-up,
Active Task Resume cleanup) is owned by the parent loop flow — v6
maps this to `bf-milestone-progress`, and BF's `loop-milestone`
flow consumes the `done` signal.

## Findings

(probe output captured while wiring this flow under bf-harness)

- **#1 — `Teamlead` role has no Pack role file.** v6
  `bf-team-roles` defines a 7-role roster (6 specialists + 1
  Teamlead) and treats Teamlead as the top-level orchestrator
  ("you don't spawn the Teamlead — you are the Teamlead"). In BF
  the equivalent is the orchestrator itself running the harness;
  there is no subagent to dispatch and therefore no role file is
  required at this layer. Deliberately not authoring
  `packs/product-engineering/roles/teamlead.md` here — the role's
  responsibilities map onto the harness + gate protocol, not onto
  an evaluator persona. Flagged for Stage 6 documentation: add a
  pack-level note (e.g. in `packs/product-engineering/README.md`)
  that the Teamlead persona = the BF orchestrator and is not a
  dispatchable role.

- **#2 — v6 role names overlap with OPC vendor role names.** v6
  `bf-team-roles` ships `Dev` / `QA` / `PM` / `Architect` /
  `Designer` / `Security`. OPC (vendored into BF Core + Pack)
  ships `engineer` (== Dev), `tester` (== QA), `pm` (== PM),
  `architect` (== Architect), `designer` (== Designer), `security`
  (== Security). The vendor names already cover every v6 role
  except Teamlead (see #1). Decision in this protocol: **use OPC
  vendor names** (`engineer`, `tester`, `architect`, `security`,
  `pm`, `designer`). v6 names can be added as documentation
  aliases in `packs/product-engineering/reference-v6/README.md`
  during Stage 4 or 6. Not authoring an alias map here — Stage
  3.6d is scoped to the close flow itself.

- **#3 — PR open/merge orchestration is out of flow.** v6
  `bf-task-execute` § Step 13 + `bf-pr-review-flow` § three-gate
  merge rule treat PR open and squash-merge as part of the close
  loop. In BF the flow operates inside a single task WO directory
  and emits a state transition (`doing → done`) — the
  worktree/branch/PR lifecycle is a separate orchestration
  concern (Stage 4 dispatcher work). The protocol therefore says
  "out of flow" for PR mechanics and gates only on synthesized
  in-flow evidence. Stage 4 should bind a post-PASS hook that
  invokes the equivalent of `bf-git-workflow` to open / merge the
  PR; the gate node's PASS handshake should include enough metadata
  (task id, branch name, evidence pointers) for that hook to act
  without re-reading the WO.

- **#4 — Two independent gates both push back to `implement`.**
  Both `code-review` and `verify` route their non-PASS verdicts to
  `implement`, which combined with `gate`'s own pushback gives
  three edges converging on one node. This pressures
  `maxNodeReentry` more than a typical close loop; bumped to 8
  (default would be 5 per `brainstorm-task`). Stage 4 viz should
  render the three back-edges so reviewers see the convergence —
  the current happy-path renderer only shows forward PASS edges
  (carried Finding from 3.6a).

- **#5 — `rolesDir` / `protocolDir` omitted (carried from 3.6a /
  3.6c).** The current harness rejects `../` escapes when
  resolving those keys, and Pack flows need to share Core roles
  across `roles/` (Core) and `packs/product-engineering/roles/`
  (Pack). Resolution must happen in the dispatcher, not the flow
  file. Stage 4 dispatcher work should add a multi-root role
  resolver and re-introduce these keys.
