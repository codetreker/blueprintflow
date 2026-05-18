# Stage 5 Demo — End-to-End Real-Agent Run

> Top-level summary of the Stage 5.2 + 5.3 real-agent demo. The two
> sub-traces (`./2026-05-18-stage-5-demo/{brainstorm,close-leaf}-run.md`)
> hold the per-node detail.

## Demo task

- **Description**: "Add bf version verb that prints package.json version"
- **WO id**: `add-bf-version-verb-that-prints-package-json-version`
- **Schema / Pack**: `task` / `product-engineering`
- **Real code shipped**: commit `a202ef8` ("feat(bf): bf version verb prints package.json version")

## Pipeline

```
new ──brainstorm-task──▶ shaped ──[manual flip]──▶ doing ──close-leaf-task──▶ done
```

The `[manual flip]` step is a v0.2 routing gap (no rule for `task,shaped`);
finding #5 below proposes the fix.

## Per-stage outcomes

### Stage 5.2 — brainstorm-task
See [brainstorm-run.md](./2026-05-18-stage-5-demo/brainstorm-run.md).
Headline: 4 nodes (discuss → write-criteria → criteria-lint → gate)
walked end-to-end with real `planner`/`architect`/`engineer`/`tester`
subagents (sonnet). Produced 8 concrete acceptance criteria; no ITERATE
loops needed. Final WO state: `shaped`.

### Stage 5.3 — close-leaf-task
See [close-leaf-run.md](./2026-05-18-stage-5-demo/close-leaf-run.md).
Headline: real code shipped at commit `a202ef8`; full suite ran
135/0/1 after `implement` added a verb + test. 4 nodes
(implement → code-review → verify → gate) all PASS first pass. Final
WO state: `done`.

## Stage 6 input list

Numbered findings lifted from the two sub-traces' `## Findings` sections.

1. **`--dir` sandbox missed `~/.bf/wo/`** — Severity: clarification.
   FIXED in-demo at commit `49e3f94`. No contract update required;
   documented in close-out only.
   - Affects: `bin/lib/util.mjs` (code, already fixed)
2. **`criteria-lint` Pack/Core section-name mismatch** — Severity:
   clarification. OPC-shaped `Outcomes`/`Verification`/`Quality`/`Scope`
   hard-coded; BF Pack protocol produces `Objective`/`Boundary`/
   `Acceptance criteria`. **Recommended fix:** widen `criteria-lint`
   to accept BF section names (BF names are the Core convention).
   - Affects: `bin/lib/criteria-lint.mjs` (code)
3. **Gate-type nodes incorrectly request agents** — Severity: important.
   `node-runner.mjs` returns `agents-needed` for gate nodes; per
   `pipeline/gate-protocol.md`, gates synthesize verdicts from upstream
   evals mechanically. **Recommended fix:** in `node-runner.mjs`, treat
   `nodeType === 'gate'` as auto-synthesize, skipping the
   `agents-needed` round-trip.
   - Affects: `bin/lib/dispatcher/node-runner.mjs` (code) +
     `references/flow.md` clarification
4. **Acceptance-criteria checklist (`- [ ]`) not toggled to `[x]`** —
   Severity: clarification. The state machine IS the acceptance signal
   (`current_state == done`); the checklist is the static record of
   what `done` was defined as during shaping. **Recommended fix:**
   document in `references/work-object.md`; no behavioral change.
   - Affects: `references/work-object.md` (doc)
5. **Routing gap `task,shaped → ?`** — Severity: clarification (with
   real friction). v0.2 has no routing rule for leaf tasks coming out
   of `shaped`. **Recommended fix:** add `"task,shaped":
   "close-leaf-task"` to `packs/product-engineering/pack.json`
   `routing`. In the product-eng Pack, `task` is the leaf schema, so
   the rule is unambiguous.
   - Affects: `packs/product-engineering/pack.json` (Pack config) +
     `references/pack.md` clarification
6. **Demo pollutes the demo-runner's repo** — Severity: nice-to-have.
   The `implement` subagent committed real code into the demo's own
   worktree. Convenient for proof, but blurs "BF output" vs
   "developer output". **Recommended fix:** none for v1; document in
   retro; future demo runs target a scratch repo.
   - Affects: retro doc only
7. **Gate node redundancy (re-confirmation of #3).** No separate action.
8. **No criteria-toggling (re-confirmation of #4).** No separate action.

## Demo verdict

**End-to-end runnable: YES.** A fresh task WO drove `new → shaped → doing
→ done` with real Claude subagents producing every artifact along the
way, and the `implement` node shipped real code that's now in the repo.
Findings #2 / #3 / #5 are concrete code/config fixes for Stage 6.1;
findings #1 / #4 / #6 are clarifications or already closed.
