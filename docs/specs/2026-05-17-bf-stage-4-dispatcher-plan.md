# BF Stage 4 — Live `bf-run` Dispatcher + NPM Dry-Run Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement task-by-task. Steps use `- [ ]` checkboxes.

**Goal:** Replace the `bin/bf.mjs` placeholder with a real dispatcher that routes a user request (verb-first or natural-language) through Pack discovery → flow selection → `bf-harness` execution, while landing the dispatcher-level hardening that Stage 3's demo flagged as must-do before any real WO can be driven through `execute`.

**Architecture:** `bin/bf.mjs` becomes a thin arg parser that delegates to one module per verb in `bin/lib/verbs/`. Pack discovery scans `packs/*/pack.json` (in-repo) and resolves WO routing through `pack.json.routing` keyed by `<schema>,<state>`. The dispatcher owns the lifecycle around each harness node invocation (mkdir `run_N/`, surface `validationErrors` as hard failures, walk PASS/ITERATE/FAIL edges) so node protocols can stay declarative. A separate NL front-end (`bin/lib/nl-parse.mjs`) transcribes free-form input to a verb form, prints the transcription, then re-enters the verb-first path. No new harness primitives are introduced for child-WO dispatch (that's Stage 5+); v0.2 dispatches one WO at a time and exits at the first `loop` core_type it hits, leaving a clear "drive each child manually" message.

**Tech Stack:** Same as Stage 1–3 — Node 18+, ESM modules, Bash, file-based state. No new runtime deps (the NL parser shells out to Claude Code's built-in LLM via the surrounding skill context; the dispatcher itself does not import any LLM SDK).

**Source of truth:** `docs/specs/2026-05-16-bf-fork-design.md` § Stage 4, `docs/specs/2026-05-16-bf-fork-design/bf-run-commands.md` (verb catalog), `docs/specs/2026-05-16-bf-fork-design/core-contracts.md` (esp. § Open sections), and `docs/specs/2026-05-17-stage-3-demo-trace.md` § "Stage 4 must-do list" (17-item punch list — this plan addresses 14 of them; the remaining 3 are explicitly deferred per §"Out of Scope"). When the plan and spec disagree, spec wins; update plan inline.

**Worktree:** Continue on `worktree-bf-fork-spec` — same branch carrying Stage 1–3.

**Definition of Done (preview — full version at end):** `bin/bf execute <wo-id>` drives a `task` WO from `new → shaped → doing → done` end-to-end against the product-engineering Pack using real handshakes (not manual seal). Test suite stays at 108/0/1. `npm publish --dry-run` produces a clean tarball with the expected file list. `grep -rn '/opc ' bin/lib/` returns empty.

---

## File Structure Overview (delta vs Stage 3 end-state)

```
bin/
├── bf.mjs                        ← REWRITE: thin arg parser + verb dispatch
├── bf-harness.mjs                ← MODIFY: harden per Stage 3 findings (Task 4.2)
└── lib/
    ├── verbs/                    ← NEW DIRECTORY: one file per verb
    │   ├── create.mjs            ← Task 4.4
    │   ├── execute.mjs           ← Task 4.4 (orchestrator across all 4 core_types)
    │   ├── brainstorm.mjs        ← Task 4.4 (single core_type run)
    │   ├── breakdown.mjs         ← Task 4.4
    │   ├── loop.mjs              ← Task 4.4 (returns early in v0.2 — see Out-of-Scope)
    │   ├── close.mjs             ← Task 4.4
    │   ├── show.mjs              ← Task 4.5
    │   ├── tree.mjs              ← Task 4.5
    │   ├── list.mjs              ← Task 4.5
    │   ├── discard.mjs           ← Task 4.5
    │   ├── escape.mjs            ← Task 4.5 (skip / pass / stop / goto / resume)
    │   ├── pack.mjs              ← Task 4.5 (list / info)
    │   ├── flow.mjs              ← Task 4.5 (list / viz)
    │   └── help.mjs              ← Task 4.5
    ├── dispatcher/
    │   ├── arg-parser.mjs        ← Task 4.3
    │   ├── pack-discovery.mjs    ← Task 4.3
    │   ├── wo-resolver.mjs       ← Task 4.3 (slash-path → ~/.bf/wo/<id>/)
    │   ├── flow-selector.mjs     ← Task 4.3 (routing[schema,state] → flow id)
    │   ├── node-runner.mjs       ← Task 4.4 (one node tick — mkdir, dispatch agents,
    │   │                                       seal, validate, transition)
    │   └── nl-parse.mjs          ← Task 4.6
    ├── flow-core.mjs             ← MODIFY: filename → artifact-type
    │                                       inference cleanup + 'eval.md' alias
    ├── flow-transition.mjs       ← MODIFY: Pack-overridable mandatory-role list
    ├── viz-commands.mjs          ← MODIFY: render ITERATE/FAIL back-edges
    ├── flow-escape.mjs           ← MODIFY: /opc strings → /bf
    ├── loop-advance.mjs          ← MODIFY: /opc strings → /bf
    └── runbooks.mjs              ← MODIFY: /opc strings → /bf

test/
├── verbs/                        ← NEW DIRECTORY: per-verb test scripts
│   ├── test-help.sh              ← Task 4.5
│   ├── test-create.sh            ← Task 4.4
│   ├── test-execute-leaf.sh      ← Task 4.4 (drives close-leaf-task end-to-end)
│   ├── test-show-tree-list.sh    ← Task 4.5
│   └── test-nl-parse-stub.sh     ← Task 4.6 (stubbed LLM)
├── dispatcher/
│   ├── test-arg-parser.sh        ← Task 4.3
│   ├── test-pack-discovery.sh    ← Task 4.3
│   └── test-node-runner.sh       ← Task 4.4
└── test-stage4-regression.sh     ← Task 4.8 (cross-verb sanity)

packs/product-engineering/
└── protocols/                    ← MODIFY (4 files): rename "Outputs" filename
                                    convention from eval.md → eval-<role>.md to
                                    match harness inference (Stage 3 finding #1)

bin/bf.mjs                        ← rewrite-from-scratch (placeholder gone)
scripts/postinstall.mjs           ← MODIFY: register the new bin/lib/verbs/ tree
                                    in the skill-install copy list
README.md                         ← MODIFY: real install + usage section (Task 4.7)
package.json                      ← MODIFY: bump version to 0.2.0-alpha,
                                    add "publishConfig.access": "public",
                                    add "files" entries for new bin/lib/ paths
                                    (Task 4.7)
UPSTREAM.md                       ← APPEND: Stage 4 delta entries per task
docs/specs/
├── 2026-05-16-bf-fork-design/
│   └── core-contracts.md         ← APPEND: any new Open items surfaced (Task 4.8)
└── 2026-05-17-stage-4-retro.md   ← NEW (Task 4.8)
```

**Not touched in this plan:**
- v6 plugin at `plugins/blueprintflow/` (stays as the side-by-side fallback).
- `references/*.md` Core contract docs (revisions land in Stage 6 after Stage 5 demo).
- `packs/product-engineering/reference-v6/*` (frozen until Stage 6 migration).
- New Pack schemas (`phase.json`, `blueprint.json`) — Stage 6.

---

## Stage 4 task layout

Eight tasks. Each ends with a checkpoint commit; Task 4.4 and 4.5 are the largest and may produce multiple commits (one per verb).

1. **Task 4.1 — Sweep deferred `/opc` strings** (mechanical; ships the first BF-branded user-facing strings inside vendored code)
2. **Task 4.2 — Harden `bf-harness`** (the 6 dispatcher-prerequisite Stage 3 findings — without these, Task 4.4's `execute` can't even start a real WO)
3. **Task 4.3 — Dispatcher scaffold** (arg parser, Pack discovery, WO-id resolution, flow selector, node-runner module — all testable in isolation before any verb wires them together)
4. **Task 4.4 — Lifecycle verbs** (create / execute / brainstorm / breakdown / loop / close)
5. **Task 4.5 — Inspection, escape, meta verbs** (everything else from the verb catalog)
6. **Task 4.6 — NL parse front-end** (transcribe natural-language input → verb form → print → re-enter verb path)
7. **Task 4.7 — Packaging dry-run + README** (`npm publish --dry-run`, updated install/use docs, version bump)
8. **Task 4.8 — Stage 4 retro + Stage 5 punch list** (capture what stayed broken; hand off to demo planning)

(Tasks 4.2 and 4.3 are independent — could run in parallel as separate subagent invocations if the subagent-driven runner supports it. The plan presents them sequentially for clarity.)

---

## Task 4.1 — Sweep deferred `/opc` strings

The 9 user-facing `/opc <verb>` strings in vendored code (flagged in `UPSTREAM.md` § "Deferred to Stage 4") become `/bf <verb>`. Mechanical edit; ships the first BF-branded user message inside the runtime.

**Files:**
- Modify: `bin/lib/flow-escape.mjs` (7 strings — lines 36, 107, 132, 146, 186, 217, 252)
- Modify: `bin/lib/runbooks.mjs` (1 string — line 4)
- Modify: `bin/lib/loop-advance.mjs` (2 strings — lines 17, 551)
- Modify: `UPSTREAM.md` (remove the deferred-strings note; append delta-log row)

- [ ] **Step 1: Find the 10 strings**

```bash
grep -n "/opc " bin/lib/flow-escape.mjs bin/lib/runbooks.mjs bin/lib/loop-advance.mjs
```

Expected: 10 hits across the 3 files (9 user-facing + 1 comment header in runbooks.mjs).

- [ ] **Step 2: Apply substitution**

```bash
for f in bin/lib/flow-escape.mjs bin/lib/runbooks.mjs bin/lib/loop-advance.mjs; do
  sed -i 's|/opc |/bf |g' "$f"
done
```

- [ ] **Step 3: Verify no residuals**

```bash
grep -rn "/opc " bin/lib/ || echo CLEAN
```

Expected: `CLEAN`. (The literal word "OPC" referring to the upstream project name remains in comments / commit messages — that's intentional.)

- [ ] **Step 4: Update `UPSTREAM.md`**

Find the existing section:

```
## Deferred to Stage 4 (bf-run skill)

User-visible slash-command strings still reference `/opc` ...
```

Replace the body with:

```
(Section closed: Stage 4 swept all 9 deferred `/opc <verb>` user-facing
strings to `/bf <verb>` in commit <FILL-IN-SHA-AFTER-COMMIT>. Search
to confirm later: `grep -rn '/opc ' bin/lib/`.)
```

Append a delta-log row:

```
| 2026-05-17 | bin/lib/{flow-escape,runbooks,loop-advance}.mjs | Stage 4 task 4.1: sweep 9 deferred `/opc <verb>` user-facing strings to `/bf <verb>`. The literal word "OPC" referring to the upstream project name is unchanged. |
```

- [ ] **Step 5: Run tests**

```bash
bash test/run-all.sh 2>&1 | tail -3
```

Expected: still `108 files passed, 0 files failed`. (No test asserts the exact `/opc` string; if one does, surface and discuss before editing.)

- [ ] **Step 6: Commit**

```bash
git add bin/lib/flow-escape.mjs bin/lib/runbooks.mjs bin/lib/loop-advance.mjs UPSTREAM.md
git commit -m "$(cat <<'EOF'
feat(bf): sweep deferred /opc strings to /bf

Stage 4 task 4.1. Renames the 9 user-facing `/opc <verb>` strings
inside vendored code (flow-escape.mjs, runbooks.mjs, loop-advance.mjs)
to `/bf <verb>`. The literal word "OPC" as a project-name reference is
unchanged. Closes the "Deferred to Stage 4" section in UPSTREAM.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

After the commit lands, edit `UPSTREAM.md` again to fill the `<FILL-IN-SHA-AFTER-COMMIT>` placeholder, then `git commit --amend --no-edit` is OK here (the SHA reference is a self-pointer documentation-only fix).

---

## Task 4.2 — Harden `bf-harness` per Stage 3 findings

Six harness behaviors must change before `bf execute` can drive a real WO without manual workarounds. Each finding maps to one sub-task (4.2a–4.2f) — each gets its own failing test, fix, passing test, commit. Order matters: 4.2c blocks 4.2b which blocks 4.2a (later items assume earlier ones work). Sub-tasks 4.2d–4.2f are independent of each other and of the chain.

**Files (cumulative across 4.2a–4.2f):**
- Modify: `bin/bf-harness.mjs` (4.2a — `--dir` sandbox policy)
- Modify: `bin/bf-harness.mjs` (4.2b — auto-create `run_N/`)
- Modify: `bin/lib/flow-core.mjs:494–497` (4.2c — accept `eval.md` filename)
- Modify: `bin/lib/flow-core.mjs` (4.2d — seal hardening: `validationErrors[].length > 0` => `sealed: false`)
- Modify: `bin/lib/flow-transition.mjs` (4.2e — Pack-overridable mandatory roles)
- Modify: `bin/lib/viz-commands.mjs` (4.2f — render back-edges)
- Create: `test/harness-hardening/test-{a,b,c,d,e,f}.sh` (six failing-first tests)
- Modify: `packs/product-engineering/protocols/*.md` (4.2c side-effect — update "Outputs" sections to point at the now-supported `eval.md`)

### 4.2a — `--dir` accepts `/tmp/bf-*` paths

**Why:** Stage 3 demo blocked on `--dir /tmp/...`. Either widen the allow-list to `/tmp/bf-*` (matches the convention demo recipes use) or document the harness only accepts cwd / `~/.bf/sessions/`. We widen.

**Files:**
- Modify: `bin/bf-harness.mjs` (find the `--dir` resolver — look for the literal error string `"outside cwd"`).
- Create: `test/harness-hardening/test-a-dir-sandbox.sh`

- [ ] **Step 1: Locate the current sandbox check**

```bash
grep -n "outside cwd" bin/bf-harness.mjs
```

Capture the surrounding 20 lines. The check rejects any `--dir` not under cwd or `~/.bf/sessions/`.

- [ ] **Step 2: Write the failing test**

Create `test/harness-hardening/test-a-dir-sandbox.sh`:

```bash
#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$DIR"' EXIT

OUT=$($HARNESS init --flow review --entry review --dir "$DIR" 2>&1) || true
if echo "$OUT" | grep -q "outside cwd"; then
  echo "FAIL: --dir sandbox still rejects /tmp/bf-* path"
  echo "  got: $OUT"
  exit 1
fi
echo "PASS: --dir /tmp/bf-* accepted"
```

`chmod +x test/harness-hardening/test-a-dir-sandbox.sh`.

- [ ] **Step 3: Run to confirm it fails**

```bash
bash test/harness-hardening/test-a-dir-sandbox.sh
```

Expected: `FAIL: --dir sandbox still rejects /tmp/bf-* path`.

- [ ] **Step 4: Widen the allow-list**

In `bin/bf-harness.mjs`, the sandbox check rejects any path not under cwd or `~/.bf/sessions/`. Add a third allowed pattern: paths matching `/tmp/bf-*` (or `$TMPDIR/bf-*` for portability). Concrete diff:

```diff
- if (!resolvedDir.startsWith(cwd) && !resolvedDir.startsWith(bfSessionsRoot)) {
+ const tmpBfPattern = path.join(os.tmpdir(), "bf-");
+ if (
+   !resolvedDir.startsWith(cwd) &&
+   !resolvedDir.startsWith(bfSessionsRoot) &&
+   !resolvedDir.startsWith(tmpBfPattern)
+ ) {
    console.log(JSON.stringify({
-     error: `--dir resolved to '${resolvedDir}' which is outside cwd '${cwd}' and ~/.bf/sessions/`,
+     error: `--dir resolved to '${resolvedDir}' which is outside cwd '${cwd}', ~/.bf/sessions/, and ${tmpBfPattern}*`,
    }));
    process.exit(1);
  }
```

(Imports for `path` and `os` are almost certainly already in the file. If not, add `import path from "node:path"; import os from "node:os";` at the top.)

- [ ] **Step 5: Run the test, confirm PASS**

```bash
bash test/harness-hardening/test-a-dir-sandbox.sh
```

Expected: `PASS: --dir /tmp/bf-* accepted`.

- [ ] **Step 6: Run full suite**

```bash
bash test/run-all.sh 2>&1 | tail -3
```

Expected: `109 files passed, 0 files failed` (108 baseline + the new test).

- [ ] **Step 7: Commit**

```bash
git add bin/bf-harness.mjs test/harness-hardening/test-a-dir-sandbox.sh
git commit -m "$(cat <<'EOF'
feat(bf): widen bf-harness --dir sandbox to accept /tmp/bf-* paths

Stage 4 task 4.2a. Stage 3 demo (commit 34ebb5e) blocked on
`--dir /tmp/bf-stage3-demo-wo/...` getting rejected by the sandbox
allow-list (cwd / ~/.bf/sessions/ only). Widens to also allow paths
under `$TMPDIR/bf-*`, matching the convention the demo recipes use.
Adds test/harness-hardening/test-a-dir-sandbox.sh.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.2b — Auto-create `nodes/<id>/run_N/` on seal

**Why:** Stage 3 finding #3 — `seal` returns `"no run_N directories found"` if the agent didn't `mkdir nodes/<id>/run_1/` first. Dispatcher orchestration shouldn't need to know this; harness should make the next `run_N/` itself on demand.

**Files:**
- Modify: `bin/bf-harness.mjs` (the `seal` command)
- Create: `test/harness-hardening/test-b-auto-run-dir.sh`

- [ ] **Step 1: Write the failing test**

Create `test/harness-hardening/test-b-auto-run-dir.sh`:

```bash
#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$DIR"' EXIT

$HARNESS init --flow review --entry review --dir "$DIR" >/dev/null
# Note: no manual `mkdir $DIR/nodes/review/run_1` step
OUT=$($HARNESS seal --node review --dir "$DIR" 2>&1) || true
if echo "$OUT" | grep -q "no run_N directories found"; then
  echo "FAIL: seal still requires pre-existing run_N/"
  echo "  got: $OUT"
  exit 1
fi
if [ ! -d "$DIR/nodes/review/run_1" ]; then
  echo "FAIL: seal did not auto-create run_1/"
  exit 1
fi
echo "PASS: seal auto-created nodes/review/run_1/"
```

- [ ] **Step 2: Confirm failure** (`bash test/harness-hardening/test-b-auto-run-dir.sh` → FAIL).

- [ ] **Step 3: Implement auto-create**

In `bin/bf-harness.mjs`, find the `seal` command handler (`grep -n "no run_N" bin/bf-harness.mjs` will land on or near it). Before the "no run_N" error, if the directory has zero `run_*` subdirs, `mkdirSync(path.join(nodeDir, "run_1"), {recursive: true})` and continue. Behavior: seal still requires at least one artifact file in the run dir, so an auto-created empty `run_1/` still hits the "no artifacts" check on the next line — that's correct semantics (an empty seal is meaningless).

- [ ] **Step 4: Confirm PASS + full suite green** (`bash test/run-all.sh 2>&1 | tail -3` → `110 files passed`).

- [ ] **Step 5: Commit**

```bash
git add bin/bf-harness.mjs test/harness-hardening/test-b-auto-run-dir.sh
git commit -m "$(cat <<'EOF'
feat(bf): bf-harness seal auto-creates nodes/<id>/run_1/ on first call

Stage 4 task 4.2b. Closes Stage 3 demo finding #3: seal previously
required the dispatcher to mkdir nodes/<id>/run_N/ before any artifact
could be sealed. Now seal lazily creates run_1/ if no run_* subdirs
exist, so node protocols and the future bf-run dispatcher can drop
artifacts and call seal directly without an explicit setup step.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.2c — `seal` accepts `eval.md` as artifact type `eval`

**Why:** Stage 3 finding #1 — Pack protocols tell agents to write `eval.md`, but the harness's filename-driven inference only recognizes `^eval-.*\.md$`. Bare `eval.md` becomes type `source`, which then trips the "review node requires ≥2 eval artifacts" check. Two fixes coexist: (1) accept `eval.md` and `eval-<role>.md` both as type `eval` in `flow-core.mjs`; (2) update the 4 Pack protocols' "Outputs" sections to use `eval-<role>.md` as the *preferred* convention (the bare name still works, but role-tagged is recommended for review nodes that need multiple distinct evals).

**Files:**
- Modify: `bin/lib/flow-core.mjs` (the `inferArtifactType` function — around line 494 per Stage 3 finding)
- Create: `test/harness-hardening/test-c-eval-md-alias.sh`
- Modify: `packs/product-engineering/protocols/brainstorm-task.md`
- Modify: `packs/product-engineering/protocols/breakdown-milestone-to-task.md`
- Modify: `packs/product-engineering/protocols/loop-milestone.md`
- Modify: `packs/product-engineering/protocols/close-leaf-task.md`

- [ ] **Step 1: Locate the inference function**

```bash
grep -n "inferArtifactType\|^eval-" bin/lib/flow-core.mjs
```

Capture the regex/switch table for filename → type mapping. The current rule is `^eval-.*\.md$ → eval`.

- [ ] **Step 2: Write the failing test**

Create `test/harness-hardening/test-c-eval-md-alias.sh`:

```bash
#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$DIR"' EXIT

$HARNESS init --flow review --entry review --dir "$DIR" >/dev/null
mkdir -p "$DIR/nodes/review/run_1"
cat > "$DIR/nodes/review/run_1/eval.md" <<EOF
verdict: PASS
summary: stub eval
EOF
OUT=$($HARNESS seal --node review --dir "$DIR" 2>&1)
echo "$OUT" | grep -q '"type":"eval"' || {
  echo "FAIL: eval.md was not inferred as type 'eval'"
  echo "  got: $OUT"
  exit 1
}
echo "PASS: eval.md inferred as type 'eval'"
```

- [ ] **Step 3: Confirm failure.**

- [ ] **Step 4: Update the inference function**

In `bin/lib/flow-core.mjs`, change the eval pattern from `^eval-.*\.md$` to `^eval(-.+)?\.md$`. The capture group makes the role tag optional.

- [ ] **Step 5: Confirm test PASS + full suite green.**

- [ ] **Step 6: Update the 4 Pack protocols' "Outputs" sections**

Each of the 4 protocol files has a node where multi-role review happens (`write-criteria`, `review-breakdown`, `aggregate`, `code-review`). In those nodes, the "Outputs" / "Artifacts" section currently says `eval.md`. Add a note:

```markdown
**Output filename convention:** Each reviewer writes their eval as
`eval-<role>.md` (e.g. `eval-tester.md`, `eval-skeptic-owner.md`) so
the harness can distinguish independent agents. A bare `eval.md` also
works for single-reviewer nodes but cannot satisfy review nodes that
require ≥2 distinct evals.
```

Pick the right insertion point in each file by searching for the existing eval-related text.

- [ ] **Step 7: Commit** (single commit covers both the harness fix and the protocol docs — they're inseparable).

```bash
git add bin/lib/flow-core.mjs test/harness-hardening/test-c-eval-md-alias.sh \
        packs/product-engineering/protocols/{brainstorm-task,breakdown-milestone-to-task,loop-milestone,close-leaf-task}.md
git commit -m "$(cat <<'EOF'
feat(bf): seal accepts bare eval.md as artifact type 'eval'

Stage 4 task 4.2c. Closes Stage 3 demo finding #1 (the most user-
visible Pack/Core convention collision): Pack protocols documented
`eval.md` as the per-node output filename, but bf-harness's filename
inference only matched `^eval-.*\.md$` and silently classified bare
eval.md as 'source'. Review nodes then failed with
"review node requires ≥2 eval artifacts".

Widens the regex to `^eval(-.+)?\.md$` and updates the 4 product-
engineering Pack protocols to document the recommended
`eval-<role>.md` convention for multi-reviewer review nodes.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.2d — `seal` returns `sealed: false` when `validationErrors[].length > 0`

**Why:** Stage 3 finding #6 — seal currently returns `{sealed: true, validationErrors: [...]}`. Every caller has to remember to inspect both fields. Dispatcher safety: treat non-empty `validationErrors` as a hard `sealed: false`; preserve `warnings` (soft hints) as-is.

**Files:**
- Modify: `bin/lib/flow-core.mjs` (the seal result construction)
- Create: `test/harness-hardening/test-d-seal-validation-errors.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$DIR"' EXIT

$HARNESS init --flow review --entry review --dir "$DIR" >/dev/null
mkdir -p "$DIR/nodes/review/run_1"
# review node requires ≥2 evals; we provide only 1 → validationErrors
cat > "$DIR/nodes/review/run_1/eval-stub.md" <<EOF
verdict: PASS
EOF
OUT=$($HARNESS seal --node review --dir "$DIR" 2>&1) || true
# Expect sealed:false when validationErrors non-empty
if echo "$OUT" | grep -q '"sealed":true'; then
  if echo "$OUT" | grep -q '"validationErrors":\[]'; then
    echo "PASS: sealed:true with empty validationErrors (acceptable)"
  else
    echo "FAIL: sealed:true returned with non-empty validationErrors"
    echo "  got: $OUT"
    exit 1
  fi
fi
echo "PASS: sealed:false when validationErrors non-empty"
```

- [ ] **Step 2: Confirm fail.**

- [ ] **Step 3: Implement**

In `bin/lib/flow-core.mjs`, in the seal result builder, after collecting `validationErrors`:

```diff
- return { sealed: true, validationErrors, warnings, ... };
+ const sealed = validationErrors.length === 0;
+ return { sealed, validationErrors, warnings, ... };
```

- [ ] **Step 4: Confirm test PASS + full suite green.** This change may flip other tests that asserted `sealed:true` while passing bad input. If any test breaks, fix the test (it was relying on a leniency that the dispatcher cannot live with) and note the test change in the commit body.

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/flow-core.mjs test/harness-hardening/test-d-seal-validation-errors.sh
git commit -m "$(cat <<'EOF'
fix(bf): seal returns sealed:false when validationErrors non-empty

Stage 4 task 4.2d. Closes Stage 3 demo finding #6: seal used to return
`{sealed:true, validationErrors:[...]}`, requiring callers to inspect
both fields. Dispatcher orchestration treats this as a footgun. Now
seal hard-fails (sealed:false) whenever validationErrors is non-empty;
soft `warnings` are preserved.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.2e — Pack-overridable mandatory-role list

**Why:** Stage 3 finding #4 — `skeptic-owner` is hardcoded in `flow-transition.mjs` as the required reviewer. Packs can't extend the list (a research Pack might want `compliance` instead). Add a Pack-declared list in `pack.json` (`mandatory_roles: [...]`), merged with the Core default.

**Files:**
- Modify: `bin/lib/flow-transition.mjs` (the mandatory-role check)
- Modify: `packs/product-engineering/pack.json` (add `mandatory_roles: ["skeptic-owner"]` to keep current behavior explicit)
- Create: `test/harness-hardening/test-e-pack-mandatory-roles.sh`

- [ ] **Step 1: Locate the current check**

```bash
grep -n "skeptic-owner\|mandatory" bin/lib/flow-transition.mjs
```

Capture the surrounding 30 lines. The current logic almost certainly hardcodes `["skeptic-owner"]` as the mandatory list for review nodes.

- [ ] **Step 2: Write the failing test**

```bash
#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$DIR"' EXIT

# Use a fake Pack manifest declaring `compliance` as mandatory
mkdir -p "$DIR/fake-pack"
cat > "$DIR/fake-pack/pack.json" <<EOF
{"bf_compat":">=0.1","id":"fake","version":"1","mandatory_roles":["compliance"],"routing":{},"state_aliases":{}}
EOF

$HARNESS init --flow review --entry review --dir "$DIR" --pack "$DIR/fake-pack/pack.json" >/dev/null 2>&1 || true
mkdir -p "$DIR/nodes/review/run_1"
cat > "$DIR/nodes/review/run_1/eval-tester.md" <<EOF
verdict: PASS
EOF
cat > "$DIR/nodes/review/run_1/eval-security.md" <<EOF
verdict: PASS
EOF
$HARNESS seal --node review --dir "$DIR" >/dev/null

# Transition should refuse because `compliance` (Pack-declared mandatory) is missing
OUT=$($HARNESS transition --from review --to gate --verdict PASS --flow review --dir "$DIR" --pack "$DIR/fake-pack/pack.json" 2>&1) || true
if echo "$OUT" | grep -q 'Missing mandatory role.*compliance'; then
  echo "PASS: Pack-declared mandatory role enforced"
else
  echo "FAIL: Pack mandatory_roles ignored (got: $OUT)"
  exit 1
fi
```

(The `--pack` flag is a new harness option introduced by this change. It points at a pack.json so the harness can read its `mandatory_roles` field. If the harness doesn't yet take `--pack`, add it as part of this sub-task.)

- [ ] **Step 3: Confirm failure.**

- [ ] **Step 4: Implement**

Add `--pack <path-to-pack.json>` flag to `bf-harness` arg parsing. When present, read `mandatory_roles` from the manifest; merge with Core default (`["skeptic-owner"]`). In `flow-transition.mjs`, replace the hardcoded list with the merged list.

If `--pack` is absent, fall back to Core default — current behavior preserved.

- [ ] **Step 5: Confirm test PASS + full suite green.** Also re-run `test/test-guardrails.sh` from Task 3.4 (already uses Core mandatory roles); should stay green.

- [ ] **Step 6: Update product-engineering `pack.json`**

```diff
   "state_aliases": { ... },
+  "mandatory_roles": ["skeptic-owner"],
   "routing": { ... }
```

(Explicit > implicit. Documents the Pack's choice.)

- [ ] **Step 7: Commit.**

```bash
git add bin/bf-harness.mjs bin/lib/flow-transition.mjs \
        packs/product-engineering/pack.json \
        test/harness-hardening/test-e-pack-mandatory-roles.sh
git commit -m "$(cat <<'EOF'
feat(bf): Pack-overridable mandatory-role list

Stage 4 task 4.2e. Closes Stage 3 demo finding #4: skeptic-owner was
hardcoded as the only review-node mandatory role, which blocks Packs
from declaring domain-specific mandatories (e.g. a research Pack
needing `compliance`). Adds a `--pack <path>` flag to bf-harness; when
present, the harness reads `mandatory_roles: [...]` from pack.json and
merges with Core default. Product-engineering Pack now declares
`mandatory_roles: ["skeptic-owner"]` explicitly.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.2f — `viz` renders ITERATE and FAIL back-edges

**Why:** Stage 3 demo (and Stage 3 finding §250) found `bf-harness viz` only renders happy-path PASS edges. Reviewers / operators reading the ASCII flow graph can't see the loops.

**Files:**
- Modify: `bin/lib/viz-commands.mjs`
- Create: `test/harness-hardening/test-f-viz-back-edges.sh`

- [ ] **Step 1: Inspect current renderer**

```bash
grep -n "PASS\|ITERATE\|FAIL\|edge" bin/lib/viz-commands.mjs | head -30
```

- [ ] **Step 2: Write the failing test**

```bash
#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
FLOW=packs/product-engineering/flows/brainstorm-task.json

OUT=$($HARNESS viz --flow-file "$FLOW")
echo "$OUT" | grep -q 'ITERATE' || {
  echo "FAIL: viz did not render ITERATE back-edges"
  echo "  got: $OUT"
  exit 1
}
echo "$OUT" | grep -q 'FAIL' || {
  echo "FAIL: viz did not render FAIL back-edges"
  exit 1
}
echo "PASS: viz renders both ITERATE and FAIL back-edges"
```

- [ ] **Step 3: Confirm fail.**

- [ ] **Step 4: Update the renderer**

In `bin/lib/viz-commands.mjs`, after rendering each node's PASS edge, also iterate over `edges[node]` for keys `ITERATE` and `FAIL`. Render them as dashed lines or distinct ASCII style:

```
discuss ──PASS──> write-criteria
                  └─ITERATE─┐
                            │ (back to write-criteria)
write-criteria ──PASS──> criteria-lint
                          └─ITERATE──> write-criteria
gate ──PASS──> (terminal)
     └─FAIL───> discuss
     └─ITERATE─> write-criteria
```

Exact rendering style is up to the implementer; the test only asserts the strings `ITERATE` and `FAIL` appear in the output for the `brainstorm-task` flow (which has both).

- [ ] **Step 5: Confirm test PASS + full suite green.**

- [ ] **Step 6: Commit.**

```bash
git add bin/lib/viz-commands.mjs test/harness-hardening/test-f-viz-back-edges.sh
git commit -m "$(cat <<'EOF'
feat(bf): viz renders ITERATE and FAIL back-edges

Stage 4 task 4.2f. Closes Stage 3 finding §250 in core-contracts.md:
viz previously rendered only the PASS happy path, hiding
criteria-lint→write-criteria and gate→discuss/write-criteria loops.
Operators and reviewers now see the complete flow graph.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.2 wrap-up

After 4.2a–4.2f all green:

- [ ] **Update `UPSTREAM.md`** with a single Stage 4 task 4.2 delta-log row summarizing the 6 harness changes (link to each commit SHA).
- [ ] **Run `bash test/run-all.sh 2>&1 | tail -3`** — expect `114 files passed, 0 files failed` (108 baseline + 6 new harness-hardening tests).
- [ ] **No commit** — the wrap-up step is just the UPSTREAM.md edit, commit it standalone.

```bash
git add UPSTREAM.md
git commit -m "docs(bf): UPSTREAM delta for Stage 4 task 4.2 harness hardening"
```

---

## Task 4.3 — Dispatcher scaffold

Build the dispatcher's reusable parts in isolation before any verb wires them together. Each module is small, focused, independently testable.

**Files (all new):**
- Create: `bin/lib/dispatcher/arg-parser.mjs`
- Create: `bin/lib/dispatcher/pack-discovery.mjs`
- Create: `bin/lib/dispatcher/wo-resolver.mjs`
- Create: `bin/lib/dispatcher/flow-selector.mjs`
- Create: `test/dispatcher/test-arg-parser.sh`
- Create: `test/dispatcher/test-pack-discovery.sh`
- Create: `test/dispatcher/test-wo-resolver.sh`
- Create: `test/dispatcher/test-flow-selector.sh`

### 4.3a — `arg-parser.mjs`

Parses `process.argv` into `{ verb, args, flags }`. The verb is the first non-flag token; everything after is positional `args` plus `--key value` / `--bool-flag` pairs into `flags`.

**Acceptance:**
- `bf execute auth-v1/login --one-step` → `{verb: "execute", args: ["auth-v1/login"], flags: {oneStep: true}}`
- `bf create "implement v1 auth" --pack product-engineering` → `{verb: "create", args: ["implement v1 auth"], flags: {pack: "product-engineering"}}`
- `bf` (no args) → `{verb: "help", args: [], flags: {}}`
- `bf --help` → `{verb: "help", args: [], flags: {}}`
- Unknown verb (not in known set) → returned as-is, dispatcher decides whether to NL-route.

- [ ] **Step 1: Write the failing test**

`test/dispatcher/test-arg-parser.sh`:

```bash
#!/usr/bin/env bash
set -e

run() {
  node -e "
    import('./bin/lib/dispatcher/arg-parser.mjs').then(m => {
      const out = m.parseArgs($1);
      console.log(JSON.stringify(out));
    });
  "
}

# Test 1: execute with positional + flag
OUT=$(run '["execute","auth-v1/login","--one-step"]')
echo "$OUT" | grep -q '"verb":"execute"' || { echo "FAIL t1: verb"; exit 1; }
echo "$OUT" | grep -q '"oneStep":true' || { echo "FAIL t1: flag"; exit 1; }
echo "$OUT" | grep -q '"auth-v1/login"' || { echo "FAIL t1: arg"; exit 1; }

# Test 2: create with quoted description + --pack
OUT=$(run '["create","implement v1 auth","--pack","product-engineering"]')
echo "$OUT" | grep -q '"verb":"create"' || { echo "FAIL t2: verb"; exit 1; }
echo "$OUT" | grep -q '"pack":"product-engineering"' || { echo "FAIL t2: pack"; exit 1; }

# Test 3: empty → help
OUT=$(run '[]')
echo "$OUT" | grep -q '"verb":"help"' || { echo "FAIL t3: empty→help"; exit 1; }

# Test 4: --help alias
OUT=$(run '["--help"]')
echo "$OUT" | grep -q '"verb":"help"' || { echo "FAIL t4: --help"; exit 1; }

echo "PASS: arg-parser handles 4 cases"
```

- [ ] **Step 2: Confirm failure** (module doesn't exist yet).

- [ ] **Step 3: Implement** `bin/lib/dispatcher/arg-parser.mjs`:

```javascript
const KNOWN_VERBS = new Set([
  "execute", "create", "brainstorm", "breakdown", "loop", "close",
  "show", "tree", "list", "discard",
  "skip", "pass", "stop", "goto", "resume",
  "pack", "flow", "help",
]);

function camel(kebab) {
  return kebab.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

export function parseArgs(argv) {
  if (argv.length === 0 || argv[0] === "--help" || argv[0] === "-h") {
    return { verb: "help", args: [], flags: {} };
  }
  const verb = argv[0];
  const rest = argv.slice(1);
  const args = [];
  const flags = {};
  for (let i = 0; i < rest.length; i++) {
    const t = rest[i];
    if (t.startsWith("--")) {
      const key = camel(t.slice(2));
      const next = rest[i + 1];
      if (next === undefined || next.startsWith("--")) {
        flags[key] = true;
      } else {
        flags[key] = next;
        i++;
      }
    } else {
      args.push(t);
    }
  }
  return { verb, args, flags, knownVerb: KNOWN_VERBS.has(verb) };
}
```

- [ ] **Step 4: Confirm test PASS + full suite green.**

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/dispatcher/arg-parser.mjs test/dispatcher/test-arg-parser.sh
git commit -m "feat(bf): dispatcher arg-parser (Stage 4 task 4.3a)"
```

### 4.3b — `pack-discovery.mjs`

Scans for installed Packs. v0.2 scope: in-repo `packs/*/pack.json` only (no sibling npm packages — that's v0.3+). Returns `[{id, version, path, manifest}, ...]`.

- [ ] **Step 1: Write the failing test**

`test/dispatcher/test-pack-discovery.sh`:

```bash
#!/usr/bin/env bash
set -e

OUT=$(node -e "
  import('./bin/lib/dispatcher/pack-discovery.mjs').then(m => {
    m.discoverPacks().then(p => console.log(JSON.stringify(p)));
  });
")
echo "$OUT" | grep -q '"id":"product-engineering"' || { echo "FAIL: did not find product-engineering Pack"; exit 1; }
echo "$OUT" | grep -q '"version":"1.0.0-alpha"' || { echo "FAIL: did not read version from manifest"; exit 1; }
echo "PASS: pack-discovery found product-engineering Pack"
```

- [ ] **Step 2: Confirm failure.**

- [ ] **Step 3: Implement** `bin/lib/dispatcher/pack-discovery.mjs`:

```javascript
import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";

// v0.2 scope: scan repo-local packs/. Future: also scan sibling npm packages.
const REPO_PACKS_DIR = path.resolve(process.cwd(), "packs");

export async function discoverPacks() {
  let entries;
  try {
    entries = await readdir(REPO_PACKS_DIR, { withFileTypes: true });
  } catch (e) {
    return [];
  }
  const packs = [];
  for (const e of entries) {
    if (!e.isDirectory()) continue;
    const manifestPath = path.join(REPO_PACKS_DIR, e.name, "pack.json");
    try {
      const raw = await readFile(manifestPath, "utf8");
      const manifest = JSON.parse(raw);
      packs.push({
        id: manifest.id ?? e.name,
        version: manifest.version ?? "0.0.0",
        path: path.join(REPO_PACKS_DIR, e.name),
        manifest,
      });
    } catch (e) {
      // pack.json missing or invalid — skip
    }
  }
  return packs;
}
```

- [ ] **Step 4: Confirm test PASS + full suite green.**

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/dispatcher/pack-discovery.mjs test/dispatcher/test-pack-discovery.sh
git commit -m "feat(bf): dispatcher pack-discovery (Stage 4 task 4.3b)"
```

### 4.3c — `wo-resolver.mjs`

Resolves a slash-separated WO id (`auth-v1/login/login-form`) to a filesystem path under `~/.bf/wo/`, validating that every segment contains a `wo.md`.

Returns `{path, exists, schema, current_state, pack}` for a valid WO; throws (or returns `{exists: false}`) otherwise.

- [ ] **Step 1: Write the failing test**

`test/dispatcher/test-wo-resolver.sh`:

```bash
#!/usr/bin/env bash
set -e

# Setup a fake WO home under TMPDIR
WO_HOME=$(mktemp -d -p /tmp bf-wo-test-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

mkdir -p "$WO_HOME/auth-v1/login"
cat > "$WO_HOME/auth-v1/wo.md" <<EOF
---
schema: blueprint
current_state: shaped
pack: product-engineering
---
# Auth v1
EOF
cat > "$WO_HOME/auth-v1/login/wo.md" <<EOF
---
schema: task
current_state: new
pack: product-engineering
---
# Login subtask
EOF

OUT=$(BF_WO_HOME="$WO_HOME" node -e "
  import('./bin/lib/dispatcher/wo-resolver.mjs').then(m => {
    m.resolveWo('auth-v1/login').then(r => console.log(JSON.stringify(r)));
  });
")

echo "$OUT" | grep -q '"schema":"task"' || { echo "FAIL: wrong schema"; exit 1; }
echo "$OUT" | grep -q '"current_state":"new"' || { echo "FAIL: wrong state"; exit 1; }
echo "$OUT" | grep -q '"exists":true' || { echo "FAIL: exists flag"; exit 1; }

# Missing intermediate wo.md → invalid path
rm "$WO_HOME/auth-v1/wo.md"
OUT=$(BF_WO_HOME="$WO_HOME" node -e "
  import('./bin/lib/dispatcher/wo-resolver.mjs').then(m => {
    m.resolveWo('auth-v1/login').then(r => console.log(JSON.stringify(r)));
  });
")
echo "$OUT" | grep -q '"exists":false' || { echo "FAIL: should reject broken chain"; exit 1; }

echo "PASS: wo-resolver handles valid + broken chain"
```

- [ ] **Step 2: Confirm failure.**

- [ ] **Step 3: Implement** `bin/lib/dispatcher/wo-resolver.mjs`:

```javascript
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import os from "node:os";

const WO_HOME = process.env.BF_WO_HOME ?? path.join(os.homedir(), ".bf", "wo");

function parseFrontmatter(md) {
  const m = md.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return {};
  const out = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^(\w+):\s*(.+)$/);
    if (kv) out[kv[1]] = kv[2].trim();
  }
  return out;
}

export async function resolveWo(woId) {
  const segments = woId.split("/").filter(Boolean);
  if (segments.length === 0) return { exists: false, reason: "empty wo id" };

  let cur = WO_HOME;
  for (const seg of segments) {
    cur = path.join(cur, seg);
    try {
      await stat(path.join(cur, "wo.md"));
    } catch {
      return { exists: false, reason: `missing wo.md at ${cur}`, path: cur };
    }
  }
  const md = await readFile(path.join(cur, "wo.md"), "utf8");
  const fm = parseFrontmatter(md);
  return {
    exists: true,
    path: cur,
    schema: fm.schema,
    current_state: fm.current_state,
    pack: fm.pack,
  };
}
```

- [ ] **Step 4: Confirm test PASS + full suite green.**

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/dispatcher/wo-resolver.mjs test/dispatcher/test-wo-resolver.sh
git commit -m "feat(bf): dispatcher wo-resolver (Stage 4 task 4.3c)"
```

### 4.3d — `flow-selector.mjs`

Given a Pack manifest + a WO's `{schema, current_state}`, returns the flow id from `pack.json.routing` (with `state_aliases` applied). Returns `null` if no rule matches.

- [ ] **Step 1: Write the failing test**

`test/dispatcher/test-flow-selector.sh`:

```bash
#!/usr/bin/env bash
set -e

OUT=$(node -e "
  import('./bin/lib/dispatcher/flow-selector.mjs').then(m => {
    const manifest = {
      routing: {'task,new': 'brainstorm-task', 'task,doing': 'close-leaf-task'},
      state_aliases: {'reviewed_task_ready': 'shaped'}
    };
    console.log(JSON.stringify({
      a: m.selectFlow(manifest, {schema:'task', current_state:'new'}),
      b: m.selectFlow(manifest, {schema:'task', current_state:'doing'}),
      c: m.selectFlow(manifest, {schema:'task', current_state:'reviewed_task_ready'}),
      d: m.selectFlow(manifest, {schema:'task', current_state:'done'}),
    }));
  });
")
echo "$OUT" | grep -q '"a":"brainstorm-task"' || { echo "FAIL a"; exit 1; }
echo "$OUT" | grep -q '"b":"close-leaf-task"' || { echo "FAIL b"; exit 1; }
# state_aliases: reviewed_task_ready → shaped, but routing has no task,shaped → null
echo "$OUT" | grep -q '"c":null' || { echo "FAIL c (alias-then-miss)"; exit 1; }
echo "$OUT" | grep -q '"d":null' || { echo "FAIL d (no rule)"; exit 1; }

echo "PASS: flow-selector handles routing + state_aliases + miss"
```

- [ ] **Step 2: Confirm failure.**

- [ ] **Step 3: Implement** `bin/lib/dispatcher/flow-selector.mjs`:

```javascript
export function selectFlow(packManifest, wo) {
  const routing = packManifest.routing ?? {};
  const aliases = packManifest.state_aliases ?? {};
  const canonicalState = aliases[wo.current_state] ?? wo.current_state;
  const key = `${wo.schema},${canonicalState}`;
  return routing[key] ?? null;
}
```

- [ ] **Step 4: Confirm test PASS + full suite green** (test count now `108 baseline + 6 harness + 4 dispatcher = 118 passed`).

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/dispatcher/flow-selector.mjs test/dispatcher/test-flow-selector.sh
git commit -m "feat(bf): dispatcher flow-selector (Stage 4 task 4.3d)"
```

### 4.3 wrap-up

- [ ] **Update `UPSTREAM.md`** with a Task 4.3 delta-log row summarizing the 4 new dispatcher modules.

```bash
git add UPSTREAM.md
git commit -m "docs(bf): UPSTREAM delta for Stage 4 task 4.3 dispatcher scaffold"
```

---

## Task 4.4 — Lifecycle verbs

Wire the verbs that drive Work Objects through their Core flows: `create`, `execute`, `brainstorm`, `breakdown`, `loop`, `close`. The dispatcher's `node-runner.mjs` (shared by all single-flow verbs) is built first, then each verb sits on top as a thin orchestrator.

**Files (cumulative across 4.4a–4.4g):**
- Create: `bin/lib/dispatcher/node-runner.mjs` (the per-node tick)
- Create: `bin/lib/verbs/{create,execute,brainstorm,breakdown,loop,close}.mjs`
- Modify: `bin/bf.mjs` (rewrite — replace placeholder)
- Create: `test/dispatcher/test-node-runner.sh`
- Create: `test/verbs/test-create.sh`
- Create: `test/verbs/test-execute-leaf.sh` (drives `close-leaf-task` end-to-end)

### 4.4a — `node-runner.mjs`

One module, one job: run one flow node from start to finish. Inputs: `{packPath, flowFile, runDir, nodeId, transitionToNext}`. Side effects: ensures `nodes/<nodeId>/run_N/` exists, dispatches the node's role agents (4.4 v0.2: dispatches are stubbed — emit a placeholder eval-<role>.md so the harness can seal), calls `seal`, returns `{nextNode, verdict, sealed}` for the outer verb to decide whether to advance.

**Stub note:** v0.2's `node-runner` does NOT call real LLM agents. It writes a stub `eval-<role>.md` with verdict `PASS` for every required role of the current node (read from the flow JSON). This makes `execute` end-to-end runnable in CI without LLM access; Stage 5 demo will replace the stub with real agent dispatch via Claude Code's subagent API.

- [ ] **Step 1: Write the failing test**

`test/dispatcher/test-node-runner.sh`:

```bash
#!/usr/bin/env bash
set -e

RUN_DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$RUN_DIR"' EXIT

node bin/bf-harness.mjs init \
  --flow-file packs/product-engineering/flows/close-leaf-task.json \
  --entry implement --dir "$RUN_DIR" >/dev/null

OUT=$(node -e "
  import('./bin/lib/dispatcher/node-runner.mjs').then(m => {
    m.runNode({
      packPath: 'packs/product-engineering',
      flowFile: 'packs/product-engineering/flows/close-leaf-task.json',
      runDir: '$RUN_DIR',
      nodeId: 'implement',
      transitionToNext: true,
    }).then(r => console.log(JSON.stringify(r)));
  });
")

echo "$OUT" | grep -q '"sealed":true' || { echo "FAIL: node-runner did not seal"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q '"nextNode":"code-review"' || { echo "FAIL: did not advance to code-review"; exit 1; }
[ -d "$RUN_DIR/nodes/implement/run_1" ] || { echo "FAIL: run_1 not created"; exit 1; }

echo "PASS: node-runner ticked implement → code-review"
```

- [ ] **Step 2: Confirm failure** (module missing).

- [ ] **Step 3: Implement** `bin/lib/dispatcher/node-runner.mjs`:

```javascript
import { mkdir, writeFile, readFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";

const HARNESS = "node bin/bf-harness.mjs";

function sh(cmd) {
  const r = spawnSync("bash", ["-c", cmd], { encoding: "utf8" });
  return { code: r.status, stdout: r.stdout.trim(), stderr: r.stderr.trim() };
}

async function loadFlow(flowFile) {
  return JSON.parse(await readFile(flowFile, "utf8"));
}

function stubEvalFor(role, nodeId) {
  return `---
role: ${role}
verdict: PASS
node: ${nodeId}
---

# Stub eval (Stage 4 v0.2 — replaced by real agent dispatch in Stage 5)

Auto-generated by node-runner. Acceptance check: passed.
`;
}

export async function runNode({ packPath, flowFile, runDir, nodeId, transitionToNext }) {
  const flow = await loadFlow(flowFile);
  const nodeType = flow.nodeTypes?.[nodeId] ?? "unknown";
  const runPath = path.join(runDir, "nodes", nodeId, "run_1");
  await mkdir(runPath, { recursive: true });

  // v0.2 stub: emit one eval per role the node needs.
  // Discovery: read flow.roles?.[nodeId] if present; else use ["tester","skeptic-owner"] for review, ["engineer"] for build, etc.
  const roles = flow.roles?.[nodeId] ?? defaultRolesForType(nodeType);
  for (const role of roles) {
    await writeFile(path.join(runPath, `eval-${role}.md`), stubEvalFor(role, nodeId));
  }
  // execute-type nodes also need cli-output evidence
  if (nodeType === "execute") {
    await writeFile(path.join(runPath, "cli-output.log"), `[stub] ${nodeId} executed OK\n`);
  }

  const sealOut = sh(`${HARNESS} seal --node ${nodeId} --dir ${runDir} --pack ${packPath}/pack.json`);
  const sealResult = sealOut.code === 0 ? JSON.parse(sealOut.stdout) : { sealed: false, error: sealOut.stderr };
  if (!sealResult.sealed) {
    return { sealed: false, error: sealResult, nextNode: null };
  }

  const verdict = "PASS";  // v0.2: stubs always pass
  const edges = flow.edges?.[nodeId] ?? {};
  const nextNode = edges[verdict] ?? null;

  if (transitionToNext && nextNode) {
    const tOut = sh(`${HARNESS} transition --from ${nodeId} --to ${nextNode} --verdict ${verdict} --flow-file ${flowFile} --dir ${runDir} --pack ${packPath}/pack.json`);
    if (tOut.code !== 0) {
      return { sealed: true, verdict, nextNode, transitioned: false, error: tOut.stderr };
    }
  }
  return { sealed: true, verdict, nextNode, transitioned: true };
}

function defaultRolesForType(t) {
  if (t === "review") return ["tester", "skeptic-owner"];
  if (t === "build") return ["engineer"];
  if (t === "discussion") return ["planner", "architect"];
  if (t === "execute") return ["tester"];
  return ["planner"];
}
```

- [ ] **Step 4: Confirm test PASS + full suite green.**

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/dispatcher/node-runner.mjs test/dispatcher/test-node-runner.sh
git commit -m "feat(bf): dispatcher node-runner (Stage 4 task 4.4a, v0.2 stub agents)"
```

### 4.4b — `create` verb

Creates a new top-level WO under `~/.bf/wo/<id>/wo.md`. Pack chosen via `--pack` flag or single-default rule (per `bf-run-commands.md` §5). State starts at `current_state: new`.

**Files:**
- Create: `bin/lib/verbs/create.mjs`
- Create: `test/verbs/test-create.sh`
- Modify: `bin/bf.mjs` (wire `create` verb)

- [ ] **Step 1: Write the failing test**

`test/verbs/test-create.sh`:

```bash
#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs create "test-task-1" --pack product-engineering --schema task 2>&1)
echo "$OUT" | grep -q '"created":true' || { echo "FAIL: create did not report success"; echo "$OUT"; exit 1; }
[ -f "$WO_HOME/test-task-1/wo.md" ] || { echo "FAIL: wo.md not created"; exit 1; }
grep -q 'schema: task' "$WO_HOME/test-task-1/wo.md" || { echo "FAIL: schema not written"; exit 1; }
grep -q 'current_state: new' "$WO_HOME/test-task-1/wo.md" || { echo "FAIL: state not new"; exit 1; }
echo "PASS: create scaffolded ~/.bf/wo/test-task-1/wo.md"
```

- [ ] **Step 2: Confirm failure.**

- [ ] **Step 3: Implement** `bin/lib/verbs/create.mjs`:

```javascript
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { discoverPacks } from "../dispatcher/pack-discovery.mjs";

const WO_HOME = process.env.BF_WO_HOME ?? path.join(os.homedir(), ".bf", "wo");

export async function create({ args, flags }) {
  const description = args[0];
  if (!description) {
    console.log(JSON.stringify({ error: "create requires a description: bf create \"<text>\"" }));
    process.exit(2);
  }
  const id = flags.id ?? description.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 60);
  const schema = flags.schema ?? "task";
  const packs = await discoverPacks();
  let packId = flags.pack;
  if (!packId) {
    if (packs.length === 1) packId = packs[0].id;
    else {
      console.log(JSON.stringify({ error: `multiple Packs installed (${packs.map(p=>p.id).join(", ")}); pass --pack <id>` }));
      process.exit(2);
    }
  }
  const woPath = path.join(WO_HOME, id);
  await mkdir(woPath, { recursive: true });
  const wo = `---
schema: ${schema}
current_state: new
desired_state: done
pack: ${packId}
---

# ${description}

## Objective

${description}

## Boundary

(to be shaped in brainstorm)

## Acceptance criteria

(to be shaped in brainstorm)
`;
  await writeFile(path.join(woPath, "wo.md"), wo);
  console.log(JSON.stringify({ created: true, id, path: woPath, schema, pack: packId, current_state: "new" }));
}
```

- [ ] **Step 4: Wire into `bin/bf.mjs`**

Replace the placeholder. New `bin/bf.mjs`:

```javascript
#!/usr/bin/env node
import { parseArgs } from "./lib/dispatcher/arg-parser.mjs";

const { verb, args, flags, knownVerb } = parseArgs(process.argv.slice(2));

if (verb === "help" || !knownVerb) {
  // Stage 4.5 wires help.mjs; for now print a stub
  const helpMod = await import("./lib/verbs/help.mjs").catch(() => null);
  if (helpMod) { await helpMod.help({ args, flags }); process.exit(0); }
  console.log(`bf — Blueprintflow (alpha)\nVerb '${verb}' not yet wired. Try: bf execute|create|show|help`);
  process.exit(verb === "help" ? 0 : 2);
}

const mod = await import(`./lib/verbs/${verb}.mjs`);
await mod[verb]({ args, flags });
```

- [ ] **Step 5: Confirm test PASS + full suite green.**

- [ ] **Step 6: Commit.**

```bash
git add bin/lib/verbs/create.mjs bin/bf.mjs test/verbs/test-create.sh
git commit -m "feat(bf): verb 'create' (Stage 4 task 4.4b)"
```

### 4.4c — Single-flow verbs (`brainstorm`, `breakdown`, `loop`, `close`)

Each one: read the WO, look up the flow id via `flow-selector`, then walk every node in the flow via `node-runner` until the flow finalizes. Refuses if the WO's current state doesn't match the flow's `accepts.current_state`.

**Files (one commit per verb to keep diffs small):**
- Create: `bin/lib/verbs/brainstorm.mjs`
- Create: `bin/lib/verbs/breakdown.mjs`
- Create: `bin/lib/verbs/loop.mjs` (v0.2: prints "loop core_type requires child-WO dispatch — deferred to Stage 5", exits 0)
- Create: `bin/lib/verbs/close.mjs`

For each verb, implementation skeleton (shared template — vary only the expected `core_type`):

```javascript
import path from "node:path";
import { readFile } from "node:fs/promises";
import { resolveWo } from "../dispatcher/wo-resolver.mjs";
import { discoverPacks } from "../dispatcher/pack-discovery.mjs";
import { selectFlow } from "../dispatcher/flow-selector.mjs";
import { runNode } from "../dispatcher/node-runner.mjs";

const EXPECTED_CORE_TYPE = "<brainstorm|breakdown|loop|close>";  // per verb

export async function <verb>({ args, flags }) {
  const woId = args[0];
  if (!woId) { console.log(JSON.stringify({ error: "wo id required" })); process.exit(2); }

  const wo = await resolveWo(woId);
  if (!wo.exists) { console.log(JSON.stringify({ error: `WO not found: ${woId}`, reason: wo.reason })); process.exit(2); }

  const packs = await discoverPacks();
  const pack = packs.find(p => p.id === wo.pack);
  if (!pack) { console.log(JSON.stringify({ error: `Pack '${wo.pack}' not installed` })); process.exit(2); }

  const flowId = selectFlow(pack.manifest, wo);
  if (!flowId) { console.log(JSON.stringify({ error: `no flow for ${wo.schema},${wo.current_state}` })); process.exit(2); }

  const flowFile = path.join(pack.path, "flows", `${flowId}.json`);
  const flow = JSON.parse(await readFile(flowFile, "utf8"));
  if (flow.core_type !== EXPECTED_CORE_TYPE) {
    console.log(JSON.stringify({
      error: `wrong core_type: expected ${EXPECTED_CORE_TYPE}, flow ${flowId} has ${flow.core_type}`,
    }));
    process.exit(2);
  }

  // v0.2 loop verb special-case: refuse and explain
  if (EXPECTED_CORE_TYPE === "loop") {
    console.log(JSON.stringify({
      deferred: true,
      reason: "loop core_type requires child-WO dispatch — Stage 5",
      flow: flowId,
    }));
    process.exit(0);
  }

  // Init harness run
  const runDir = path.join(wo.path, "runs", `run-${Date.now()}`);
  // (init via spawnSync the harness, then loop runNode until finalize)
  // ... (full loop implementation)
}
```

For `loop.mjs`, hard-stop after `EXPECTED_CORE_TYPE` check with the deferred message above.

- [ ] **Step 1 (per verb): Write the failing test** for `brainstorm`/`breakdown`/`close` — each test creates a WO in the matching state, invokes the verb, asserts the WO's `current_state` advanced. For `loop`, the test asserts the deferred-message output and exit code 0.

- [ ] **Step 2 (per verb): Implement the verb module.**

- [ ] **Step 3 (per verb): Confirm test PASS + full suite green.**

- [ ] **Step 4 (per verb): Commit.** One commit per verb: `feat(bf): verb 'brainstorm' (Stage 4 task 4.4c-1)`, then `-2`, `-3`, `-4`.

### 4.4d — `execute` verb (orchestrator)

The "drive it home" verb. Reads WO state, picks the matching flow, runs it to completion, re-reads state, repeats until `current_state == desired_state` or a `loop` core_type is hit (then defers per 4.4c v0.2 behavior).

**Files:**
- Create: `bin/lib/verbs/execute.mjs`
- Create: `test/verbs/test-execute-leaf.sh`

The execute test is the **integration smoke** — creates a `task` WO at state `new`, runs `bf execute <id>`, asserts state ends at `done` (going through `brainstorm-task` → `close-leaf-task`).

- [ ] **Step 1: Write the failing test**

`test/verbs/test-execute-leaf.sh`:

```bash
#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

# Manually create a task WO at state `new`
ID="exec-smoke-test"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: new
desired_state: done
pack: product-engineering
---

# exec smoke test

## Objective
verify execute orchestrator drives a task from new → done end-to-end.

## Boundary
single-leaf task.

## Acceptance criteria
- bf execute finishes without error
- final current_state is 'done'
EOF

# Note: state transitions new → shaped (via brainstorm) → ??? 
# brainstorm-task flow produces shaped; that's not yet "doing".
# v0.2 special: routing has no task,shaped → null → execute exits with hint.
# The test asserts that intermediate behavior is correct AND that re-running
# after manually setting current_state: doing drives close-leaf to PASS.

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
grep -q 'current_state: shaped' "$WO_HOME/$ID/wo.md" || { echo "FAIL: brainstorm did not advance to shaped"; exit 1; }

# Manually flip to doing (v0.2 routing gap — Stage 5 will add the breakdown step)
sed -i 's/current_state: shaped/current_state: doing/' "$WO_HOME/$ID/wo.md"

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
grep -q 'current_state: done' "$WO_HOME/$ID/wo.md" || {
  echo "FAIL: close-leaf-task did not advance to done"
  echo "$OUT"
  exit 1
}

echo "PASS: execute drove new → shaped → (manual) → doing → done"
```

(The manual flip in the middle is honest about v0.2's scope — Stage 5 lands the `breakdown` step for leaf-only tasks that skip the breakdown core_type entirely. The test documents the gap rather than hiding it.)

- [ ] **Step 2: Confirm failure.**

- [ ] **Step 3: Implement** `bin/lib/verbs/execute.mjs`:

```javascript
import path from "node:path";
import { readFile, writeFile } from "node:fs/promises";
import { resolveWo } from "../dispatcher/wo-resolver.mjs";
import { discoverPacks } from "../dispatcher/pack-discovery.mjs";
import { selectFlow } from "../dispatcher/flow-selector.mjs";
import { runNode } from "../dispatcher/node-runner.mjs";
import { spawnSync } from "node:child_process";

const HARNESS = "node bin/bf-harness.mjs";
const MAX_TICKS = 50;

function sh(cmd) {
  const r = spawnSync("bash", ["-c", cmd], { encoding: "utf8" });
  return { code: r.status, stdout: r.stdout.trim(), stderr: r.stderr.trim() };
}

async function runOneFlow(wo, pack, flowId) {
  const flowFile = path.join(pack.path, "flows", `${flowId}.json`);
  const flow = JSON.parse(await readFile(flowFile, "utf8"));
  if (flow.core_type === "loop") {
    return { deferred: true, reason: "loop core_type — Stage 5" };
  }
  const runDir = path.join(wo.path, "runs", `run-${Date.now()}`);
  const initOut = sh(`${HARNESS} init --flow-file ${flowFile} --entry ${flow.nodes[0]} --dir ${runDir} --pack ${pack.path}/pack.json`);
  if (initOut.code !== 0) return { error: initOut.stderr };

  let nodeId = flow.nodes[0];
  for (let i = 0; i < MAX_TICKS; i++) {
    const r = await runNode({
      packPath: pack.path,
      flowFile,
      runDir,
      nodeId,
      transitionToNext: true,
    });
    if (!r.sealed) return { error: r.error };
    if (!r.nextNode) {
      // Terminal; finalize and update WO state
      sh(`${HARNESS} finalize --flow-file ${flowFile} --dir ${runDir}`);
      const newState = flow.produces?.desired_state;
      if (newState) {
        const md = await readFile(path.join(wo.path, "wo.md"), "utf8");
        await writeFile(path.join(wo.path, "wo.md"),
          md.replace(/current_state:\s*\S+/, `current_state: ${newState}`));
      }
      return { finalized: true, terminalNode: nodeId, newState };
    }
    nodeId = r.nextNode;
  }
  return { error: "max ticks exceeded" };
}

export async function execute({ args, flags }) {
  const woId = args[0];
  if (!woId) { console.log(JSON.stringify({ error: "wo id required" })); process.exit(2); }
  const packs = await discoverPacks();
  const maxOuterTicks = flags.maxTicks ? Number(flags.maxTicks) : 10;

  for (let outer = 0; outer < maxOuterTicks; outer++) {
    const wo = await resolveWo(woId);
    if (!wo.exists) { console.log(JSON.stringify({ error: `WO not found` })); process.exit(2); }
    const pack = packs.find(p => p.id === wo.pack);
    if (!pack) { console.log(JSON.stringify({ error: `Pack '${wo.pack}' not installed` })); process.exit(2); }

    if (wo.current_state === (wo.desired_state ?? "done")) {
      console.log(JSON.stringify({ done: true, wo: woId, current_state: wo.current_state }));
      return;
    }

    const flowId = selectFlow(pack.manifest, wo);
    if (!flowId) {
      console.log(JSON.stringify({
        stuck: true,
        wo: woId,
        current_state: wo.current_state,
        hint: `no flow for ${wo.schema},${wo.current_state} — check pack.json.routing`,
      }));
      return;
    }

    const r = await runOneFlow(wo, pack, flowId);
    if (r.error || r.deferred) {
      console.log(JSON.stringify({ ...r, wo: woId, attemptedFlow: flowId }));
      return;
    }
    if (flags.oneStep) {
      console.log(JSON.stringify({ ...r, oneStep: true }));
      return;
    }
  }
  console.log(JSON.stringify({ error: "max outer ticks exceeded" }));
}
```

- [ ] **Step 4: Confirm test PASS + full suite green** (new count: 108 + 6 harness + 4 dispatcher + 1 create + 4 single-flow + 1 execute = 124 passed).

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/verbs/execute.mjs test/verbs/test-execute-leaf.sh
git commit -m "$(cat <<'EOF'
feat(bf): verb 'execute' orchestrator (Stage 4 task 4.4d)

Drives a WO toward desired_state by selecting whichever flow matches
the current (schema, state) pair, running it to completion, then
re-reading state and repeating. v0.2 limits: loop core_type defers
to Stage 5; reaching a routing gap exits with a "stuck" message
naming the missing rule.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.4 wrap-up

- [ ] **Update `UPSTREAM.md`** with a Task 4.4 delta-log row summarizing the 6 verbs + node-runner.
- [ ] Run full suite — expect all 124 tests green.

```bash
git add UPSTREAM.md
git commit -m "docs(bf): UPSTREAM delta for Stage 4 task 4.4 lifecycle verbs"
```

---

## Task 4.5 — Inspection, escape, meta verbs

The catalog's remaining 12 verbs. Each is small (10–80 lines). Group into 3 sub-tasks by category; each sub-task = one commit.

**Files (cumulative):**
- Create: `bin/lib/verbs/{show,tree,list,discard}.mjs` (4 inspection)
- Create: `bin/lib/verbs/escape.mjs` (handles skip / pass / stop / goto / resume; reuses existing `bin/lib/flow-escape.mjs` Core logic)
- Create: `bin/lib/verbs/{pack,flow,help}.mjs` (3 meta)
- Modify: `bin/bf.mjs` (route `skip|pass|stop|goto|resume` to `escape.mjs` via single sub-verb dispatch)
- Create: `test/verbs/test-show-tree-list.sh`, `test/verbs/test-discard.sh`, `test/verbs/test-escape.sh`, `test/verbs/test-pack-flow.sh`, `test/verbs/test-help.sh`

### 4.5a — Inspection verbs: `show`, `tree`, `list`, `discard`

These read or mutate the WO home directly; no flow execution.

- [ ] **Step 1: Write the failing test (covers all 4)** at `test/verbs/test-show-tree-list.sh`:

```bash
#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

# Setup 3 WOs
for i in 1 2 3; do
  mkdir -p "$WO_HOME/wo-$i"
  cat > "$WO_HOME/wo-$i/wo.md" <<EOF
---
schema: task
current_state: $([ $i -eq 1 ] && echo new || echo doing)
desired_state: done
pack: product-engineering
---
# wo-$i
EOF
done

# show
OUT=$(node bin/bf.mjs show wo-1 2>&1)
echo "$OUT" | grep -q "wo-1" || { echo "FAIL: show missing wo-1"; exit 1; }
echo "$OUT" | grep -q "current_state.*new" || { echo "FAIL: show missing state"; exit 1; }

# tree
OUT=$(node bin/bf.mjs tree 2>&1)
echo "$OUT" | grep -q "wo-1" && echo "$OUT" | grep -q "wo-2" && echo "$OUT" | grep -q "wo-3" || { echo "FAIL: tree missing entries"; exit 1; }

# list with state filter
OUT=$(node bin/bf.mjs list --state doing 2>&1)
echo "$OUT" | grep -q "wo-2" || { echo "FAIL: list --state doing missing wo-2"; exit 1; }
echo "$OUT" | grep -q "wo-1" && { echo "FAIL: list --state doing should not include wo-1"; exit 1; }

# discard
node bin/bf.mjs discard wo-3 --force >/dev/null
[ -d "$WO_HOME/wo-3" ] && { echo "FAIL: discard did not remove wo-3"; exit 1; }

echo "PASS: show/tree/list/discard all behave"
```

- [ ] **Step 2: Confirm failure.**

- [ ] **Step 3: Implement** each verb. Shared utility: enumerate `~/.bf/wo/` recursively, find every directory containing `wo.md`, parse front-matter — this can live in `dispatcher/wo-resolver.mjs` (extend with `listWos()`).

**`show.mjs`** — read the WO's `wo.md`, print frontmatter + body. Append a "## Recent runs" section listing the last 5 entries under `runs/`.

**`tree.mjs`** — walk WO home; render as indented tree, each line shows `<id>  [<schema>: <current_state> → <desired_state>]`. Honor `--all` flag: without `--all`, hide WOs at terminal state `done`.

**`list.mjs`** — flat list with `--pack`, `--state`, `--schema` filters.

**`discard.mjs`** — `rm -rf` the WO's directory. Confirm-or-`--force` per `bf-run-commands.md` §7.

- [ ] **Step 4: Wire all 4 verbs into `bin/bf.mjs`** (the dispatcher's dynamic import already handles them once the files exist).

- [ ] **Step 5: Confirm test PASS + full suite green.**

- [ ] **Step 6: Commit.**

```bash
git add bin/lib/verbs/{show,tree,list,discard}.mjs bin/lib/dispatcher/wo-resolver.mjs test/verbs/test-show-tree-list.sh
git commit -m "feat(bf): verbs show/tree/list/discard (Stage 4 task 4.5a)"
```

### 4.5b — Escape verbs: `skip`, `pass`, `stop`, `goto`, `resume`

All five operate on the currently active flow run. The Core logic already lives in `bin/lib/flow-escape.mjs` (vendored from OPC). The dispatcher's job is to read "what is the active run" from the WO + most-recent `runs/run-*/` and forward the verb to flow-escape.

- [ ] **Step 1: Write the failing test** `test/verbs/test-escape.sh`:

```bash
#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

# Create a WO + start a run, then `bf stop` it
ID="escape-test"
mkdir -p "$WO_HOME/$ID/runs/run-1/nodes/implement/run_1"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: doing
desired_state: done
pack: product-engineering
---
# escape test
EOF

# stub a flow-state.json so flow-escape has something to work on
cat > "$WO_HOME/$ID/runs/run-1/flow-state.json" <<EOF
{"flow":"close-leaf-task","currentNode":"implement","status":"in_progress"}
EOF

OUT=$(node bin/bf.mjs stop "$ID" 2>&1)
echo "$OUT" | grep -q '"stopped":true' || { echo "FAIL: stop did not report success"; echo "$OUT"; exit 1; }

# goto
OUT=$(node bin/bf.mjs goto code-review --wo "$ID" 2>&1) || true
# loose assertion: goto either accepts and prints node, or errors with "cycle limit" / "unknown node" — both are valid v0.2 behavior
echo "$OUT" | grep -q -E 'code-review|cycle limit|unknown node' || { echo "FAIL: goto produced unexpected output: $OUT"; exit 1; }

echo "PASS: escape verbs route to flow-escape"
```

- [ ] **Step 2: Implement** `bin/lib/verbs/escape.mjs`:

```javascript
import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { resolveWo } from "../dispatcher/wo-resolver.mjs";

async function activeRunDir(woPath) {
  const runs = path.join(woPath, "runs");
  const entries = await readdir(runs).catch(() => []);
  const runDirs = entries.filter(e => e.startsWith("run-")).sort();
  return runDirs.length ? path.join(runs, runDirs[runDirs.length - 1]) : null;
}

function sh(cmd) {
  const r = spawnSync("bash", ["-c", cmd], { encoding: "utf8" });
  return r.stdout.trim() || r.stderr.trim();
}

export async function skip({ args, flags }) { return forward("skip", args, flags); }
export async function pass({ args, flags }) { return forward("pass", args, flags); }
export async function stop({ args, flags }) { return forward("stop", args, flags); }
export async function goto({ args, flags }) { return forward("goto", args, flags); }
export async function resume({ args, flags }) { return forward("resume", args, flags); }

async function forward(sub, args, flags) {
  const woId = flags.wo ?? args.find(a => !a.startsWith("--")) ?? null;
  // Resume needs no wo arg; others need one
  if (sub === "resume" && !woId) {
    // pick most recent active WO across home
    console.log(JSON.stringify({ error: "resume without wo: not yet implemented (Stage 5)" }));
    process.exit(2);
  }
  if (!woId) { console.log(JSON.stringify({ error: `${sub} requires wo id` })); process.exit(2); }
  const wo = await resolveWo(woId);
  if (!wo.exists) { console.log(JSON.stringify({ error: "wo not found" })); process.exit(2); }
  const runDir = await activeRunDir(wo.path);
  if (!runDir) { console.log(JSON.stringify({ error: "no active run for wo" })); process.exit(2); }

  // bf-harness already implements these sub-verbs in flow-escape; just forward
  const extra = sub === "goto" ? args.filter(a => a !== woId).join(" ") : "";
  const out = sh(`node bin/bf-harness.mjs ${sub} --dir ${runDir} ${extra}`);
  console.log(out);
}
```

- [ ] **Step 3: Route in `bin/bf.mjs`**:

```diff
- const mod = await import(`./lib/verbs/${verb}.mjs`);
- await mod[verb]({ args, flags });
+ const escapeVerbs = new Set(["skip","pass","stop","goto","resume"]);
+ const modPath = escapeVerbs.has(verb) ? "./lib/verbs/escape.mjs" : `./lib/verbs/${verb}.mjs`;
+ const mod = await import(modPath);
+ await mod[verb]({ args, flags });
```

- [ ] **Step 4: Confirm test PASS + full suite green.**

- [ ] **Step 5: Commit.**

```bash
git add bin/lib/verbs/escape.mjs bin/bf.mjs test/verbs/test-escape.sh
git commit -m "feat(bf): escape verbs skip/pass/stop/goto/resume (Stage 4 task 4.5b)"
```

### 4.5c — Meta verbs: `pack`, `flow`, `help`

- [ ] **Step 1: Write the failing test** `test/verbs/test-pack-flow.sh`:

```bash
#!/usr/bin/env bash
set -e

OUT=$(node bin/bf.mjs pack list 2>&1)
echo "$OUT" | grep -q 'product-engineering' || { echo "FAIL: pack list missing product-engineering"; exit 1; }

OUT=$(node bin/bf.mjs pack info product-engineering 2>&1)
echo "$OUT" | grep -q '"version":"1.0.0-alpha"' || { echo "FAIL: pack info missing version"; exit 1; }

OUT=$(node bin/bf.mjs flow list product-engineering 2>&1)
echo "$OUT" | grep -q 'close-leaf-task' || { echo "FAIL: flow list missing close-leaf-task"; exit 1; }

OUT=$(node bin/bf.mjs flow viz brainstorm-task 2>&1)
echo "$OUT" | grep -q 'discuss' || { echo "FAIL: flow viz did not render nodes"; exit 1; }

echo "PASS: pack/flow meta verbs work"
```

`test/verbs/test-help.sh`:

```bash
#!/usr/bin/env bash
set -e
OUT=$(node bin/bf.mjs help 2>&1)
echo "$OUT" | grep -q 'execute' || { echo "FAIL: help missing 'execute' verb"; exit 1; }
echo "$OUT" | grep -q 'create' || { echo "FAIL: help missing 'create' verb"; exit 1; }
OUT=$(node bin/bf.mjs help execute 2>&1)
echo "$OUT" | grep -q -i 'desired_state' || { echo "FAIL: help execute missing semantic hint"; exit 1; }
echo "PASS: help and help <verb> work"
```

- [ ] **Step 2: Implement**

**`pack.mjs`** — sub-verbs `list` (uses `discoverPacks()`, prints table) and `info <id>` (full manifest dump).

**`flow.mjs`** — sub-verbs `list [<pack>]` (read `pack.manifest.flows`) and `viz <flow-id>` (forward to `bf-harness viz --flow-file <pack>/flows/<id>.json`).

**`help.mjs`** — top-level prints the verb catalog (one line per verb from a static table); `help <verb>` prints that verb's grammar + flags. Pull strings from a single `VERB_DOCS = {...}` object so the table and per-verb output stay in sync.

- [ ] **Step 3: Confirm both tests PASS + full suite green.**

- [ ] **Step 4: Commit (one commit for the three).**

```bash
git add bin/lib/verbs/{pack,flow,help}.mjs test/verbs/test-pack-flow.sh test/verbs/test-help.sh
git commit -m "feat(bf): meta verbs pack/flow/help (Stage 4 task 4.5c)"
```

### 4.5 wrap-up

- [ ] **Update `UPSTREAM.md`** Task 4.5 delta-log row (12 verbs).
- [ ] Full suite expected: 128–130 passed (depending on how the 4.5a test bundles cases). Adjust expected count in any commit message that cites it.

```bash
git add UPSTREAM.md
git commit -m "docs(bf): UPSTREAM delta for Stage 4 task 4.5 inspection/escape/meta verbs"
```

---

## Task 4.6 — NL parse front-end

User input that doesn't start with a known verb is treated as natural language. The dispatcher prints a transcribed verb form first, then re-enters the verb-first path.

**v0.2 strategy:** the NL parser is a thin wrapper. Inside Claude Code (the runtime context this whole skill lives in), the LLM that's executing `bf` already sees the user message. The wrapper's job is: print the transcribed verb, ask the LLM to either auto-confirm (default) or ask for user confirmation if `--confirm` is set. Outside Claude Code (e.g. CI invocations of `bf`), NL mode is disabled and unknown verbs error with a help hint.

The mechanical part of NL → verb is a simple deterministic mapping for the common patterns; LLM only runs when the deterministic pass doesn't match. This keeps tests reproducible (the deterministic pass is what the test asserts).

**Files:**
- Create: `bin/lib/dispatcher/nl-parse.mjs`
- Modify: `bin/bf.mjs` (route unknown verbs to NL)
- Create: `test/verbs/test-nl-parse-stub.sh`

- [ ] **Step 1: Write the failing test**

`test/verbs/test-nl-parse-stub.sh`:

```bash
#!/usr/bin/env bash
set -e

# Deterministic patterns only — no LLM call
expect_transcribe() {
  local input="$1"
  local expected_verb="$2"
  OUT=$(node -e "
    import('./bin/lib/dispatcher/nl-parse.mjs').then(m => {
      const r = m.transcribeDeterministic(${input});
      console.log(JSON.stringify(r));
    });
  ")
  echo "$OUT" | grep -q "\"verb\":\"$expected_verb\"" || {
    echo "FAIL: '$input' did not transcribe to '$expected_verb' (got: $OUT)"
    exit 1
  }
}

expect_transcribe '["show","auth-v1"]'                    show
expect_transcribe '["tree"]'                              tree
expect_transcribe '["list","--state","doing"]'            list
# Mixed-case / unknown verb → null (LLM would handle)
OUT=$(node -e "
  import('./bin/lib/dispatcher/nl-parse.mjs').then(m => {
    const r = m.transcribeDeterministic(['帮我搞定','auth-v1']);
    console.log(JSON.stringify(r));
  });
")
echo "$OUT" | grep -q '"verb":null' || { echo "FAIL: non-deterministic input should return null"; exit 1; }

echo "PASS: deterministic NL transcription"
```

- [ ] **Step 2: Confirm failure.**

- [ ] **Step 3: Implement** `bin/lib/dispatcher/nl-parse.mjs`:

```javascript
// Tiny deterministic mapping for the obvious cases. LLM-driven transcription
// happens at the surrounding skill layer (the `bf` Claude Code skill calls
// out to the host LLM when this returns {verb: null}).
//
// v0.2: keep this small. Stage 5 demo will populate more patterns
// as we see real user input.

const KNOWN_VERBS = new Set([
  "execute", "create", "brainstorm", "breakdown", "loop", "close",
  "show", "tree", "list", "discard",
  "skip", "pass", "stop", "goto", "resume",
  "pack", "flow", "help",
]);

export function transcribeDeterministic(argv) {
  if (argv.length === 0) return { verb: "help", args: [], flags: {} };
  const first = argv[0].toLowerCase();
  if (KNOWN_VERBS.has(first)) {
    // Not actually NL — caller should use verb-first parser
    return { verb: first, args: argv.slice(1), flags: {}, source: "verb-match" };
  }
  // No other deterministic patterns in v0.2; signal LLM-needed
  return { verb: null, args: argv, flags: {}, source: "needs-llm" };
}

// Stage 5 will add: async function transcribeViaLlm(argv) {...} — invokes the
// surrounding Claude skill / API for free-form parsing.
```

- [ ] **Step 4: Wire** `bin/bf.mjs` to call `transcribeDeterministic` when `parseArgs` returns `knownVerb: false`. If transcription returns a verb, print a single line like `[bf] transcribed: bf <verb> <args>` then re-dispatch. If it returns `{verb: null}`, print the "needs LLM" hint and exit 2 (Stage 5 will replace the hint with a real LLM call).

```diff
- if (verb === "help" || !knownVerb) {
+ if (verb === "help") { ... handle help ... }
+ if (!knownVerb) {
+   const nl = await import("./lib/dispatcher/nl-parse.mjs");
+   const t = nl.transcribeDeterministic(process.argv.slice(2));
+   if (t.verb && t.source !== "needs-llm") {
+     console.error(`[bf] transcribed: bf ${t.verb} ${t.args.join(" ")}`);
+     const mod = await import(`./lib/verbs/${t.verb}.mjs`);
+     await mod[t.verb]({ args: t.args, flags: t.flags });
+     return;
+   }
+   console.log(JSON.stringify({
+     error: `Unknown verb '${verb}'. Natural-language parsing requires Claude Code skill context; CLI usage requires a verb. Run 'bf help' for the catalog.`,
+   }));
+   process.exit(2);
+ }
```

- [ ] **Step 5: Confirm test PASS + full suite green.**

- [ ] **Step 6: Commit.**

```bash
git add bin/lib/dispatcher/nl-parse.mjs bin/bf.mjs test/verbs/test-nl-parse-stub.sh
git commit -m "$(cat <<'EOF'
feat(bf): NL parse front-end (deterministic v0.2, LLM-deferred to Stage 5)

Stage 4 task 4.6. Routes unknown first-token through nl-parse.mjs. v0.2
ships only the deterministic mapping (matches verbs that happened to
arrive case-mangled or after extra noise). Returns null for inputs that
need LLM transcription — the surrounding `bf` Claude Code skill will
later wrap that case; CLI users get a usable error pointing at the
verb catalog.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.6 wrap-up

- [ ] Update `UPSTREAM.md` Task 4.6 row. Single commit.

```bash
git add UPSTREAM.md
git commit -m "docs(bf): UPSTREAM delta for Stage 4 task 4.6 NL parse"
```

---

## Task 4.7 — Packaging dry-run + README

Confirm the npm package is shippable without actually publishing. Update install/use docs to match the verbs that now exist.

**Files:**
- Modify: `package.json` (bump version, add `publishConfig`, expand `files`)
- Modify: `scripts/postinstall.mjs` (include new `bin/lib/verbs/` and `bin/lib/dispatcher/` trees in the skill-install copy)
- Modify: `README.md` (replace placeholder with real install + usage section)
- Create: `test/test-package-dryrun.sh` (asserts `npm pack --dry-run` produces the expected file list)

### 4.7a — Version bump + publishConfig

- [ ] **Step 1: Inspect current `package.json`**

```bash
cat package.json
```

Note the current `version`, `files`, presence/absence of `publishConfig`.

- [ ] **Step 2: Bump version, add `publishConfig`, expand `files`**

Apply diff to `package.json`:

```diff
   "name": "@codetreker/bf",
-  "version": "0.1.0-alpha",
+  "version": "0.2.0-alpha",
   ...
+  "publishConfig": {
+    "access": "public"
+  },
   "files": [
     "bin",
     "scripts",
     "SKILL.md",
     "roles",
     "references",
     "pipeline",
     "packs",
     "test",
     "UPSTREAM.md",
     "README.md"
   ],
```

(`bin/` is already included → `bin/lib/verbs/` and `bin/lib/dispatcher/` ride along automatically. Double-check by running `npm pack --dry-run` in Step 4.)

- [ ] **Step 3: Update `scripts/postinstall.mjs`**

Verify the postinstall copy step grabs the new directory trees. If it uses an explicit allowlist, add `bin/lib/verbs/` and `bin/lib/dispatcher/`. If it copies `bin/` wholesale, no change needed.

```bash
cat scripts/postinstall.mjs | grep -E "bin|lib|verbs|dispatcher"
```

- [ ] **Step 4: Run `npm pack --dry-run`**

```bash
npm pack --dry-run 2>&1 | tail -40
```

Expected: file list includes `bin/bf.mjs`, `bin/bf-harness.mjs`, `bin/lib/verbs/*.mjs`, `bin/lib/dispatcher/*.mjs`, `packs/product-engineering/{pack.json,flows/*,protocols/*,schemas/*,roles/*}`, `pipeline/*.md`, `roles/*.md`, `references/*.md`, `SKILL.md`, `scripts/postinstall.mjs`, `README.md`, `UPSTREAM.md`, `test/`. No node_modules, no `.harness/`, no `.bf-demo/`, no large junk.

- [ ] **Step 5: Write a regression test**

`test/test-package-dryrun.sh`:

```bash
#!/usr/bin/env bash
set -e
OUT=$(npm pack --dry-run 2>&1)

# Must include
for required in "bin/bf.mjs" "bin/bf-harness.mjs" "bin/lib/verbs/" "bin/lib/dispatcher/" \
                "packs/product-engineering/pack.json" "packs/product-engineering/flows/" \
                "packs/product-engineering/protocols/" "pipeline/" "roles/" "references/" \
                "SKILL.md" "scripts/postinstall.mjs" "README.md"; do
  echo "$OUT" | grep -q "$required" || { echo "FAIL: missing $required from npm pack output"; exit 1; }
done

# Must NOT include
for excluded in "node_modules" ".bf-demo" ".harness/"; do
  echo "$OUT" | grep -q "$excluded" && { echo "FAIL: $excluded should not be in pack"; exit 1; }
done

# Total tarball size sanity (under 2 MB — adjust if pack content legitimately grows)
SIZE_LINE=$(echo "$OUT" | grep -E "package size|unpacked size" | head -1)
echo "Pack size: $SIZE_LINE"

echo "PASS: npm pack --dry-run produces expected file list"
```

- [ ] **Step 6: Run the test.**

```bash
bash test/test-package-dryrun.sh
```

If any "must include" fails, fix `files` in `package.json`. If any "must NOT include" fails, add it to `.npmignore` (create the file if missing).

- [ ] **Step 7: Full suite green** (`bash test/run-all.sh 2>&1 | tail -3`).

- [ ] **Step 8: Commit.**

```bash
git add package.json scripts/postinstall.mjs test/test-package-dryrun.sh .npmignore
git commit -m "$(cat <<'EOF'
chore(bf): bump to 0.2.0-alpha + npm pack regression test

Stage 4 task 4.7a. Version bump signals the dispatcher landed.
Adds publishConfig.access=public so future `npm publish` doesn't
require an explicit flag. test/test-package-dryrun.sh asserts the
tarball's file list — catches accidental omissions (e.g. forgetting
to extend `files` after adding a new bin/lib subdirectory).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 4.7b — README rewrite

Replace the install/use placeholder with a real install path and a tour of the verbs that now exist.

- [ ] **Step 1: Inspect current README**

```bash
cat README.md | head -80
```

- [ ] **Step 2: Rewrite install + usage sections**

Replace the corresponding sections with:

```markdown
## Install

### As a Claude Code skill (recommended)

```bash
npm install -g @codetreker/bf
```

postinstall copies the skill into `~/.claude/skills/bf/`. From inside
Claude Code you can then invoke:

```
/bf execute <wo-id>
/bf help
```

### As a CLI (no Claude Code)

The `bf` binary works standalone for everything except natural-language
mode (which needs the surrounding Claude Code LLM):

```bash
bf help
bf create "implement v1 auth" --pack product-engineering
bf show auth-v1
bf tree
```

## Usage tour (v0.2-alpha)

`bf` is verb-first. The 18 verbs group by purpose:

| Group | Verbs | Notes |
|---|---|---|
| Lifecycle | `create`, `execute`, `brainstorm`, `breakdown`, `loop`, `close` | `execute` drives a WO to its `desired_state`; the 4 specific verbs run one core flow each |
| Inspection | `show`, `tree`, `list`, `discard` | Read or remove the WO home (`~/.bf/wo/`) |
| Escape | `skip`, `pass`, `stop`, `goto`, `resume` | Operate on the currently active run |
| Meta | `pack`, `flow`, `help` | Inspect installed Packs / flows / usage |

### Driving a task through

```bash
bf create "shape login form acceptance" --pack product-engineering --schema task
# → creates ~/.bf/wo/shape-login-form-acceptance/wo.md at state 'new'

bf execute shape-login-form-acceptance
# → walks brainstorm-task flow; ends at state 'shaped'

# (Stage 4 v0.2 limitation: leaf tasks go from shaped → doing manually
# until the Stage 5 demo lands the leaf-fast-path.)
vim ~/.bf/wo/shape-login-form-acceptance/wo.md  # set current_state: doing

bf execute shape-login-form-acceptance
# → walks close-leaf-task flow; ends at state 'done'
```

### Status (Stage 4 v0.2)

- ✅ verb-first dispatch (all 18 verbs)
- ✅ harness-level mechanics (init, seal, transition, finalize, viz with back-edges)
- ✅ packs-relative flow loading (no global flow registry needed)
- ✅ `npm pack --dry-run` clean
- ⚠️ stub agent dispatch (every role's eval is auto-PASS; Stage 5 plumbs real Claude subagent calls)
- ⚠️ `loop` verb defers with a "child-WO dispatch — Stage 5" message
- ⚠️ NL parse handles deterministic patterns only; LLM-driven transcription deferred
- ⏳ not yet `npm publish`-ed; first publish lands when Stage 5 demo succeeds end-to-end
```

(Adjust if the README has existing sections that should stay.)

- [ ] **Step 3: Verify README renders well**

```bash
markdown-link-check README.md 2>/dev/null || true  # optional
wc -l README.md
```

- [ ] **Step 4: Commit.**

```bash
git add README.md
git commit -m "docs(bf): README install + usage tour for v0.2-alpha (Stage 4 task 4.7b)"
```

### 4.7 wrap-up

- [ ] Update `UPSTREAM.md` Task 4.7 row. Single commit.

---

## Task 4.8 — Stage 4 retro + Stage 5 punch list

Stage 4 inevitably surfaces gaps the plan didn't predict. Capture them in a retro doc and hand off a punch list to Stage 5.

**Files:**
- Create: `docs/specs/2026-05-17-stage-4-retro.md`
- Append: `docs/specs/2026-05-16-bf-fork-design/core-contracts.md` (any new Open items)

- [ ] **Step 1: Run the cross-verb regression**

Create `test/test-stage4-regression.sh`:

```bash
#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

# create → show → execute → show → discard
node bin/bf.mjs create "regression task" --pack product-engineering --schema task >/dev/null
ID=$(ls "$WO_HOME")  # the one we just created
node bin/bf.mjs show "$ID" | grep -q 'current_state' || { echo "FAIL: show after create"; exit 1; }
node bin/bf.mjs execute "$ID" >/dev/null 2>&1 || true   # may stop at routing gap; that's OK for regression
node bin/bf.mjs tree | grep -q "$ID" || { echo "FAIL: tree after execute"; exit 1; }
node bin/bf.mjs discard "$ID" --force >/dev/null
[ -d "$WO_HOME/$ID" ] && { echo "FAIL: discard"; exit 1; }
echo "PASS: create→show→execute→tree→discard regression"
```

- [ ] **Step 2: Author the retro doc** `docs/specs/2026-05-17-stage-4-retro.md`:

```markdown
# Stage 4 Retrospective

> Captures what worked, what stayed broken, and what Stage 5 demo
> needs to address. Companion to the Stage 4 plan
> (docs/specs/2026-05-17-bf-stage-4-dispatcher-plan.md).

## What's working

- [list every verb that the per-verb test suite confirms behaves]
- [harness changes per 4.2a–4.2f all green; cite commit SHAs]
- [npm pack --dry-run produces clean tarball]

## What stayed broken

For each unresolved item, document:
- the symptom (what happens when you hit it)
- the workaround (if any)
- the file/finding it traces back to

## Stage 5 must-do list

Carried forward from Stage 3 (still relevant) + Stage 4 discoveries:

- [ ] Real agent dispatch (replace node-runner's stub eval emitter with Claude subagent calls)
- [ ] Child-run dispatch for `loop.dispatch-children` (Stage 3 finding §251)
- [ ] Per-WO live-state file (Stage 3 finding §251)
- [ ] Structured edge payloads `{verdict, scope}` (Stage 3 finding §252)
- [ ] Loop-type-aware default budgets (Stage 3 finding §253)
- [ ] LLM-driven NL transcription (replace nl-parse stub)
- [ ] [add Stage 4 discoveries here]

## Stage 5 demo target

End-to-end driving: brainstorm `create "implement auth login form"`,
verify brainstorm produces a shaped task with real acceptance criteria
written by a real role-evaluator agent, then `close` drives it to done.

## Test result

`bash test/run-all.sh` → [final count, e.g. 130 files passed, 0 files failed, 1 deferred].
```

- [ ] **Step 3: Append new Open items to `core-contracts.md`**

Any cross-cutting limitation that surfaced (e.g. "WO front-matter parser is line-based — doesn't handle multi-line YAML values") goes here as a bullet under the right contract's `## Open` section, citing the commit/test that exposed it.

- [ ] **Step 4: Full suite green** + run `test-stage4-regression.sh`.

```bash
bash test/run-all.sh 2>&1 | tail -3
bash test/test-stage4-regression.sh
```

- [ ] **Step 5: Commit.**

```bash
git add docs/specs/2026-05-17-stage-4-retro.md docs/specs/2026-05-16-bf-fork-design/core-contracts.md test/test-stage4-regression.sh
git commit -m "$(cat <<'EOF'
docs(spec): Stage 4 retro + Stage 5 punch list

Captures Stage 4 outcomes: which verbs work end-to-end with stub
agents, which findings carry forward, and the must-do list for Stage 5
demo (real agent dispatch + child-run dispatch + the remaining
Stage 3 findings that weren't blockers for Stage 4's scope).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Stage 4 Definition of Done

- [ ] **Verb dispatch works** — `bf <verb> ...` for every verb in the catalog: invokes the right module, returns expected output. Tested by per-verb scripts under `test/verbs/`.
- [ ] **`bf execute` drives a leaf task end-to-end with stub agents** — `test/verbs/test-execute-leaf.sh` green. (Stage 5 replaces stubs with real agents — that's not gated by this Stage.)
- [ ] **Harness hardening complete** — all 6 sub-tasks in 4.2 land; their tests under `test/harness-hardening/` all PASS.
- [ ] **`/opc` strings swept** — `grep -rn '/opc ' bin/lib/` returns empty.
- [ ] **`npm pack --dry-run` clean** — `test/test-package-dryrun.sh` PASS; tarball contains the expected file list and excludes node_modules / .bf-demo / .harness.
- [ ] **README reflects shipped behavior** — install + usage tour names every verb; calls out v0.2 limitations honestly.
- [ ] **Test suite at expected count** — `bash test/run-all.sh` shows roughly 130 passed / 0 failed / 1 deferred (108 baseline + 6 harness + 4 dispatcher + 1 create + 4 single-flow + 1 execute + 4–5 inspection/escape/meta + 1 NL + 1 pack-dryrun + 1 regression = ~131). Exact count depends on how Step bundles plays out — record actual.
- [ ] **All UPSTREAM.md delta-log rows written** — one per task (4.1, 4.2 wrap, 4.3 wrap, 4.4 wrap, 4.5 wrap, 4.6 wrap, 4.7 wrap).
- [ ] **Stage 4 retro doc shipped** — `docs/specs/2026-05-17-stage-4-retro.md` lists what carried forward into Stage 5.

## Self-Review Notes (for plan author after drafting)

- [ ] Spec coverage: every must-do in `2026-05-17-stage-3-demo-trace.md` § "Stage 4 must-do list" either has a task or is in § Out of Scope below.
- [ ] All file paths are absolute relative to repo root (`bin/lib/verbs/create.mjs`, not `./create.mjs`).
- [ ] No "TBD" / "fill in details" / "add appropriate validation" — every step has either complete code or a precise command.
- [ ] Type / name consistency:
  - `parseArgs` returns `{verb, args, flags, knownVerb}` everywhere
  - `discoverPacks()` returns `[{id, version, path, manifest}, ...]` consistently
  - `resolveWo(id)` returns `{exists, path, schema, current_state, pack, reason?}` consistently
  - `selectFlow(manifest, wo)` returns flow id string or `null`
  - `runNode({packPath, flowFile, runDir, nodeId, transitionToNext})` returns `{sealed, verdict, nextNode, transitioned?, error?}` consistently
- [ ] Brand: every new file uses `bf-harness` / `bf` / `.bf/` / `~/.bf/` consistently — no `opc-harness` leaks.
- [ ] Stage 3 dependencies cited where relevant (e.g. 4.2a refers to commit `34ebb5e` — that's the Stage 3 demo trace commit).

## Out of Scope (deferred to Stage 5+)

Three of the 17 Stage 3 must-do items are explicitly NOT addressed here:

1. **Child-run dispatch for `loop.dispatch-children`** — needs a real "node spawns child runs" primitive in `bf-harness`. v0.2 short-circuits at `loop` core_type.
2. **Per-WO live-state file** — requires a polling/notify protocol design (in-process vs file-watch). Defer to Stage 5 demo input.
3. **Structured edge payloads `{verdict, scope}`** — depends on having a real loop run to exercise the semantics. Defer to Stage 5.

Additionally:

- **Real LLM-driven NL transcription** (Stage 4's NL is deterministic-only)
- **`npm publish`** (Stage 4 stops at dry-run; first publish gated on Stage 5 demo success)
- **Schema completeness check at dispatcher init** (Stage 3 finding §474 — added as Stage 5 nice-to-have; v0.2 just errors at `execute` time with a clear "no flow for X,Y" message instead)
- **Sibling-Pack npm discovery** (`pack-discovery` scans repo-local only; sibling npm scan is v0.3)
- **`bf-harness create-child-wo` primitive** (Stage 3 finding §254 — same as child-run dispatch)
- **Loop-type-aware default budgets** (defer with the child-run work)
- **PR-lifecycle hook** (Stage 3 finding §477 — out of scope for the dispatcher itself; lives in a future `bf-git-bridge` Pack)

These appear as `## Stage 5 must-do list` bullets in the retro doc.
