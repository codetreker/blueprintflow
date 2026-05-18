# Stage 5.2 — brainstorm-task real-agent run

> First half of the Stage 5 end-to-end demo. Drove `task` WO
> `add-bf-version-verb-that-prints-package-json-version` from
> `current_state: new` → `shaped` using the SKILL.md orchestrator
> + 4 real subagents (planner, architect, engineer, tester) +
> the BF dispatcher / harness landed in Stages 1–4.

## Demo task

- **WO id**: `add-bf-version-verb-that-prints-package-json-version`
- **WO path**: `~/.bf/wo/add-bf-version-verb-that-prints-package-json-version/`
- **Description**: "Add bf version verb that prints package.json version"
- **Schema**: `task`
- **Pack**: `product-engineering`
- **Created via**: `node bin/bf.mjs create "..." --pack product-engineering --schema task`

## Walk-through

### Node: `discuss` (discussion)

| Aspect | Value |
|---|---|
| Roles dispatched | `planner`, `architect` |
| Subagent model | sonnet |
| Artifacts produced | `eval-planner.md`, `eval-architect.md` |
| Verdicts | PASS, PASS |
| Seal | `{sealed: true}` |
| Transition | `discuss → write-criteria` |

Both agents converged on the same four-piece without an ITERATE
round. Planner owned Objective phrasing; architect owned Boundary
(naming concrete out-of-scope items: no `--version` flag, no
`npm`/`git` shell-outs, no new dependencies). Both rejected over-
engineering the verb; both agreed sizing fits a single task.

### Node: `write-criteria` (build)

| Aspect | Value |
|---|---|
| Roles dispatched | `engineer` |
| Subagent model | sonnet |
| Artifacts produced | `eval-engineer.md` + **rewritten `wo.md`** |
| Verdict | PASS |
| Seal | `{sealed: true}` |
| Transition | `write-criteria → criteria-lint` |

Engineer turned the frozen four-piece into 8 concrete acceptance
criteria, each observable from outside the implementation
(verb file existence, KNOWN_VERBS entry, stdout match, exit
code, help listing, test file existence, test suite count
increase, VERB_DOCS entry). Output replaced the brainstorm
placeholder text in `wo.md`.

### Node: `criteria-lint` (execute)

| Aspect | Value |
|---|---|
| Roles dispatched | `tester` (mechanical lint runner) |
| Artifacts produced | `eval-tester.md`, `cli-output.log` |
| Verdict | PASS (with Stage 6 finding) |
| Seal | `{sealed: true}` |
| Transition | `criteria-lint → gate` |

`bf-harness criteria-lint` reports 4 structural failures
(`outcomes-exist` / `verification-exists` / `quality-section` /
`scope-section`) because the OPC lint expects `## Outcomes` /
`OUT-N` bullets, not the BF Pack's `## Acceptance criteria` /
`- [ ]` checklist. Tester verdict was PASS because the criteria
meet the brainstorm-task protocol's quality bar; the lint
mismatch is a Stage 6 finding.

### Node: `gate` (gate)

| Aspect | Value |
|---|---|
| Roles dispatched | `planner` (defaulted by node-runner — see Finding 3) |
| Artifacts produced | `eval-planner.md` |
| Verdict | PASS |
| Finalize | `{finalized: true, terminalNode: "gate", newState: "shaped"}` |

WO `current_state` updated to `shaped`. Next `bf execute` returned
`{stuck, hint: "no flow for task,shaped"}` — expected per Stage 4
routing-gap doc; 5.3 flips the state manually.

## Findings (Stage 6 input)

1. **`--dir` sandbox didn't allow `~/.bf/wo/`** (FIXED in-demo,
   commit `49e3f94`). Test 4.2a widened to `/tmp/bf-*` but missed
   the canonical WO home. Added `test-g-dir-wo-home.sh`.

2. **`criteria-lint` Pack-vs-Core schema mismatch.** OPC-shaped
   section names (`Outcomes` / `Verification` / `Quality` / `Scope`)
   are hard-coded in `bin/lib/criteria-lint.mjs`; BF Pack protocol
   produces `Objective` / `Boundary` / `Acceptance criteria`.
   Severity: clarification. Recommendation: widen the lint to also
   accept BF section names (BF section names are the documented
   Core convention).

3. **Gate-type nodes request roles.** `node-runner` returns an
   `agents-needed` envelope for gate nodes, defaulting the role to
   `planner` (from `defaultRolesForType('gate') → ['planner']`).
   Per `pipeline/gate-protocol.md`, gates synthesize from upstream
   evals mechanically; no role dispatch is needed. Severity:
   important. Fix: in `node-runner.mjs`, treat `nodeType === 'gate'`
   as auto-synthesize (read upstream evals, compute verdict, seal +
   transition) without an `agents-needed` round-trip.

4. **Acceptance criteria checklist (`- [ ]`) not toggled to `[x]`.**
   The build/execute/gate nodes don't mark individual criteria as
   met; the WO's final `Acceptance criteria` section still shows
   all `- [ ]` even after `current_state: done`. Severity:
   clarification. Question for Stage 6: are acceptance criteria
   meant to be toggled by the orchestrator, or is "WO state =
   done" the singular acceptance signal? Recommendation: the
   latter (state machine is the truth; checklist is for humans).

## Test result

Suite still 134/0/1 (Stage 4 baseline + Task 4.2a–g harness tests +
Stage 5.1 orchestrator shape test).
