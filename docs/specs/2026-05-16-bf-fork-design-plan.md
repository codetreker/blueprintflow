# BF Fork OPC — Stage 1 + Stage 2 Implementation Plan

> **Status (2026-05-17):** This plan has been executed. Paths and structure below reflect the **original plan** as written (`plugins/bf/...`). The actual implementation reorganized into bare-skill + npm form (bf content lives at repo root, distributed as `@codetreker/bf` on npm) — see the main spec § Repository layout and UPSTREAM.md delta log for the final layout. Paths in this plan are kept as-was for traceability; refer to the spec for the current shape.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor OPC's harness execution core into `plugins/bf/runtime/`, apply brand renames, get the full OPC test suite green under the new names, and author the 5 BF Core contract docs.

**Architecture:** Two stages. Stage 1 is mechanical: copy OPC `bin/` into `plugins/bf/runtime/`, rename brand strings (`opc-harness` → `bf-harness`, `.harness/` → `.bf/`, etc.), keep generic vocabulary (flow / node / verdict / handshake / gate / route / transition / `synthesize`). Stage 2 writes the 5 contract markdown files into `plugins/bf/core/`, drafted from `docs/specs/2026-05-16-bf-fork-design/core-contracts.md`. No Pack work in this plan — that comes in Stage 3 in a separate plan.

**Tech Stack:** Node 18+, Bash, file-based state (JSON / Markdown). No build step, no npm deps in core runtime.

**Source of truth for design decisions:** `docs/specs/2026-05-16-bf-fork-design.md` and `docs/specs/2026-05-16-bf-fork-design/*.md`. When this plan and the spec disagree, the spec wins; update the plan inline.

**Worktree:** Work is being done in `.claude/worktrees/bf-fork-spec/` on branch `worktree-bf-fork-spec`. All file paths below are relative to that worktree root.

---

## File Structure Overview

```
plugins/bf/                                ← NEW: the bf plugin
├── .claude-plugin/plugin.json             ← marketplace metadata
├── runtime/                               ← vendored from /workspace/opc/bin
│   ├── bf-harness.mjs                     ← renamed from opc-harness.mjs
│   └── lib/                               ← all 40 files from opc/bin/lib
├── core/                                  ← 5 contract docs (Stage 2)
│   ├── work-object.md
│   ├── flow.md
│   ├── gate.md
│   ├── wo-home.md
│   └── pack.md
├── roles/                                 ← empty for v1 (populated in later plan)
├── skills/                                ← empty for v1
├── packs/                                 ← empty for v1
├── test/                                  ← vendored from /workspace/opc/test
│   ├── run-all.sh
│   ├── test-*.sh                          ← 111 test scripts
│   └── fixtures/
└── UPSTREAM.md                            ← fork point + delta log

.claude-plugin/marketplace.json             ← UPDATED: add bf plugin entry
```

**Not touched in this plan:**
- `plugins/blueprintflow/` (the v6.0.0 plugin) — left as-is; moved into `plugins/bf/packs/product-engineering/` in Stage 3 plan
- `docs/specs/` content — already authored; this plan reads from it but does not modify it

---

## Stage 1 — Vendor + Rename + Tests Green

### Task 1.1: Create `plugins/bf/` skeleton + plugin manifest

**Files:**
- Create: `plugins/bf/.claude-plugin/plugin.json`
- Create: `plugins/bf/roles/.gitkeep`
- Create: `plugins/bf/skills/.gitkeep`
- Create: `plugins/bf/packs/.gitkeep`

- [ ] **Step 1: Create directories**

```bash
mkdir -p plugins/bf/.claude-plugin plugins/bf/roles plugins/bf/skills plugins/bf/packs plugins/bf/core
touch plugins/bf/roles/.gitkeep plugins/bf/skills/.gitkeep plugins/bf/packs/.gitkeep
```

- [ ] **Step 2: Write plugin manifest**

Write `plugins/bf/.claude-plugin/plugin.json`:

```json
{
  "name": "bf",
  "version": "0.1.0-alpha",
  "description": "Blueprintflow — general evidence-gated work loop framework. BF Core + runtime; Packs (e.g. product-engineering) live under bf/packs/."
}
```

- [ ] **Step 3: Verify**

```bash
cat plugins/bf/.claude-plugin/plugin.json
ls plugins/bf/
```

Expected: prints the JSON; `ls` shows `.claude-plugin/  core/  packs/  roles/  skills/`.

- [ ] **Step 4: Commit**

```bash
git add plugins/bf/
git commit -m "feat(bf): scaffold plugins/bf/ skeleton

Empty bf plugin directory with .claude-plugin/plugin.json and placeholder
subdirs (core/ roles/ skills/ packs/). Subsequent tasks vendor the OPC
harness into runtime/ and write Core contract docs into core/."
```

---

### Task 1.2: Vendor OPC `bin/` and `test/` into the plugin (verbatim copy)

**Files:**
- Create: `plugins/bf/runtime/opc-harness.mjs` (verbatim copy)
- Create: `plugins/bf/runtime/lib/*.mjs` (40 files, verbatim copies)
- Create: `plugins/bf/test/run-all.sh` and `test-*.sh` (110 scripts + helpers + fixtures, verbatim)
- Create: `plugins/bf/UPSTREAM.md`

Source: `/workspace/opc/bin/` and `/workspace/opc/test/`. We deliberately do **NOT** rename in this task — that's task 1.3. Step 1 of the rename must follow a known-clean vendor commit.

We also explicitly **exclude** these files (not part of Core runtime; see spec § "NOT taken from OPC"):
- `bin/opc.mjs` (slash-command dispatcher — bf-run replaces it; deferred to Stage 4 plan)
- `bin/opc-report.mjs` (HTML report — defer to v2)
- `bin/replay-viewer.html` (defer to v2)
- `bin/replay-open.sh` (defer to v2)
- `bin/hooks/` (PreCompact/PostCompact — defer to v2)

- [ ] **Step 1: Capture OPC source commit SHA**

```bash
( cd /workspace/opc && git rev-parse HEAD ) > /tmp/opc-fork-sha
cat /tmp/opc-fork-sha
```

Expected: a 40-char SHA. Save the value; we'll embed it in `UPSTREAM.md` in step 5.

- [ ] **Step 2: Vendor `bin/opc-harness.mjs` and `bin/lib/`**

```bash
mkdir -p plugins/bf/runtime/lib
cp /workspace/opc/bin/opc-harness.mjs plugins/bf/runtime/opc-harness.mjs
cp /workspace/opc/bin/lib/*.mjs plugins/bf/runtime/lib/
```

- [ ] **Step 3: Vendor the test suite**

```bash
mkdir -p plugins/bf/test
cp /workspace/opc/test/run-all.sh plugins/bf/test/
cp /workspace/opc/test/test-*.sh plugins/bf/test/
[ -d /workspace/opc/test/fixtures ] && cp -r /workspace/opc/test/fixtures plugins/bf/test/
```

- [ ] **Step 4: Sanity-count the copied files**

```bash
ls plugins/bf/runtime/lib/*.mjs | wc -l
ls plugins/bf/test/test-*.sh | wc -l
```

Expected: `40` and `110` respectively. If counts differ, investigate before continuing (OPC may have changed; update UPSTREAM.md accordingly).

- [ ] **Step 5: Write `UPSTREAM.md`**

Write `plugins/bf/UPSTREAM.md` (replace `<SHA>` with the value from step 1):

```markdown
# UPSTREAM — OPC Fork Provenance

BF's `runtime/` and `test/` directories were vendored from OPC at the fork point below. We do not auto-pump from upstream; cherry-picks are documented in the delta log.

## Fork point

- Source: https://github.com/iamtouchskyer/opc (local clone at `/workspace/opc`)
- Commit: <SHA>
- HARNESS_VERSION at fork: 0.10.0 (see runtime/lib/flow-templates.mjs)
- Files vendored verbatim:
  - `bin/opc-harness.mjs` → `runtime/opc-harness.mjs` (renamed in delta below)
  - `bin/lib/*.mjs` (40 files) → `runtime/lib/*.mjs`
  - `test/run-all.sh` + `test/test-*.sh` (110 scripts) + `test/test-helpers.sh` + `test/fixtures/`

## Files explicitly NOT vendored

- `bin/opc.mjs` — slash-command dispatcher, replaced by `bf-run` skill (Stage 4 plan)
- `bin/opc-report.mjs` — HTML report, deferred to v2
- `bin/replay-viewer.html`, `bin/replay-open.sh` — deferred to v2
- `bin/hooks/` — PreCompact/PostCompact, deferred to v2

## Delta log

(append one row per BF-side change to vendored files)

| Date | Files | Reason |
|---|---|---|
| 2026-05-17 | (initial vendor) | Fork point captured above |
```

- [ ] **Step 6: Commit the verbatim vendor**

```bash
git add plugins/bf/runtime/ plugins/bf/test/ plugins/bf/UPSTREAM.md
git commit -m "bf-fork: vendor OPC harness@$(cat /tmp/opc-fork-sha | cut -c1-7)

Verbatim copy of /workspace/opc/bin/opc-harness.mjs + bin/lib/*.mjs into
plugins/bf/runtime/, and test/run-all.sh + test/test-*.sh + test/fixtures
into plugins/bf/test/. No renames yet — task 1.3 applies brand renames.

Excluded: bin/opc.mjs, bin/opc-report.mjs, bin/replay-viewer.html,
bin/replay-open.sh, bin/hooks/ (see plugins/bf/UPSTREAM.md)."
```

---

### Task 1.2.5: Vendor OPC roles + record deferred test

Discovered during Task 1.3 baseline: OPC's harness expects role files at `<runtime>/../../roles/*.md`, and `test-install-hooks.sh` invokes `bin/opc.mjs` which we deliberately did not vendor. Both produce baseline test failures that block Task 1.3.

This task fixes both by:

- Vendoring all 21 OPC `roles/*.md` files into `plugins/bf/roles/` (later, Stage 3 will move product-engineering-specific roles into the Pack; here we vendor the lot so the harness tests pass).
- Adding `test-install-hooks.sh` to a `plugins/bf/test/deferred-tests.txt` list, and editing `run-all.sh` to skip files named in that list. (The test depends on `bin/opc.mjs`, which `UPSTREAM.md` already marks as not-vendored.)

**Files:**
- Create: `plugins/bf/roles/<21 .md files>` (verbatim from `/workspace/opc/roles/`)
- Modify: `plugins/bf/roles/.gitkeep` — delete (no longer empty)
- Create: `plugins/bf/test/deferred-tests.txt`
- Modify: `plugins/bf/test/run-all.sh` (add a skip-by-name filter)
- Modify: `plugins/bf/UPSTREAM.md` (delta log entry)

- [ ] **Step 1: Vendor OPC roles**

```bash
cp /workspace/opc/roles/*.md plugins/bf/roles/
rm plugins/bf/roles/.gitkeep
ls plugins/bf/roles/*.md | wc -l
```

Expected: 21.

- [ ] **Step 2: Create deferred-tests list**

Write `plugins/bf/test/deferred-tests.txt`:

```
# Tests deferred because they depend on files not vendored.
# Each line: one test filename (basename), with optional `# reason` comment.

test-install-hooks.sh    # depends on bin/opc.mjs (deferred to Stage 4; see plugins/bf/UPSTREAM.md)
```

- [ ] **Step 3: Patch run-all.sh to honor the skip list**

Edit `plugins/bf/test/run-all.sh`. After the existing line `DIR="$(cd "$(dirname "$0")" && pwd)"`, add:

```bash
DEFERRED_LIST="$DIR/deferred-tests.txt"
declare -A DEFERRED
if [ -f "$DEFERRED_LIST" ]; then
  while IFS= read -r line; do
    name="${line%%#*}"; name="${name%"${name##*[![:space:]]}"}"; name="${name#"${name%%[![:space:]]*}"}"
    [ -z "$name" ] && continue
    DEFERRED["$name"]=1
  done < "$DEFERRED_LIST"
fi
```

Then inside the `for f in "$DIR"/test-*.sh; do` loop, after the existing `[ "$(basename "$f")" = "test-helpers.sh" ] && continue` line, add:

```bash
  base="$(basename "$f")"
  if [ -n "${DEFERRED[$base]:-}" ]; then
    echo ""
    echo "─── skipping (deferred): $base"
    continue
  fi
```

- [ ] **Step 4: Run the suite to confirm baseline is green**

```bash
mkdir -p plugins/bf/bin
ln -sf ../runtime/opc-harness.mjs plugins/bf/bin/opc-harness.mjs
ln -sf ../runtime/lib plugins/bf/bin/lib
cd plugins/bf/test
bash run-all.sh 2>&1 | tee /tmp/bf-baseline-test-output.txt
cd -
rm -rf plugins/bf/bin
```

Expected: `Suite: 108 files passed, 0 files failed` (110 `test-*.sh` − 1 `test-helpers.sh` already skipped by run-all.sh − 1 deferred = 108). Exit code 0.

- [ ] **Step 5: Append delta log entry to UPSTREAM.md**

Add a row to the delta log table in `plugins/bf/UPSTREAM.md`:

```markdown
| 2026-05-17 | roles/*.md (21 files), test/deferred-tests.txt, test/run-all.sh | Vendor OPC roles so harness mandatory-role checks work; add a skip-by-name mechanism to run-all.sh and defer test-install-hooks.sh (depends on bin/opc.mjs which is not vendored). Discovered during Task 1.3 baseline run. |
```

- [ ] **Step 6: Commit**

```bash
git add plugins/bf/roles/ plugins/bf/test/deferred-tests.txt plugins/bf/test/run-all.sh plugins/bf/UPSTREAM.md
git commit -m "bf-fork: vendor OPC roles + skip deferred test (test-install-hooks)

Task 1.3 baseline surfaced two failure clusters:
- test-guardrails.sh + test-mandatory-role.sh failed because OPC harness
  expects roles/*.md and plugins/bf/roles/ was empty (.gitkeep only).
  Vendor all 21 upstream roles verbatim. Stage 3 will later move product-
  engineering-specific roles into the Pack.
- test-install-hooks.sh failed because it invokes bin/opc.mjs which is
  intentionally not vendored (see UPSTREAM.md). Add a deferred-tests.txt
  + skip filter in run-all.sh so the suite can stay green.

Baseline now: 108 passed / 0 failed / 1 deferred. UPSTREAM.md delta log
records the change."
```

---

### Task 1.3: Confirm baseline output captured

After Task 1.2.5 fixed the vendor gaps, the baseline test output should already exist. This task is a quick checkpoint.

**Files:** No changes.

- [ ] **Step 1: Confirm baseline output is captured**

```bash
test -f /tmp/bf-baseline-test-output.txt && tail -3 /tmp/bf-baseline-test-output.txt
```

Expected: a `Suite: 108 files passed, 0 files failed` line near the end.

- [ ] **Step 2: If missing, re-run the suite**

(Only if /tmp/bf-baseline-test-output.txt is missing — e.g. /tmp was wiped.)

```bash
mkdir -p plugins/bf/bin
ln -sf ../runtime/opc-harness.mjs plugins/bf/bin/opc-harness.mjs
ln -sf ../runtime/lib plugins/bf/bin/lib
cd plugins/bf/test && bash run-all.sh 2>&1 | tee /tmp/bf-baseline-test-output.txt && cd -
rm -rf plugins/bf/bin
```

- [ ] **Step 3: No commit**

Verification only.

---

### Task 1.4: Apply brand renames across vendored runtime

Replace the brand strings per the spec's naming policy. **Generic vocabulary** (`flow`, `node`, `edge`, `verdict`, `handshake`, `gate`, `route`, `transition`, `synthesize`, `FLOW_TEMPLATES`) is **kept**. Only the brand words listed in `docs/specs/2026-05-16-bf-fork-design.md` § "Replaced (brand words)" change.

**Files:**
- Rename: `plugins/bf/runtime/opc-harness.mjs` → `plugins/bf/runtime/bf-harness.mjs`
- Modify (in-place): `plugins/bf/runtime/bf-harness.mjs`, `plugins/bf/runtime/lib/*.mjs`

**The rename map** (apply across all `.mjs` files; case-sensitive):

| from | to | notes |
|---|---|---|
| `opc-harness` | `bf-harness` | binary name + skill ref |
| `OPC_HARNESS` | `BF_HARNESS` | env var |
| `~/.opc/sessions/` | `~/.bf/sessions/` | session root |
| `~/.opc/runbooks/` | `~/.bf/runbooks/` | runbooks dir |
| `OPC_DISABLE_EXTENSIONS` | `BF_DISABLE_EXTENSIONS` | env opt-out |
| `OPC_QUIET_DEPRECATIONS` | `BF_QUIET_DEPRECATIONS` | env opt-out |
| `OPC_DISABLE_RUNBOOKS` | `BF_DISABLE_RUNBOOKS` | env opt-out |
| `OPC_RUNBOOKS_DIR` | `BF_RUNBOOKS_DIR` | env path |
| `opc_compat` | `bf_compat` | flow JSON field name |
| `~/.claude/flows/` | (kept; deprecated path; logs warning) | back-compat only; not active |
| `~/.claude/skills/opc/` | `~/.claude/plugins/bf/` | OPC-style install path → BF plugin path |
| `OPC` (standalone tag in log strings like `OPC harness` or `OPC v…`) | `BF` | only when it's a brand mention, not generic "OPC" comment-reference |
| `.harness` (the **state dir** default; both bare `.harness` and `.harness/...`) | `.bf` | session/run state dir |
| `wave-*` (legacy v0.4 detection) | (kept; this is OPC's own legacy marker, not BF brand) | keep for migration messaging |

**Strings we deliberately keep unchanged:**

- `HARNESS_VERSION` constant name (semantic, not a brand)
- `flow-state.json`, `flow-context.json`, `handshake.json`, `loop-state.json`, `plan.md`, `acceptance-criteria.md` (file names; generic)
- `FLOW_TEMPLATES`, `BUILTIN_NAMES` (semantic)
- `bypass`, `extension`, `runbook`, `oscillation`, `criteria-lint`, `synthesize`, `scope` (vocabulary)

- [ ] **Step 1: Move the harness entry file**

```bash
git mv plugins/bf/runtime/opc-harness.mjs plugins/bf/runtime/bf-harness.mjs
```

- [ ] **Step 2: Apply text substitutions across runtime files**

Use a script to apply the rename map. Save it as `/tmp/bf-rename.sh`:

```bash
cat > /tmp/bf-rename.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="plugins/bf/runtime"

# Order matters: longer patterns first to avoid partial overlaps.
declare -a MAP=(
  "OPC_DISABLE_EXTENSIONS|BF_DISABLE_EXTENSIONS"
  "OPC_QUIET_DEPRECATIONS|BF_QUIET_DEPRECATIONS"
  "OPC_DISABLE_RUNBOOKS|BF_DISABLE_RUNBOOKS"
  "OPC_RUNBOOKS_DIR|BF_RUNBOOKS_DIR"
  "OPC_HARNESS|BF_HARNESS"
  "opc-harness|bf-harness"
  "~/.opc/sessions|~/.bf/sessions"
  "~/.opc/runbooks|~/.bf/runbooks"
  "~/.claude/skills/opc/|~/.claude/plugins/bf/"
  "opc_compat|bf_compat"
)

for entry in "${MAP[@]}"; do
  from="${entry%%|*}"
  to="${entry##*|}"
  echo "  $from → $to"
  find "$ROOT" -name '*.mjs' -print0 | xargs -0 sed -i "s|${from}|${to}|g"
done

# .harness as a path default (only string literals — not comments mentioning legacy)
# Patterns to hit: ".harness", "'\.harness'", "\".harness\""
find "$ROOT" -name '*.mjs' -print0 | xargs -0 sed -i "s|\"\\.harness\"|\".bf\"|g; s|'\\.harness'|'.bf'|g"

# Standalone "OPC" as a brand mention in log strings (be conservative: only replace
# when it's at a string boundary or followed by a space + word like "harness"/"version").
find "$ROOT" -name '*.mjs' -print0 | xargs -0 sed -i "s|OPC harness|BF harness|g; s|OPC version|BF version|g"

echo "rename done"
EOF
chmod +x /tmp/bf-rename.sh
bash /tmp/bf-rename.sh
```

- [ ] **Step 3: Inspect what changed**

```bash
git diff --stat plugins/bf/runtime/ | tail -3
git diff plugins/bf/runtime/lib/util.mjs | head -40
```

Expected: many files modified; util.mjs's `.harness` defaults and `opc-harness` writer signature are now `.bf` and `bf-harness`.

- [ ] **Step 4: Spot-check residual occurrences**

```bash
grep -rn "opc-harness\|OPC_HARNESS\|opc_compat\|\.opc/\|~/.opc" plugins/bf/runtime/ || echo "CLEAN"
```

Expected: `CLEAN`. If any hits remain, investigate (likely a path / case variant the script missed); fix manually and commit alongside.

Some hits are **acceptable** and should be left alone:
- comments referencing the OPC project (e.g. `// vendored from OPC`)
- the deprecation warning string for `~/.claude/flows/` (legacy OPC behavior; warning text mentions both)

Add greps for those too, to be sure:

```bash
grep -rn "\\.harness" plugins/bf/runtime/ | grep -v "// " | grep -v "wave-" || echo "CLEAN"
```

Expected: `CLEAN` for code; comments mentioning `.harness` (back-compat warnings) are OK.

- [ ] **Step 5: Commit the rename**

```bash
git add plugins/bf/runtime/
git commit -m "bf-fork: brand rename (opc-harness → bf-harness, .harness → .bf)

Apply the brand-word rename map from spec § 'Replaced (brand words)':
- opc-harness → bf-harness (binary entry + writer sig)
- OPC_HARNESS, OPC_DISABLE_*, OPC_QUIET_* → BF_*
- ~/.opc/sessions → ~/.bf/sessions
- ~/.opc/runbooks → ~/.bf/runbooks
- opc_compat → bf_compat (flow JSON field)
- .harness → .bf (default state dir literal)
- ~/.claude/skills/opc/ → ~/.claude/plugins/bf/

Generic vocabulary (flow / node / verdict / handshake / gate / route /
transition / synthesize / FLOW_TEMPLATES / HARNESS_VERSION) is kept.

UPSTREAM.md delta log will be updated in the next task once tests
are green under the new names."
```

---

### Task 1.5: Update test scripts for new paths + harness name

OPC test scripts hardcode `bin/opc-harness.mjs` and `.harness`. After our rename they need to point to `runtime/bf-harness.mjs` and `.bf`.

**Files:**
- Modify: `plugins/bf/test/test-*.sh` (all 111 scripts)
- Modify: `plugins/bf/test/run-all.sh`, `plugins/bf/test/test-helpers.sh` (if present)

Apply the **same rename map** as task 1.4, plus one extra: tests reference the harness via path, not env, so we also need:

| from | to |
|---|---|
| `bin/opc-harness.mjs` | `runtime/bf-harness.mjs` |
| `bin/lib/` | `runtime/lib/` |
| `../bin/` (in test scripts) | `../runtime/` |

- [ ] **Step 1: Apply path renames in test scripts**

```bash
find plugins/bf/test -name '*.sh' -print0 | xargs -0 sed -i \
  -e 's|bin/opc-harness\.mjs|runtime/bf-harness.mjs|g' \
  -e 's|bin/lib/|runtime/lib/|g' \
  -e 's|/bin/|/runtime/|g' \
  -e 's|opc-harness|bf-harness|g' \
  -e 's|OPC_HARNESS|BF_HARNESS|g' \
  -e 's|opc_compat|bf_compat|g' \
  -e 's|~/.opc/sessions|~/.bf/sessions|g' \
  -e 's|~/.opc/runbooks|~/.bf/runbooks|g' \
  -e 's|"\.harness"|".bf"|g' \
  -e "s|'\\.harness'|'.bf'|g"
```

- [ ] **Step 2: Sanity-check for missed strings**

```bash
grep -rn "opc-harness\|OPC_HARNESS\|opc_compat\|/bin/" plugins/bf/test/ 2>/dev/null || echo "CLEAN"
```

Expected: `CLEAN`. If hits remain, they're likely in unusual constructs (heredocs, multi-line strings); fix manually.

- [ ] **Step 3: Run the full test suite from the new layout**

```bash
cd plugins/bf/test
bash run-all.sh 2>&1 | tee /tmp/bf-postrename-test-output.txt
cd -
```

Expected: `Suite: N files passed, 0 files failed` — same pass count as `/tmp/bf-baseline-test-output.txt`.

- [ ] **Step 4: Compare counts vs baseline**

```bash
grep "Suite:" /tmp/bf-baseline-test-output.txt /tmp/bf-postrename-test-output.txt
```

Both lines should show identical `N files passed, 0 files failed`. If post-rename has fewer passes or any failures, **stop** — the rename broke something. Diagnose the failing test, fix it (likely a path the regex missed), re-run; don't proceed until parity.

- [ ] **Step 5: Commit the test rename**

```bash
git add plugins/bf/test/
git commit -m "bf-fork: update test scripts for new runtime path + names

Apply same brand rename map to test/*.sh, plus path fixes:
- bin/opc-harness.mjs → runtime/bf-harness.mjs
- bin/lib/ → runtime/lib/
- ../bin/ → ../runtime/

Test suite passes with same N/N count as pre-rename baseline (see
/tmp/bf-postrename-test-output.txt)."
```

---

### Task 1.6: Update UPSTREAM.md delta log + register `bf` in marketplace

**Files:**
- Modify: `plugins/bf/UPSTREAM.md`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Append the rename to the UPSTREAM delta log**

Edit `plugins/bf/UPSTREAM.md`, replace the `(initial vendor)` row in the delta log with:

```markdown
| Date | Files | Reason |
|---|---|---|
| 2026-05-17 | initial vendor | Fork point captured above |
| 2026-05-17 | runtime/*.mjs, test/*.sh | Brand renames per spec § 'Replaced (brand words)': opc-harness → bf-harness; .harness → .bf; ~/.opc → ~/.bf; opc_compat → bf_compat; OPC_* env vars → BF_*. Generic vocabulary kept. |
```

- [ ] **Step 2: Update `.claude-plugin/marketplace.json` to include bf**

Read existing file first:

```bash
cat .claude-plugin/marketplace.json
```

Expected: a JSON with `plugins: [{name: "blueprintflow", ...}]`. Add a second entry for `bf`:

```json
{
  "name": "blueprintflow",
  "owner": { "name": "codetreker" },
  "plugins": [
    {
      "name": "blueprintflow",
      "source": "./plugins/blueprintflow",
      "description": "Blueprint-driven multi-agent collaboration workflow (v6.0.0; v1 migration in progress)"
    },
    {
      "name": "bf",
      "source": "./plugins/bf",
      "description": "Blueprintflow — general evidence-gated work loop framework (alpha)"
    }
  ]
}
```

- [ ] **Step 3: Verify marketplace JSON is valid**

```bash
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json'))" && echo "VALID JSON"
```

Expected: `VALID JSON`.

- [ ] **Step 4: Commit**

```bash
git add plugins/bf/UPSTREAM.md .claude-plugin/marketplace.json
git commit -m "feat(bf): register bf plugin in marketplace + document fork delta

UPSTREAM.md now logs the brand rename as the first BF-side delta.
Marketplace JSON adds a 'bf' entry alongside existing 'blueprintflow'."
```

---

## Stage 1 Definition of Done

- [ ] `plugins/bf/runtime/bf-harness.mjs` runs (e.g. `node plugins/bf/runtime/bf-harness.mjs --help` exits 0)
- [ ] `plugins/bf/test/run-all.sh` passes with the same count as `/tmp/bf-baseline-test-output.txt`
- [ ] No stale `opc-harness` / `OPC_HARNESS` / `opc_compat` / `~/.opc` / hard-coded `.harness` strings in `plugins/bf/runtime/` or `plugins/bf/test/`
- [ ] `plugins/bf/UPSTREAM.md` documents the fork point + initial delta
- [ ] `.claude-plugin/marketplace.json` registers `bf`

---

## Stage 2 — Write 5 BF Core Contract Docs

These docs live at `plugins/bf/core/*.md` and are **the canonical statement** of Core for users of the `bf` plugin. They derive from `docs/specs/2026-05-16-bf-fork-design/core-contracts.md` (which currently contains all 5 contracts inline) — Stage 2's job is to split that one spec file into 5 user-facing reference docs **inside the plugin**.

**Why split?** Spec lives in `docs/specs/` for designers. Core docs live in `plugins/bf/core/` for plugin users. Same content; different audience; different default location.

**Source of truth ordering:** if the spec and the new core/*.md ever disagree during this stage, the spec wins. After Stage 6, the plugin's core/*.md may have evolved past the spec — at that point Stage 6 will fold spec into a `CHANGELOG.md`.

### Task 2.1: Author `core/work-object.md`

**Files:**
- Create: `plugins/bf/core/work-object.md`

**Source:** `docs/specs/2026-05-16-bf-fork-design/core-contracts.md` § "1. Work Object". Lift the content; rewrite the intro paragraph to be plugin-user-facing (not spec-reviewer-facing); keep example, lifecycle, field table verbatim.

- [ ] **Step 1: Read the spec section**

```bash
sed -n '/^## 1\. Work Object/,/^---$/p' docs/specs/2026-05-16-bf-fork-design/core-contracts.md | head -120
```

- [ ] **Step 2: Write `plugins/bf/core/work-object.md`**

Content outline (write it as one file in this step):

```markdown
# Work Object

> The primary citizen of BF. A bounded piece of uncertain or incomplete work that BF advances through states.

## Concept

[2-3 paragraphs: what a WO is, why semi-persistent, why recursive directories, the
relationship to "work product" (BF doesn't track product; acceptance_criteria
asserts it). Lift wording from spec § Purpose.]

## On-disk shape

[The directory diagram from spec § Storage shape — verbatim]

## wo.md structure

[The YAML + markdown body template from spec — verbatim]

## Field reference

[The full field table from spec — verbatim, with one column added: "Default" for
optional fields]

## Lifecycle (canonical states)

[The state-machine block from spec § Lifecycle — verbatim, plus a brief note
that Pack-defined states alias to canonical via `state_aliases`]

## Example

[A complete leaf-task wo.md example — lift from spec]

## See also

- [Flow](./flow.md) — how a WO is advanced
- [WO Home](./wo-home.md) — where a WO lives on disk
- [Pack](./pack.md) — which Pack a WO belongs to
- [Gate](./gate.md) — how state transitions are gated
```

(Write the actual sections in full when implementing — don't leave bracket-placeholders. The spec already has the exact wording for each.)

- [ ] **Step 3: Verify**

```bash
wc -l plugins/bf/core/work-object.md
head -30 plugins/bf/core/work-object.md
```

Expected: file exists; > 80 lines; header and TOC look right.

- [ ] **Step 4: Commit**

```bash
git add plugins/bf/core/work-object.md
git commit -m "docs(bf-core): author work-object contract

Lift from docs/specs/.../core-contracts.md § 1. Plugin-user-facing
rewrite of the intro; fields / lifecycle / example verbatim from spec."
```

---

### Task 2.2: Author `core/flow.md` (includes Artifact sub-contract)

**Files:**
- Create: `plugins/bf/core/flow.md`

**Source:** Spec § "2. Flow" + § "3. Artifact (sub-contract within Flow)".

Same shape as Task 2.1. The doc has these sections:

- `# Flow`
- `## Concept` — directed graph of typed nodes; one of 4 core_types
- `## The four core types` — brief description of brainstorm / breakdown / loop / close (the table from spec § Core flow types)
- `## Field reference` — full table from spec § Fields, including BF additions (`core_type`, `accepts`, `produces`)
- `## Lifecycle` — Selection → Init → Step → Terminal, from spec
- `## Where stored` — definition path vs run state path
- `## Example` — the `task-implementation` example from spec
- `## Artifact (sub-contract)` — the entire spec § 3 lifted (`type` enum, `path`, lifecycle, "artifact as product" note)
- `## See also` — pointers to work-object.md, gate.md, wo-home.md

- [ ] **Step 1: Read the relevant spec sections**

```bash
sed -n '/^## 2\. Flow/,/^## 4\. Gate/p' docs/specs/2026-05-16-bf-fork-design/core-contracts.md
```

- [ ] **Step 2: Write `plugins/bf/core/flow.md`** (follow outline above; lift spec content into each section)

- [ ] **Step 3: Verify**

```bash
wc -l plugins/bf/core/flow.md
grep -c "^## " plugins/bf/core/flow.md
```

Expected: > 100 lines; 8 H2 sections.

- [ ] **Step 4: Commit**

```bash
git add plugins/bf/core/flow.md
git commit -m "docs(bf-core): author flow contract + artifact sub-contract"
```

---

### Task 2.3: Author `core/gate.md`

**Files:**
- Create: `plugins/bf/core/gate.md`

**Source:** Spec § "4. Gate".

Sections:

- `# Gate`
- `## Concept` — mechanical decision; no LLM
- `## Mechanism` — synthesize rules (🔴🟡🔵 counts, compound D2 rule)
- `## Where stored` — gate handshake + flow-state history
- `## BF additions` — state advancement on PASS, Pack-level override hook
- `## See also`

- [ ] **Step 1: Lift content**

```bash
sed -n '/^## 4\. Gate/,/^## 5\. WO Home/p' docs/specs/2026-05-16-bf-fork-design/core-contracts.md
```

- [ ] **Step 2: Write `plugins/bf/core/gate.md`** (follow outline)

- [ ] **Step 3: Cross-reference acceptance-judgement.md** — Gate alone doesn't tell the full acceptance story. Add a paragraph at the end of `## Mechanism` linking to `../../../docs/specs/2026-05-16-bf-fork-design/acceptance-judgement.md` for the full distributed-judgement model (criteria-lint + review + execute + gate)

- [ ] **Step 4: Verify and commit**

```bash
wc -l plugins/bf/core/gate.md
git add plugins/bf/core/gate.md
git commit -m "docs(bf-core): author gate contract"
```

---

### Task 2.4: Author `core/wo-home.md`

**Files:**
- Create: `plugins/bf/core/wo-home.md`

**Source:** Spec § "5. WO Home".

Sections:

- `# WO Home`
- `## Concept` — semi-persistent directory; replaces earlier "Ledger" name
- `## Distinction from runs` — the table from spec
- `## Files / structure` — the directory tree from spec
- `## Child WOs` — filesystem-native parent/child relations
- `## Lifecycle` — created → shaped → broken_down → loop → close → discarded
- `## Where stored` — default `~/.bf/wo/`; configurable for shared storage
- `## See also`

- [ ] **Step 1: Lift content**

```bash
sed -n '/^## 5\. WO Home/,/^## 6\. Pack/p' docs/specs/2026-05-16-bf-fork-design/core-contracts.md
```

- [ ] **Step 2: Write `plugins/bf/core/wo-home.md`** (follow outline)

- [ ] **Step 3: Verify and commit**

```bash
wc -l plugins/bf/core/wo-home.md
git add plugins/bf/core/wo-home.md
git commit -m "docs(bf-core): author wo-home contract"
```

---

### Task 2.5: Author `core/pack.md`

**Files:**
- Create: `plugins/bf/core/pack.md`

**Source:** Spec § "6. Pack".

Sections:

- `# Pack`
- `## Concept` — domain-specific instantiation of Core
- `## Field reference` — full table from spec including `state_aliases`
- `## Lifecycle` — registered → selected → active → versioned
- `## Where stored` — `plugins/bf/packs/<id>/`; future `plugins/bf-pack-*/`
- `## Role resolution` — flow → Pack → Core override order
- `## Example` — the product-engineering pack.json from spec
- `## See also`

- [ ] **Step 1: Lift content**

```bash
sed -n '/^## 6\. Pack/,$p' docs/specs/2026-05-16-bf-fork-design/core-contracts.md
```

- [ ] **Step 2: Write `plugins/bf/core/pack.md`** (follow outline)

- [ ] **Step 3: Verify and commit**

```bash
wc -l plugins/bf/core/pack.md
git add plugins/bf/core/pack.md
git commit -m "docs(bf-core): author pack contract"
```

---

### Task 2.6: Cross-link audit + Core README

**Files:**
- Create: `plugins/bf/core/README.md`
- (Possibly modify) `plugins/bf/core/*.md` to fix any broken cross-links

- [ ] **Step 1: Write `plugins/bf/core/README.md`**

```markdown
# BF Core Contracts

This directory holds the five canonical BF Core contracts. Read in order:

1. [work-object.md](./work-object.md) — the primary citizen (what)
2. [flow.md](./flow.md) — how a Work Object advances (also documents Artifact)
3. [gate.md](./gate.md) — how PASS / ITERATE / FAIL is decided
4. [wo-home.md](./wo-home.md) — where a Work Object lives on disk
5. [pack.md](./pack.md) — domain-specific instantiation

For the **design rationale** behind these contracts — including the 10 BF axioms,
the Core / Pack layering principles, and the four-step core loop —
see `../../../docs/specs/2026-05-16-bf-fork-design/layering-principles.md`.

For **how acceptance is judged**, see
`../../../docs/specs/2026-05-16-bf-fork-design/acceptance-judgement.md`.
```

- [ ] **Step 2: Verify all relative links resolve**

```bash
for f in plugins/bf/core/*.md; do
  echo "--- $f ---"
  grep -oE '\]\([^)]+\)' "$f" | sed 's|](\(.*\))|\1|' | while read link; do
    # Skip http/https/anchor-only links
    case "$link" in
      http*|\#*) continue;;
    esac
    # Resolve relative to the file's directory
    dir=$(dirname "$f")
    target="$dir/$link"
    # Strip any anchor
    target="${target%%\#*}"
    if [ ! -e "$target" ]; then
      echo "BROKEN: $link → $target"
    fi
  done
done
```

Expected: no `BROKEN:` lines. If any appear, fix the link.

- [ ] **Step 3: Commit**

```bash
git add plugins/bf/core/README.md plugins/bf/core/
git commit -m "docs(bf-core): add core/README.md + verify cross-links"
```

---

## Stage 2 Definition of Done

- [ ] All five `plugins/bf/core/*.md` exist, derived from the spec
- [ ] `plugins/bf/core/README.md` exists with reading order + pointers to layering-principles + acceptance-judgement
- [ ] All cross-links resolve
- [ ] Spec and `plugins/bf/core/*.md` are content-equivalent (spec is reviewer-facing; core docs are user-facing — but the facts match)

---

## Self-Review Notes

- [ ] All file paths in this plan are absolute-from-worktree-root (`plugins/bf/...`); no `./` prefixes that depend on cwd
- [ ] No "TBD" or "fill in later"; every step has the command or content needed
- [ ] Test count assertions are concrete (40 lib files, 111 test scripts; verified during plan authoring)
- [ ] Stage 1 ends with full test parity; Stage 2 has no runtime impact, just docs

## Out of Scope (deferred to later plans)

- Stage 3: first Pack (product-engineering) — separate plan after Stage 1+2 done
- Stage 4: `bf-run` entry skill — separate plan
- Stage 5: end-to-end demo — separate plan
- Stage 6: remaining Pack migration + v6→v1 migration guide — separate plan
- `bf` extension system, cron verbs, HTML report, replay viewer — all v2
