# BF Stage 5+6 — Real Demo + Core Revision + Migration Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement task-by-task. Steps use `- [ ]` checkboxes.

**Goal:** Turn BF v0.2.0-alpha into a v1.0.0-rc that actually runs an end-to-end product-engineering task with real Claude subagents (Stage 5), then revise Core contracts based on what the demo surfaced and write the v6 → v1 migration guide (Stage 6).

**Architecture:** The Stage 4 dispatcher is in place but `node-runner.mjs` emits stub `eval-<role>.md` files. Stage 5 wraps `bin/bf.mjs` with a thin Claude Code skill orchestrator (`SKILL.md` becomes executable instructions, not just a description) — when `node-runner` reports "node ready for agents", the orchestrator spawns one Claude subagent per required role via the host LLM (this conversation's runtime), each subagent gets the role prompt + WO context + acceptance criteria, writes its `eval-<role>.md` directly into `nodes/<id>/run_1/`, the orchestrator calls `bf-harness seal` + `transition`, then advances. Stage 6 takes the demo's gaps, lifts them into `references/*.md` (the 5 Core contracts) as v0.3 contract updates, then writes `MIGRATION.md` mapping v6 plugin concepts → v1 equivalents.

**Tech Stack:** Same as Stage 1–4 (Node 18+, Bash, file-based state). Stage 5 introduces dependency on Claude Code's Agent tool — the orchestrator calls into it during execution, but the dispatcher itself stays LLM-agnostic (real agent calls live in the `bf` skill layer, not in `bin/lib/`).

**Source of truth:** `docs/specs/2026-05-16-bf-fork-design.md` § Stages 5/6, `docs/specs/2026-05-17-stage-4-retro.md` (10 must-do items), `docs/specs/2026-05-16-bf-fork-design/{core-contracts,bf-skill-migration}.md`, `references/*.md` (current Core contracts). When plan and spec disagree, spec wins; update plan inline.

**Worktree:** Continue on `worktree-bf-fork-spec`.

**Definition of Done (preview):** A `bf execute <wo>` invocation drives a fresh task WO from `new` → `done` end-to-end with real role-evaluator subagents writing artifacts; the Stage 5 demo trace records every node's handshake; Core contracts (`references/*.md`) updated to reflect any v0.3 schema changes; `MIGRATION.md` maps each retired v6 skill to its v1 equivalent; `package.json` bumped to `1.0.0-rc.1`; npm pack still clean. Test suite stays at ≥132/0/1.

---

## Scope split (Stage 5 vs Stage 6 vs deferred)

This plan combines two spec stages because they share the same demo loop: Stage 5 produces the demo, Stage 6 converts demo findings into doc + version artifacts.

**Stage 5 (the demo loop):**
1. **5.1** — SKILL.md → executable orchestrator (the agent dispatch layer Stage 4 deferred)
2. **5.2** — Real `brainstorm-task` demo: a fresh WO from `new` → `shaped` with real role evaluations
3. **5.3** — Real `close-leaf-task` demo: `doing` → `done` with real implement/code-review/verify agents
4. **5.4** — Stage 5 demo trace + Stage 6 input list

**Stage 6 (lift to contracts + migration):**
5. **6.1** — Revise Core contracts (`references/*.md`) per Stage 5 findings → v0.3
6. **6.2** — `MIGRATION.md` mapping v6 plugin (`plugins/blueprintflow/skills/*`) to v1 destinations per `bf-skill-migration.md`
7. **6.3** — Retire 3 v6 skills marked "Retire" in the migration table (bf-runtime-adapter + 2 teamlead-* skills)
8. **6.4** — Version bump `0.2.0-alpha` → `1.0.0-rc.1`; release notes; `npm pack --dry-run` stays clean

**Out of scope (true Stage 7+):**
- Remaining 14 v6 skills full content migration into Pack protocols (Stage 5 demo will name the next 2-3 highest-value migrations as candidates; the bulk migration is post-v1)
- LLM-driven NL transcription (Stage 4 retro item; nice-to-have, defers to v1.1)
- Sibling-Pack npm discovery (defers to v1.1+ when there's a real second Pack)
- Cron-driven verbs (sweep/intake) — explicitly post-v1 in spec
- `npm publish` for real (Stage 6 still does `--dry-run`; first real publish happens after a user — possibly the spec author — runs the demo on their own machine and signs off)

---

## File Structure Overview (delta vs Stage 4 end-state)

```
SKILL.md                          ← REWRITE: orchestrator instructions
                                    (currently descriptive; becomes
                                    executable steps for /bf invocations)

bin/lib/dispatcher/
└── node-runner.mjs               ← MODIFY: add a 'dryRun' / 'awaitAgents'
                                    mode so the orchestrator can intercept
                                    between "node ready" and "agents complete"

bin/lib/verbs/
└── execute.mjs                   ← MODIFY: emit "agents needed" event
                                    instead of auto-stub when running
                                    inside the SKILL.md orchestrator

references/
├── work-object.md                ← MODIFY (Stage 6.1): v0.3 schema
├── flow.md                       ← MODIFY (Stage 6.1)
├── gate.md                       ← MODIFY (Stage 6.1)
├── wo-home.md                    ← MODIFY (Stage 6.1)
├── pack.md                       ← MODIFY (Stage 6.1)
└── README.md                     ← MODIFY (Stage 6.1): bump version
                                    references; document Stage 5 outcomes

MIGRATION.md                      ← NEW (Stage 6.2): v6 → v1 migration

plugins/blueprintflow/skills/
├── bf-runtime-adapter/           ← DELETE (Stage 6.3): subsumed by bf-run
├── bf-teamlead-role-reminder/    ← DELETE (Stage 6.3): role lives in Pack
└── bf-teamlead-slow-cron-checkin/← DELETE (Stage 6.3): defer to v2 sweep verb

docs/specs/
├── 2026-05-18-stage-5-demo-trace.md ← NEW (Stage 5.4)
├── 2026-05-18-stage-6-core-v0.3.md  ← NEW (Stage 6.1) — change log
└── 2026-05-18-stage-5-6-retro.md    ← NEW (Stage 6 wrap)

package.json                      ← MODIFY (Stage 6.4): 1.0.0-rc.1
UPSTREAM.md                       ← APPEND: Stage 5/6 delta-log rows
README.md                         ← MODIFY (Stage 6.4): rc.1 status,
                                    "demo runs end-to-end with real
                                     subagents" callout
```

**Not touched in this plan:**
- 18 v6 skills marked "→ Brainstorm/Breakdown/Loop/Close protocol" in `bf-skill-migration.md` — their content already lives in `packs/product-engineering/reference-v6/`; Stage 5 demo identifies which 2-3 to migrate first (becomes Stage 7+).
- New Pack schemas (`phase.json`, `blueprint.json`) — Stage 5 demo runs at `task` level only; if a milestone-level demo is also needed, Stage 6 hint will flag it as Stage 7 work.
- Stage 4 dispatcher modules — they're frozen unless the demo surfaces a hard blocker.

---

## Stage 5+6 task layout

Eight tasks, each ending with a checkpoint commit; Stages 5 and 6 chained because Stage 6 inputs are 100% Stage 5 outputs.

1. **5.1 — SKILL.md orchestrator** (executable instructions; Agent-tool dispatch shape)
2. **5.2 — Real brainstorm demo** (real subagents for `discuss` + `write-criteria` nodes)
3. **5.3 — Real close-leaf demo** (real subagents for `implement` + `code-review` + `verify`)
4. **5.4 — Demo trace + Stage 6 input list**
5. **6.1 — Core contracts → v0.3** (incorporate Stage 5 findings)
6. **6.2 — MIGRATION.md**
7. **6.3 — Retire 3 v6 skills**
8. **6.4 — v1.0.0-rc.1 packaging + README**

---

## Task 5.1 — SKILL.md orchestrator

Today's `SKILL.md` describes BF. Stage 5 makes it an executable orchestrator: when the `/bf` slash invocation lands in Claude Code, the host LLM (you) reads SKILL.md and follows its dispatch loop — call `bf execute <wo>` to discover what node needs agents, spawn one Agent subagent per role, collect their `eval-<role>.md` outputs, write them into the run dir, then re-invoke `bf execute` to advance.

**Files:**
- Modify: `SKILL.md` (the rewrite — was descriptive, becomes a runbook)
- Modify: `bin/lib/dispatcher/node-runner.mjs` (add `--await-agents` mode that prints the "agents needed" envelope and exits cleanly instead of stub-emitting)
- Modify: `bin/lib/verbs/execute.mjs` (forward `--await-agents` to `node-runner`; honor an `BF_ORCHESTRATOR=skill` env that flips behavior)
- Create: `test/test-skill-orchestrator-shape.sh` (shape-only test: verifies the "agents needed" envelope schema; doesn't actually call Claude)

- [ ] **Step 1: Inspect current SKILL.md**

```bash
cat SKILL.md
```

Capture the frontmatter (name/version/description) — keep it; rewrite only the body.

- [ ] **Step 2: Plan node-runner extension**

Read `bin/lib/dispatcher/node-runner.mjs` (commit `610a261`). Today it emits stub evals and immediately seals. The new mode:

```javascript
// Before stub-emit, check if running under orchestrator:
if (process.env.BF_ORCHESTRATOR === "skill") {
  return {
    status: "agents-needed",
    nodeId,
    runDir: runPath,
    roles,                   // ["tester", "skeptic-owner"]
    nodeType,                // "review"
    woPath,                  // for context-passing to subagents
    expectedArtifacts: roles.map(r => `eval-${r}.md`),
  };
}
// Otherwise fall through to existing stub-emit path
```

The orchestrator (SKILL.md) reads this envelope, spawns N subagents (one per role), each writes its artifact, then the orchestrator re-invokes `execute --resume-node <id>` which seals + transitions.

- [ ] **Step 3: Write the failing test** at `test/test-skill-orchestrator-shape.sh`:

```bash
#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

# Create a leaf task at state 'doing' (skips the brainstorm step)
ID="orch-shape-test"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: doing
desired_state: done
pack: product-engineering
---

# orch shape test

## Objective
verify the orchestrator envelope shape.

## Boundary
shape-only — no real agents called.

## Acceptance criteria
- node-runner under BF_ORCHESTRATOR=skill returns agents-needed envelope
EOF

OUT=$(BF_ORCHESTRATOR=skill BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
echo "$OUT" | grep -q '"status":"agents-needed"' || { echo "FAIL: missing agents-needed envelope"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q '"roles":' || { echo "FAIL: missing roles list"; exit 1; }
echo "$OUT" | grep -q '"expectedArtifacts":' || { echo "FAIL: missing expectedArtifacts"; exit 1; }
echo "$OUT" | grep -q '"runDir":' || { echo "FAIL: missing runDir"; exit 1; }

echo "PASS: orchestrator envelope shape correct"
```

Make executable. Run — expect FAIL.

- [ ] **Step 4: Implement the `BF_ORCHESTRATOR=skill` path**

In `node-runner.mjs`, around the stub emission block:

```diff
   const roles = flow.roles?.[nodeId] ?? defaultRolesForType(nodeType);
+  if (process.env.BF_ORCHESTRATOR === "skill") {
+    return {
+      status: "agents-needed",
+      sealed: false,
+      nodeId,
+      runDir: runPath,
+      roles,
+      nodeType,
+      woPath: runDir,            // adjust if the variable name differs
+      flowFile,
+      expectedArtifacts: roles.map(r => `eval-${r}.md`),
+      next: { action: "spawn-agents-then-re-run-execute" },
+    };
+  }
   for (const role of roles) {
     await writeFile(path.join(runPath, `eval-${role}.md`), stubEvalFor(role, nodeId));
   }
```

In `bin/lib/verbs/execute.mjs`, if the inner `runOneFlow` returns `status: "agents-needed"`, propagate it upward as the verb's output (instead of trying to advance) and exit cleanly:

```diff
       const r = await runNode({ ... });
+      if (r.status === "agents-needed") {
+        console.log(JSON.stringify(r));
+        return;
+      }
       if (!r.sealed) return { error: r.error };
```

Confirm test PASS.

- [ ] **Step 5: Add a `--resume-node` flag**

The orchestrator, after writing artifacts, re-invokes execute. It needs a way to say "skip the agents-needed return, just seal and transition this node". Add `--resume-node <id>` (or `BF_RESUME_NODE=<id>` env). When present and the current node matches, `node-runner` skips the agents-needed branch AND the stub-emit branch — it just seals and transitions.

```diff
+  if (process.env.BF_RESUME_NODE === nodeId) {
+    // artifacts assumed already written by the orchestrator;
+    // skip both stub-emit and agents-needed branches
+  } else if (process.env.BF_ORCHESTRATOR === "skill") {
+    return { status: "agents-needed", ... };
+  } else {
+    // existing stub-emit
+  }
```

- [ ] **Step 6: Extend the test to cover `--resume-node`**

Append to `test/test-skill-orchestrator-shape.sh`:

```bash
# Simulate orchestrator: write the expected artifacts, then re-invoke
RUN_DIR=$(echo "$OUT" | grep -o '"runDir":"[^"]*"' | head -1 | sed 's/.*"runDir":"\([^"]*\)"/\1/')
for r in $(echo "$OUT" | grep -o '"eval-[^"]*"' | tr -d '"'); do
  cat > "$RUN_DIR/$r" <<EOF
---
role: $(echo "$r" | sed 's/eval-//;s/.md//')
verdict: PASS
---
synthetic resume test
EOF
done

OUT2=$(BF_ORCHESTRATOR=skill BF_RESUME_NODE=implement BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
# After resume-node, the run should advance past implement
echo "$OUT2" | grep -q '"status":"agents-needed"\|"finalized":true' || { echo "FAIL: resume did not advance"; echo "$OUT2"; exit 1; }
echo "PASS: --resume-node advances correctly"
```

Run test — should PASS the original assertion AND the resume assertion.

- [ ] **Step 7: Rewrite SKILL.md body**

Replace the descriptive body with executable orchestrator instructions. Keep the frontmatter (name/version/description) intact. New body shape:

```markdown
# bf — Blueprintflow orchestrator

You are the BF orchestrator. When invoked via `/bf <input>`, your job
is to drive Work Objects through Pack flows by alternating between
`bf` CLI calls (which manipulate state on disk) and Agent subagent
dispatches (which produce the artifacts the CLI verifies).

## Dispatch loop

1. **Parse input**: if first token is a known BF verb, run that verb
   directly (see `bf help` or `references/README.md` for the catalog).
   Otherwise, transcribe natural language to a verb form:
   - Default verb: `execute`
   - If the input names an action ("create X", "show Y", "discard Z"),
     map it to the matching verb.
   - Print the transcription before executing: `[bf] transcribed: bf <verb> <args>`

2. **Run the verb** under `BF_ORCHESTRATOR=skill`:
   ```bash
   BF_ORCHESTRATOR=skill node bin/bf.mjs <verb> <args>
   ```

3. **Read the JSON envelope** on stdout. Three cases:

   **a. `{status: "agents-needed", roles, runDir, expectedArtifacts, nodeType, flowFile, ...}`**
   This node needs human-or-LLM work before sealing. Take these steps:

   - For each `role` in `roles`:
     - Read the role's prompt: `cat roles/<role>.md` if the role is Core,
       else `cat packs/<pack>/roles/<role>.md`.
     - Read the node's protocol: `cat packs/<pack>/protocols/<flow-id>.md`
       and locate the section for the current `nodeId`.
     - Read the WO: `cat <runDir>/../../../wo.md` (relative path back to the WO's wo.md).
     - Spawn one Agent subagent (model: sonnet for review/build nodes;
       haiku for mechanical execute nodes), prompt structured as:
       ```
       You are the <role> for this product-engineering work object.

       <role prompt from roles/<role>.md>

       Work object context:
       <wo.md content>

       Node protocol (current node: <nodeId>):
       <relevant section of protocols/<flow>.md>

       Output: write your evaluation to <runDir>/eval-<role>.md
       Format: YAML frontmatter (role, verdict ∈ {PASS, FAIL, ITERATE}),
       then a markdown body explaining the verdict against the WO's
       acceptance criteria.
       ```
     - Wait for the subagent to write the file.
   - When all roles' artifacts exist, re-invoke:
     ```bash
     BF_ORCHESTRATOR=skill BF_RESUME_NODE=<nodeId> node bin/bf.mjs <verb> <args>
     ```
   - Loop back to step 3.

   **b. `{finalized: true, terminalNode, newState, ...}`**
   The flow completed. The WO's `current_state` has been updated.
   Re-invoke `bf execute <wo>` to drive the next core-type flow (or
   exit if `current_state == desired_state`).

   **c. `{error: ..., ...}` / `{stuck: true, ...}` / `{deferred: ...}`**
   Print to the user and exit. Don't loop.

4. **Stop conditions**:
   - WO reaches `desired_state`.
   - Three consecutive `{error}` envelopes (likely an unfixable contract gap).
   - `{deferred: true}` returned (e.g. `loop` core_type pending child-run primitive).

## Reference

- Verb catalog: `bf help` or `docs/specs/2026-05-16-bf-fork-design/bf-run-commands.md`
- Core contracts: `references/{work-object,flow,gate,wo-home,pack}.md`
- Active Pack: `packs/product-engineering/{pack.json,flows/,protocols/,roles/,schemas/}`
- Stage 4 retro (known limitations): `docs/specs/2026-05-17-stage-4-retro.md`
```

- [ ] **Step 8: Run full suite** — expect 132 baseline + 1 new = 133 passed.

```bash
bash test/run-all.sh 2>&1 | tail -3
```

- [ ] **Step 9: Commit.**

```bash
git add SKILL.md bin/lib/dispatcher/node-runner.mjs bin/lib/verbs/execute.mjs test/test-skill-orchestrator-shape.sh
git commit -m "$(cat <<'EOF'
feat(bf): SKILL.md orchestrator + node-runner agents-needed envelope

Stage 5 task 5.1. Replaces SKILL.md's descriptive body with executable
dispatch-loop instructions for the host LLM. When BF_ORCHESTRATOR=skill,
node-runner returns an {agents-needed, roles, runDir, expectedArtifacts}
envelope instead of stub-emitting eval files; the orchestrator spawns
one Agent subagent per role, each writes its eval-<role>.md, then
re-invokes execute with BF_RESUME_NODE=<id> to seal and transition.

Closes Stage 4 retro item #1 (stub role-evaluator inside node-runner).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.2 — Real brainstorm-task demo

Run the real demo for a fresh task WO going from `new` → `shaped` via the brainstorm flow, with real role-evaluator subagents producing artifacts.

Unlike Stage 3's manual demo, this one drives via the orchestrator (`/bf` skill context) — but since we're already inside Claude Code, we can do the dispatch loop manually here as we execute the plan: the executing agent IS the orchestrator.

**Files (this task is mostly process; outputs are commit-able artifacts):**
- Create: `docs/specs/2026-05-18-stage-5-demo/brainstorm-run.md` (the trace doc)
- Create (transient): a real WO under `~/.bf/wo/stage-5-demo-task-1/` — this WO directory is captured in the trace doc but the live `~/.bf/wo/` is NOT committed (it's user state, lives in the user's home).

- [ ] **Step 1: Pick the demo task**

Use a small real task with one clear deliverable. Suggested: "Add a `bf version` verb that prints package version" (small, leaf, real artifact). Alternative: pick from anything in `docs/tasks/` if a tracked task exists.

Document the chosen task in `docs/specs/2026-05-18-stage-5-demo/brainstorm-run.md` § "Demo task".

- [ ] **Step 2: Create the WO**

```bash
node bin/bf.mjs create "Add bf version verb that prints package.json version" --pack product-engineering --schema task
```

Note the assigned WO id (slugified description). Capture the create envelope output into the trace doc.

- [ ] **Step 3: Drive brainstorm with real agents**

Run the orchestrator loop manually (since we're inside Claude Code, the orchestrator-loop steps from SKILL.md become this section's substeps):

```bash
BF_ORCHESTRATOR=skill node bin/bf.mjs execute <wo-id>
```

Read the returned envelope. It will say `{status: "agents-needed", nodeId: "discuss", roles: [<defaults for discussion>], ...}`.

For each role in the envelope:
- Read its role file: `cat roles/<role>.md`
- Read the brainstorm protocol: `cat packs/product-engineering/protocols/brainstorm-task.md`
- Read the WO: `cat ~/.bf/wo/<wo-id>/wo.md`
- Spawn one Agent subagent (via the Agent tool, `general-purpose` subagent_type, model `sonnet`) with the prompt template from SKILL.md § 3a.
- Subagent writes `<runDir>/eval-<role>.md`.

After all roles' artifacts exist, re-invoke:

```bash
BF_ORCHESTRATOR=skill BF_RESUME_NODE=discuss node bin/bf.mjs execute <wo-id>
```

This should advance to `write-criteria` and re-emit `agents-needed`. Repeat the agent-spawn for `write-criteria`, then `criteria-lint`, then the final gate.

When the flow finalizes, the envelope will show `{finalized: true, newState: "shaped"}`. The WO's `current_state` should now be `shaped` and acceptance criteria should be a real list in the wo.md body.

- [ ] **Step 4: Capture the trace**

In `docs/specs/2026-05-18-stage-5-demo/brainstorm-run.md`, for each node visited:

```markdown
### Node: <id> (type: <type>)

**Roles dispatched**: <role1>, <role2>, ...

**Artifacts produced**:
- `eval-<role1>.md` — verdict <V> — <one-line summary>
- ...

**Errors / surprises**:
- [list anything that didn't match expectations]

**Seal output**: `{sealed: true, ...}`

**Transition**: `<from-node> → <to-node>` (verdict <V>)
```

End with the final shaped WO's content snippet (the now-populated acceptance criteria).

- [ ] **Step 5: Note Stage 6 inputs**

Anywhere the demo surfaced a contract issue (e.g. a role's expected output didn't match the protocol's "Outputs" section, or `criteria-lint` rejected what felt like valid criteria), add a `## Findings` bullet at the bottom of the trace. These become Stage 6.1 inputs.

- [ ] **Step 6: Don't commit `~/.bf/wo/<id>/`** — that's user state. The trace document is what survives.

```bash
git add docs/specs/2026-05-18-stage-5-demo/brainstorm-run.md
git commit -m "$(cat <<'EOF'
docs(spec): Stage 5.2 brainstorm-task real-agent demo trace

Drives a real task WO new → shaped via the brainstorm-task flow with
real role-evaluator subagents (sonnet) writing acceptance criteria.
Captures per-node handshakes, surprises, and Stage 6 input bullets.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.3 — Real close-leaf-task demo

After 5.2 produced a shaped task, drive it through `close-leaf-task` end-to-end. This flow has 4 nodes: `implement` (build) → `code-review` (review) → `verify` (execute) → `gate`. Each node spawns real subagents.

This is the hardest test of the orchestrator: the `implement` node produces actual code changes (the subagent writes/edits files in the repo); `code-review` reviews those changes against the WO's acceptance criteria; `verify` runs the test suite.

**Files:**
- Create: `docs/specs/2026-05-18-stage-5-demo/close-leaf-run.md` (the trace)
- Possibly: actual code changes produced by the `implement` subagent (e.g. the new `bf version` verb if that was the demo task) — these get committed as their own commit.

- [ ] **Step 1: Flip the WO to `doing`**

The brainstorm-task flow produced `shaped`. The Stage 4 routing has no `task,shaped` rule (it routes `task,new → brainstorm-task` and `task,doing → close-leaf-task`); v0.2 documented this gap and accepts manual transition for leaf tasks:

```bash
sed -i 's/current_state: shaped/current_state: doing/' ~/.bf/wo/<wo-id>/wo.md
```

(Stage 6.1 may add a `task,shaped → close-leaf-task` routing rule based on this demo's findings.)

- [ ] **Step 2: Run close-leaf-task with real agents**

```bash
BF_ORCHESTRATOR=skill node bin/bf.mjs execute <wo-id>
```

The first envelope: `{status: "agents-needed", nodeId: "implement", roles: ["engineer"], nodeType: "build", ...}`.

For the `implement` node specifically: the subagent must actually produce code changes. Its prompt includes the WO's acceptance criteria; it edits files in the worktree, then writes its `eval-engineer.md` with `verdict: PASS` if the changes meet the criteria.

For `code-review`: spawn multiple subagents (engineer + architect + security + skeptic-owner per `close-leaf-task.md` protocol). Each independently reviews the diff (`git diff HEAD`) and the test suite output, writes its eval.

For `verify`: a tester subagent runs the test suite (`bash test/run-all.sh`), captures pass/fail in its eval + a `cli-output.log`.

For `gate`: synthesize verdict (per the BF gate protocol) — no role dispatch needed; verdict comes from prior nodes' evals.

- [ ] **Step 3: Capture the trace**

In `docs/specs/2026-05-18-stage-5-demo/close-leaf-run.md`, same per-node table format as 5.2.

Particular things to record:
- For `implement`: what files the subagent created/modified; what tests it added.
- For `code-review`: each role's verdict; any inter-role disagreement; the gate-protocol synthesis.
- For `verify`: the test count before/after; any new failures.
- For `gate`: the final verdict and which evidence drove it.

End with the final WO state (`current_state: done`) and the resulting code commit SHA.

- [ ] **Step 4: Commit the code changes separately**

If `implement` produced real code changes, that goes in its own commit (probably authored by the implement subagent during its run — instruct it to commit before sealing). The trace commit references that SHA.

- [ ] **Step 5: Commit the trace**

```bash
git add docs/specs/2026-05-18-stage-5-demo/close-leaf-run.md
git commit -m "$(cat <<'EOF'
docs(spec): Stage 5.3 close-leaf-task real-agent demo trace

Drives the shaped task WO doing → done via close-leaf-task with real
subagents at implement/code-review/verify/gate. Captures per-node
artifact production, inter-role review verdicts, and the final gate
synthesis. References the code-change commit produced by the
implement subagent.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5.4 — Stage 5 demo trace + Stage 6 input list

Consolidate 5.2 and 5.3 into a single top-level trace + extract every "this is broken / unclear / surprised me" finding into a Stage 6 input list.

**Files:**
- Create: `docs/specs/2026-05-18-stage-5-demo-trace.md` (the top-level summary; links to 5.2 + 5.3 sub-traces)

- [ ] **Step 1: Author the top-level trace**

Structure:

```markdown
# Stage 5 Demo — End-to-End Real-Agent Run

## Demo task

<the task chosen in 5.2>

## Pipeline

new ─brainstorm─→ shaped ─[manual flip]─→ doing ─close─→ done

## Per-stage outcomes

### Stage 5.2 — brainstorm-task
See [brainstorm-run.md](./2026-05-18-stage-5-demo/brainstorm-run.md).
Headline: <e.g. "produced 3 acceptance criteria after 1 ITERATE loop">

### Stage 5.3 — close-leaf-task
See [close-leaf-run.md](./2026-05-18-stage-5-demo/close-leaf-run.md).
Headline: <e.g. "real code shipped at commit <sha>; verify passed 133/0/1">

## Stage 6 input list (lifted from per-stage Findings sections)

Each item: what was surprising / broken / underspecified, and which
Core contract or Pack file it affects.

1. **[issue title]** — [description]
   - Affects: `references/<contract>.md` § ... | `packs/.../protocols/<file>.md` | both
   - Severity: blocker | clarification | nice-to-have
2. ...

## Demo verdict

End-to-end runnable: yes / no / partial.
If partial: what blocks "yes"?
```

- [ ] **Step 2: Cross-link from the Stage 4 retro**

In `docs/specs/2026-05-17-stage-4-retro.md`, append a line under the "Stage 5 demo target" section:

```markdown
**Stage 5 demo outcome:** see `docs/specs/2026-05-18-stage-5-demo-trace.md`.
```

- [ ] **Step 3: Update UPSTREAM.md**

Append a Stage 5 wrap-up delta-log row summarizing the 5.1 / 5.2 / 5.3 / 5.4 commits.

- [ ] **Step 4: Run full suite + verify nothing broke**

```bash
bash test/run-all.sh 2>&1 | tail -3
```

Expected: ≥133 passed (132 baseline + 1 from 5.1 shape test + any tests added by `implement` subagent in 5.3).

- [ ] **Step 5: Commit**

```bash
git add docs/specs/2026-05-18-stage-5-demo-trace.md docs/specs/2026-05-17-stage-4-retro.md UPSTREAM.md
git commit -m "$(cat <<'EOF'
docs(spec): Stage 5 demo summary + Stage 6 input list

Consolidates the brainstorm and close-leaf real-agent traces into a
top-level Stage 5 outcome doc, extracts a numbered Stage 6 input list
(each tied to a Core contract or Pack file), and cross-links from the
Stage 4 retro. UPSTREAM.md gets a Stage 5 wrap-up row.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6.1 — Core contracts → v0.3

Lift Stage 5 demo findings into the 5 Core contract files. Each contract file may need 0+ updates depending on what surfaced.

**Files:**
- Modify: `references/{work-object,flow,gate,wo-home,pack}.md` (zero or more, depending on findings)
- Modify: `references/README.md` (bump version reference)
- Create: `docs/specs/2026-05-18-stage-6-core-v0.3.md` (change log — what changed and why, with traceback to demo finding)

- [ ] **Step 1: Read the Stage 6 input list**

From `docs/specs/2026-05-18-stage-5-demo-trace.md` § "Stage 6 input list".

- [ ] **Step 2: Group findings by contract**

For each finding, decide:
- Which `references/<contract>.md` it belongs to
- What kind of change: new field, removed field, behavioral clarification, "Open" → resolved, etc.
- Whether it's a breaking change (would invalidate existing Pack schemas)

If a finding clearly only affects a Pack-level file (e.g. a protocol's "Outputs" section was wrong), apply the fix in the Pack file in 6.2 instead.

- [ ] **Step 3: Apply changes per contract**

For each affected file:
- Update the relevant section.
- Move any newly-resolved item from `## Open` to the main body.
- Add new `## Open` items if the demo surfaced gaps you didn't fix in this stage.
- Bump the "Version" line at the top of the file from `v0.2` → `v0.3`.

If a contract had no findings: no change needed; explicitly note in the change log "no changes — Stage 5 didn't exercise this contract beyond v0.2".

- [ ] **Step 4: Update `references/README.md`**

Bump version references; add a short "v0.3 changes" section linking to the change log.

- [ ] **Step 5: Author the change log**

`docs/specs/2026-05-18-stage-6-core-v0.3.md`:

```markdown
# Core Contracts v0.3 — Change Log

> Lifted from Stage 5 demo findings
> (`docs/specs/2026-05-18-stage-5-demo-trace.md` § "Stage 6 input list").
> Companion to `references/*.md` v0.3.

## Summary

- N findings from Stage 5 → M contract updates across K files
- X breaking changes / Y additive changes / Z behavioral clarifications

## Per-finding traceback

### Finding 1: <title>
- Source: Stage 5 input list item N
- Contract affected: `references/<file>.md`
- Change: <what>
- Reason: <why; cites demo trace section>
- Breaking? <yes/no; if yes, how Packs migrate>

### Finding 2: ...

## Contracts NOT updated

- `references/<file>.md` — Stage 5 didn't exercise; remains at v0.2 behavior, now versioned v0.3 only for consistency.
```

- [ ] **Step 6: Run full suite** (the contracts are docs — no test impact expected; verify anyway).

```bash
bash test/run-all.sh 2>&1 | tail -3
```

- [ ] **Step 7: Commit**

```bash
git add references/ docs/specs/2026-05-18-stage-6-core-v0.3.md
git commit -m "$(cat <<'EOF'
docs(spec): Core contracts v0.3 — Stage 5 demo findings

Updates references/*.md from v0.2 to v0.3 based on Stage 5 demo
findings. Each change is traced in the change log to a specific
demo input. Contracts not exercised by Stage 5 remain v0.2 in
behavior; the version bump is for consistency.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6.2 — MIGRATION.md

Document how a v6 plugin user moves to v1 BF. Use `docs/specs/2026-05-16-bf-fork-design/bf-skill-migration.md` (the per-skill mapping table) as the source. The migration table is already authored; this task surfaces it as a top-level user-facing doc.

**Files:**
- Create: `MIGRATION.md` (top-level)
- Modify: `README.md` (link to MIGRATION.md from the install section)

- [ ] **Step 1: Author MIGRATION.md**

```markdown
# Migrating from v6 plugin to v1 BF

If you used the `blueprintflow` plugin (v6.x) in Claude Code, this is
the path forward.

## TL;DR

- v6 plugin (`plugins/blueprintflow/`) still works side-by-side with
  v1. You can uninstall it when you're confident in v1's behavior.
- v1 BF is an npm package: `npm install -g @codetreker/bf`.
- The 21 v6 skills become either Pack content (protocols, schemas,
  roles) under `packs/product-engineering/` or are retired.

## Skill-by-skill mapping

(Lifted from `docs/specs/2026-05-16-bf-fork-design/bf-skill-migration.md`.)

| v6 skill | v1 destination | Status |
|---|---|---|
| `bf-brainstorm` | brainstorm-blueprint protocol | Pack content; migrated 2026-MM-DD |
| `bf-blueprint-write` | write-blueprint protocol | Pack content; migrated 2026-MM-DD |
| ... | ... | ... |
| `bf-runtime-adapter` | Retired | Subsumed by `bf` runtime |
| `bf-teamlead-role-reminder` | Retired | Role lives in Pack `roles/` |
| `bf-teamlead-slow-cron-checkin` | Retired (re-enter v2) | `sweep` Core verb deferred |
| `using-plueprint` | `packs/product-engineering/skills/using-bf/` | Renamed |

(For Stage 5 release: only the 4 probe protocols + the 3 retirements
are concretely landed; the other 14 skills migrate in v1.x. Pack
content paths exist as `reference-v6/` until promoted.)

## Backwards-compatibility

- The v6 plugin remains marketplace-installable; v1 lives on npm.
- WO directory layout is new in v1 (`~/.bf/wo/<id>/wo.md`); v6 didn't
  have a persistent WO home.
- State name changes: v6 used `reviewed_task_ready` and other long
  names; v1 canonical states are `new / shaped / broken_down / doing /
  children_done / done`. The product-engineering Pack's `pack.json`
  carries `state_aliases` mapping v6 names to v1 canonical so existing
  workflows still resolve.

## When to switch

- You're starting a fresh project: use v1.
- You're mid-project on v6: finish the project on v6, then switch.
- You want both: install both; they don't conflict (different command
  prefixes: v6 uses no global verb, v1 uses `/bf`).

## Retiring the v6 plugin

When v1 has carried you through a full project end-to-end:

```bash
# Remove v6 from your marketplace
# (specific command depends on how you installed it)

# Confirm v1 is your sole Blueprintflow:
which bf            # → /path/to/global/node_modules/.bin/bf
bf pack list        # → product-engineering
```

## Stage 5 demo proof

The Stage 5 demo trace
(`docs/specs/2026-05-18-stage-5-demo-trace.md`) records a real task
driven end-to-end through v1 BF — a concrete confidence anchor for
the switch.
```

- [ ] **Step 2: Link from README**

In `README.md`, after the install section, add:

```markdown
**Coming from v6 plugin?** See [MIGRATION.md](./MIGRATION.md).
```

- [ ] **Step 3: Commit**

```bash
git add MIGRATION.md README.md
git commit -m "$(cat <<'EOF'
docs(bf): MIGRATION.md (v6 plugin → v1) + README link

Stage 6 task 6.2. Top-level user-facing migration doc lifted from
bf-skill-migration.md. README points to it from the install section.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6.3 — Retire 3 v6 skills

Per `bf-skill-migration.md`, three skills are flagged "Retire":
- `bf-runtime-adapter` — subsumed by `bf-run` + runtime
- `bf-teamlead-role-reminder` — Teamlead behavior moves to role file + execute orchestration
- `bf-teamlead-slow-cron-checkin` — Cron deferred to v2 `sweep` Core verb

**Files:**
- Delete: `plugins/blueprintflow/skills/bf-runtime-adapter/`
- Delete: `plugins/blueprintflow/skills/bf-teamlead-role-reminder/`
- Delete: `plugins/blueprintflow/skills/bf-teamlead-slow-cron-checkin/`
- Verify: `packs/product-engineering/reference-v6/<same 3 dirs>/` already contains the copies from Stage 3.2 — those are the historical record.

- [ ] **Step 1: Verify reference-v6 copies exist**

```bash
ls packs/product-engineering/reference-v6/bf-runtime-adapter/
ls packs/product-engineering/reference-v6/bf-teamlead-role-reminder/
ls packs/product-engineering/reference-v6/bf-teamlead-slow-cron-checkin/
```

Each must contain at least `SKILL.md`. If any is missing, do NOT delete; surface the gap (a Stage 3.2 leak).

- [ ] **Step 2: Inspect each retiring skill briefly**

```bash
for s in bf-runtime-adapter bf-teamlead-role-reminder bf-teamlead-slow-cron-checkin; do
  echo "=== $s ==="
  head -30 plugins/blueprintflow/skills/$s/SKILL.md
  echo
done
```

If any file in those dirs looks like content that should have been migrated to a Pack protocol but wasn't, flag it before deleting. The 3 retirements are pre-decided in the spec, so this is just a paranoia check.

- [ ] **Step 3: Delete**

```bash
git rm -r plugins/blueprintflow/skills/bf-runtime-adapter
git rm -r plugins/blueprintflow/skills/bf-teamlead-role-reminder
git rm -r plugins/blueprintflow/skills/bf-teamlead-slow-cron-checkin
```

- [ ] **Step 4: Update plugin metadata**

If `plugins/blueprintflow/marketplace.json` (or equivalent) lists skills, remove the 3 retired entries.

```bash
grep -n "bf-runtime-adapter\|bf-teamlead" plugins/blueprintflow/marketplace.json plugins/blueprintflow/.claude-plugin/plugin.json 2>/dev/null
```

Edit any matches accordingly.

- [ ] **Step 5: Run full suite**

```bash
bash test/run-all.sh 2>&1 | tail -3
```

Expected: still green. No test should reference the deleted skills (they were never wired into bf-harness or tests).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore(bf): retire 3 v6 skills (subsumed by v1)

Stage 6 task 6.3. Removes per bf-skill-migration.md:
- bf-runtime-adapter (subsumed by bf-run + runtime)
- bf-teamlead-role-reminder (role lives in Pack roles/; orchestration
  in /bf skill)
- bf-teamlead-slow-cron-checkin (cron deferred to v2 sweep verb)

Historical record preserved under
packs/product-engineering/reference-v6/<same 3 dirs>/ from Stage 3.2.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6.4 — v1.0.0-rc.1 packaging + README

Bump the version, refresh README to reflect rc.1 status (demo runs end-to-end with real subagents), verify packaging clean.

**Files:**
- Modify: `package.json` (version `0.2.0-alpha` → `1.0.0-rc.1`)
- Modify: `README.md` (rc.1 status block; remove "stub agents" warning since 5.1 fixed it; keep "loop verb deferred" and "no npm publish yet")
- Verify: `test/test-package-dryrun.sh` still passes
- Append: `UPSTREAM.md` Stage 6 wrap-up row
- Create: `docs/specs/2026-05-18-stage-5-6-retro.md` (final retro for the v1 push)

- [ ] **Step 1: Version bump**

```diff
   "name": "@codetreker/bf",
-  "version": "0.2.0-alpha",
+  "version": "1.0.0-rc.1",
```

- [ ] **Step 2: README rc.1 status update**

In `README.md` § "Status (Stage 4 v0.2)" (or whatever the current section is called), rewrite to:

```markdown
### Status (v1.0.0-rc.1)

- ✅ verb-first dispatch (all 18 verbs)
- ✅ harness mechanics hardened (Stage 4.2)
- ✅ Pack-supplied flow loading
- ✅ SKILL.md orchestrator drives real subagent dispatch (Stage 5.1)
- ✅ end-to-end demo passed: see `docs/specs/2026-05-18-stage-5-demo-trace.md`
- ✅ `npm pack --dry-run` clean
- ⚠️ `loop` verb still defers — child-WO dispatch is post-v1 (`docs/specs/.../core-contracts.md` Flow.Open)
- ⚠️ NL transcription via Claude Code skill only; standalone CLI requires verb-first
- ⏳ first real `npm publish` after the spec author runs the demo on their own machine and signs off
```

- [ ] **Step 3: Run the package-dryrun test**

```bash
bash test/test-package-dryrun.sh
```

Expected: PASS. The version bump doesn't change the file list; the assertion checks content paths.

- [ ] **Step 4: Run full suite + regression**

```bash
bash test/run-all.sh 2>&1 | tail -3
bash test/test-stage4-regression.sh
```

- [ ] **Step 5: UPSTREAM wrap-up + final retro**

Append one row to UPSTREAM.md summarizing Stage 6.

Author `docs/specs/2026-05-18-stage-5-6-retro.md`:

```markdown
# Stage 5+6 Retrospective

> v1.0.0-rc.1 — Blueprintflow's first version that runs end-to-end
> with real subagents. Companion to the combined Stage 5+6 plan.

## What landed

- SKILL.md orchestrator (commit ...) drives real subagent dispatch
- Stage 5 demo traces (commits ...) record per-node handshakes
- Core contracts → v0.3 (commit ...) lifts demo findings
- MIGRATION.md (commit ...) — v6 → v1 path
- 3 v6 skills retired (commit ...)
- Version bump to 1.0.0-rc.1 (commit ...)

## What's still deferred (post-v1)

[list — same scope as the plan's "Out of scope" section, augmented
with anything Stage 5+6 discovered that we punted on]

## How to actually try it

```bash
git clone <this repo>
cd blueprintflow
# (optional) npm install -g .  for global install
node bin/bf.mjs create "your first task" --pack product-engineering
node bin/bf.mjs execute <wo-id>
# follow the agents-needed envelope per SKILL.md
```

## Test result

`bash test/run-all.sh` → <final count>
`bash test/test-stage4-regression.sh` → PASS
```

- [ ] **Step 6: Commit everything**

```bash
git add package.json README.md UPSTREAM.md docs/specs/2026-05-18-stage-5-6-retro.md
git commit -m "$(cat <<'EOF'
chore(bf): v1.0.0-rc.1 — first end-to-end real-agent release candidate

Stage 6 task 6.4. Bumps from 0.2.0-alpha to 1.0.0-rc.1. README reflects
v1 status: orchestrator drives real subagents; demo passed end-to-end;
remaining deferrals (loop child-runs, real npm publish) are post-v1.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Stage 5+6 Definition of Done

- [ ] **Real-agent demo passes**: a fresh WO drives `new → shaped → doing → done` via the SKILL.md orchestrator, with real subagents producing every artifact. Trace docs under `docs/specs/2026-05-18-stage-5-demo/`.
- [ ] **`BF_ORCHESTRATOR=skill` returns agents-needed envelopes** instead of stub-emitting. `test/test-skill-orchestrator-shape.sh` PASS.
- [ ] **Core contracts at v0.3**: `references/*.md` updated per demo findings, with a per-finding traceback in the change log.
- [ ] **`MIGRATION.md` exists** and is linked from README.
- [ ] **3 v6 skills retired**, historical copies preserved under `reference-v6/`.
- [ ] **`package.json` at 1.0.0-rc.1**; `test/test-package-dryrun.sh` PASS.
- [ ] **Test suite stable**: `bash test/run-all.sh` → ≥133 passed; `bash test/test-stage4-regression.sh` PASS.
- [ ] **README reflects rc.1 status**: claims "real subagents" only because the demo actually passed.
- [ ] **Stage 5+6 retro doc shipped**.
- [ ] **UPSTREAM.md delta-log rows written** for Stage 5 wrap and Stage 6 wrap.

## Self-Review Notes (for plan author)

- [ ] Every Stage 5 item has a concrete output (trace, commit, or both).
- [ ] Stage 6.1 doesn't pretend to enumerate findings in advance — its structure is "lift Stage 5 findings into contracts", with the demo determining what those findings are.
- [ ] No "TODO / TBD / fill in" — Stage 5 has placeholder file names like "the chosen task" that get filled in during execution; the plan is explicit about when that's expected.
- [ ] Type / behavior consistency:
  - `BF_ORCHESTRATOR=skill` flag name used consistently
  - `BF_RESUME_NODE=<id>` flag name used consistently
  - `{status: "agents-needed", roles, runDir, expectedArtifacts, nodeType, flowFile, woPath}` envelope shape consistent across SKILL.md, node-runner, and the shape test
- [ ] Brand: every new file uses `bf` / `~/.bf/` / `BF_*`.

## Out of Scope (truly deferred to v1.x / v2)

Reproduced from §"Out of scope" at top of plan for emphasis:

1. **14 of 21 v6 skills' full content migration into Pack protocols** — bulk migration is post-v1. Stage 5 demo names the next 2-3 candidates.
2. **LLM-driven NL transcription** in CLI mode — works in skill context; standalone CLI requires verb-first. v1.1.
3. **Sibling-Pack npm discovery** — `pack-discovery` scans repo-local only. v1.1+.
4. **Cron-driven verbs** (`sweep`, `intake`) — explicitly post-v1 in spec.
5. **Real `npm publish`** — Stage 6 stops at `--dry-run`. First publish is owner-driven, post-this-plan.
6. **Child-run dispatch for `loop`** — Stage 4 retro item #2; needs a real "node spawns child runs" primitive that's larger than v1 should swallow. v1.x.
7. **Per-WO live-state file** — Stage 4 retro item #3; same scope as child-run dispatch. v1.x.
8. **Structured edge payloads `{verdict, scope}`** — Stage 4 retro item #4; same scope. v1.x.
9. **Multi-line YAML in `wo.md`** — Stage 4 retro item #7; needs a YAML library swap. v1.0.1 patch.
10. **`bf resume --last` ergonomics** — Stage 4 retro item #6. v1.0.1.
