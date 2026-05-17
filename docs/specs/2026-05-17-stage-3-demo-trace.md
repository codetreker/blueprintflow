# Stage 3 Demo Trace

> Manual walk-through of two probe flows (`brainstorm-task`,
> `close-leaf-task`) via `bf-harness`, exercising the Pack-supplied flow
> JSON authored in Task 3.6. Stage 4's dispatcher will automate the
> orchestration; here we just confirm the JSON + harness mechanics work
> when fed Pack flows from outside `flows/templates/`.

## Demo task

No suitable v6 task existed under `docs/tasks/` (only `BOARD.md`). A
1-acceptance-criterion synthetic task was fabricated for the walk-through:

- **Title:** "Stage 3 demo: dummy task to drive probe flows"
- **State:** `new` (brainstorm entry) → `doing` (close entry)
- **Single AC:** "harness mechanics succeed end-to-end on Pack flow JSON"
- **Path (transient):** `.bf-demo/run-1/` (brainstorm), `.bf-demo/run-2/` (close)

`.bf-demo/` is process trace; not committed.

## Setup quirks (immediate)

- `--dir /tmp/bf-stage3-demo-wo/...` (per plan §3.7 step 2) is rejected
  by harness:
  ```
  ERROR: --dir resolved to '/tmp/bf-stage3-demo-wo/runs/run-1' which is
  outside cwd '...' and ~/.bf/sessions/
  ```
  Workaround: run state directories must live under cwd or
  `~/.bf/sessions/`. The plan's `/tmp/...` recipe needs an update —
  captured in must-do list.
- `--flow-file <path>` does work for Pack flows (Stage 4 won't need a
  copy step into `flows/templates/`).

## Walk-through

### brainstorm-task

Init:
```
node bin/bf-harness.mjs init \
  --flow-file packs/product-engineering/flows/brainstorm-task.json \
  --entry discuss --dir .bf-demo/run-1
```
→ `{"created":true,"flow":"brainstorm-task","entry":"discuss",...}`. The
viz only renders the happy path (`discuss → write-criteria →
criteria-lint → gate`) plus the gate's FAIL back-edge; the
`criteria-lint → write-criteria` ITERATE edge is invisible (confirms
3.6 finding 250).

`seal` requires evidence to live under `nodes/<id>/run_N/` (an empty
`nodes/<id>/` directory gives `"no run_N directories found"`). Once
populated with an `eval.md`, seal generates a valid `handshake.json`.

| Node          | Verdict | Handshake notes                                       | Observations                                                                                       |
|---------------|---------|--------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| discuss       | PASS    | 1 artifact `source` (eval.md); `verdict: null`         | Seal infers nodeType `discussion` from flow JSON. Validate passes.                                  |
| write-criteria| PASS    | 1 artifact `source`                                    | Transition allowed; edgeCount `discuss→write-criteria: 1`.                                          |
| criteria-lint | PASS    | initially failed: `"executor node missing evidence"`  | Re-sealed after adding a `cli-output.log`; then PASS. Seal does NOT infer cli-output from eval.md. |
| gate          | PASS    | 1 artifact `source`                                    | `finalize` succeeded: `{"finalized":true,"terminalNode":"gate","totalSteps":3}`.                    |

Errors encountered (verbatim):
```
{"allowed":false,"reason":"pre-transition check: handshake.json for
 'criteria-lint' has errors: executor node missing evidence (need at
 least one artifact with type: test-result, screenshot, or cli-output)",
 "handshakeErrors":["executor node missing evidence (...)"]}
```

### close-leaf-task

Init succeeded under `.bf-demo/run-2/` with `--entry implement`.

| Node        | Verdict | Handshake notes                                                 | Observations                                                                                              |
|-------------|---------|------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| implement   | PASS    | 1 artifact `source`                                              | Clean transition.                                                                                          |
| code-review | PASS    | initially failed (`review node requires ≥2 eval artifacts`)      | Required `eval-<role>.md` filenames (not `eval.md`) so seal infers type `eval`. Also required ≥1 from `skeptic-owner` (mandatory role rule fires at transition, not at seal). Final: 3 evals (tester, security, skeptic-owner). |
| verify      | PASS    | 2 artifacts (`eval`, `cli-output`)                              | execute-type evidence rule satisfied by `cli-output.log`.                                                  |
| gate        | PASS    | 1 artifact `source`                                              | Finalize OK: `{"finalized":true,"terminalNode":"gate","totalSteps":3}`.                                   |

Errors encountered (verbatim):
```
[seal code-review] review node requires ≥2 eval artifacts from
                   independent agents, got 0

[T2] {"allowed":false,"reason":"pre-transition check: handshake.json
      for 'code-review' has errors: review node requires ≥2 eval
      artifacts from independent agents, got 0"}

[T2-attempt-2] {"allowed":false,"error":"Missing mandatory role
                evaluations: [skeptic-owner]. Review node must include
                all mandatory roles."}
```

## Findings beyond what 3.6 already captured

These are *new* (not previously logged in `core-contracts.md` §249–254
or §473–477):

1. **Seal artifact-type inference is filename-driven, undocumented.**
   `bin/lib/flow-core.mjs:494–497` infers `eval` only from
   `^eval-.*\.md$`, `cli-output` from `^(command-output|cli-output).*\.(txt|log)$`,
   etc. Everything else falls through to `source`. A bare `eval.md`
   becomes `source`, not `eval`, which silently breaks review nodes.
   The Pack protocol docs in `packs/product-engineering/protocols/`
   tell agents to write `eval.md` — collision with harness convention.
2. **`--dir` sandbox blocks `/tmp/`.** The plan's recipe is wrong; the
   harness only allows directories under cwd or `~/.bf/sessions/`.
3. **`seal` needs pre-existing `run_N/` subdir.** Harness will not
   create it. Stage 4 dispatcher must mkdir `run_1/` before invoking
   any node.
4. **Mandatory-role rule (`skeptic-owner`) is hard-coded** and fires at
   *transition* time, not at seal. No Pack-overridable list. Discovered
   from `"Missing mandatory role evaluations: [skeptic-owner]"`. The
   list lives in Core; Packs cannot extend or replace it.
5. **`finalize` is idempotent** (second call returns
   `"note":"already finalized"`) — good, but undocumented.
6. **Soft `warnings` vs hard `validationErrors` on seal** — seal
   returns `sealed: true` even when `validationErrors` is non-empty.
   Caller must inspect both fields; Stage 4 dispatcher must treat
   `validationErrors.length > 0` as a failure even when `sealed` is
   true.

## Stage 4 must-do list

Stage 4 = `bf-run` dispatcher + first real automation pass. Every item
ties back to a Stage 3 finding (file/commit cited).

- [ ] **Sandbox `--dir` policy: extend to `/tmp/bf-*` or document
      reliance on cwd / `~/.bf/sessions/`.** (Stage 3.7 finding #2;
      `bin/bf-harness.mjs` dir resolver.) The plan's recipes assume
      `/tmp/` works; either the harness opens up or every recipe in
      `docs/specs/` needs the new constraint.
- [ ] **Dispatcher auto-creates `nodes/<id>/run_N/` before invoking a
      sub-agent.** (Stage 3.7 finding #3.) Today the agent must mkdir
      manually; `bf-run` should set this up so node protocols can drop
      artifacts and call `seal` directly.
- [ ] **Document or rename Pack node-output convention to match seal's
      filename inference.** (Stage 3.7 finding #1; `bin/lib/flow-core.mjs:494`.)
      Either change Core to accept `eval.md` as type `eval`, or rename
      every protocol's "Outputs" section in
      `packs/product-engineering/protocols/*.md` to use `eval-<role>.md`.
- [ ] **Pack-aware validator for `core_type` / `accepts` / `produces`.**
      (3.6 finding §249, core-contracts.md.) Stage 4 should fail fast
      on unknown core_type or schema/state outside the Pack's declared
      universe.
- [ ] **viz renders ITERATE / FAIL back-edges and convergence nodes.**
      (3.6 finding §250.) The current happy-path-only renderer hid the
      `criteria-lint → write-criteria` and `code-review → implement`
      edges during this demo.
- [ ] **Multi-root role resolver (`flow.rolesDir` → Pack `roles/` →
      Core `roles/`).** (3.6 finding §473.) Lets flow JSON re-introduce
      `rolesDir`/`protocolDir` without `../` escape errors.
- [ ] **Make mandatory-role list Pack-overridable.** (Stage 3.7 finding #4;
      hard-coded `skeptic-owner` rule in flow-transition.) Pack should
      declare its own reviewer mandatories in `pack.json` or per-flow.
- [ ] **Dispatcher must treat `seal.validationErrors[] != []` as a
      hard failure even when `sealed:true`.** (Stage 3.7 finding #6.)
- [ ] **Child-run dispatch for `loop.dispatch-children`.** (3.6 finding §251;
      `loop-milestone` probe / commit 64dad9a.) Implement
      `bf-run execute --parent-run <id> <child-wo>` nesting under
      `<parent-run-dir>/children/<child-id>/`.
- [ ] **Per-WO live-state file for parent watching children.**
      (core-contracts.md §167 + 3.6 finding §251.) Standardize the
      on-disk location + poll/notify semantics.
- [ ] **Structured edge payloads `{verdict, scope}` for loop aggregation.**
      (3.6 finding §252.) Allows targeted re-dispatch of the failed
      subset rather than the full ready-set.
- [ ] **Loop-type-aware default budgets.** (3.6 finding §253.) Wide
      milestones (>10 children) trip current 5/30 caps.
- [ ] **`bf-harness create-child-wo` (or explicit agent-side
      ownership documented).** (3.6 finding §254.) Today
      `breakdown-milestone-to-task` has no harness primitive for
      spawning child task WOs.
- [ ] **Schema completeness check at dispatcher init.** (3.6 finding §474.)
      `pack.json.routing` references `milestone,*` but
      `packs/product-engineering/schemas/` only ships `task.json`.
      Stage 4 should refuse to dispatch a routing key with no schema,
      or Stage 6 must land `milestone.json` first.
- [ ] **Document Teamlead = orchestrator (not a role file).**
      (3.6 finding §475.) Add a note in
      `packs/product-engineering/README.md`.
- [ ] **Role-name alias map (v6 names ↔ OPC vendor names).**
      (3.6 finding §476.) Document in
      `packs/product-engineering/reference-v6/README.md` so v6 muscle
      memory still resolves.
- [ ] **Post-PASS PR-lifecycle hook (`bf-git-workflow` equivalent).**
      (3.6 finding §477.) Bind to gate handshake metadata (task id,
      branch, evidence pointers); not part of in-WO state machine.

## Test result

`bash test/run-all.sh` → 108 files passed, 0 files failed (1 deferred).
