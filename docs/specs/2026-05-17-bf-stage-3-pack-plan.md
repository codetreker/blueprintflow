# BF Stage 3 — First Pack (product-engineering) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement task-by-task. Steps use `- [ ]` checkboxes.

**Goal:** Stand up the first BF Pack — `product-engineering` — by copying the v6 plugin content into `packs/product-engineering/`, writing a `pack.json` with `state_aliases`, vendoring 5–7 generic OPC pipeline protocols into `pipeline/`, sorting the 21 vendored roles into Core vs Pack, and authoring 4 probe flows (one per Core flow type: brainstorm / breakdown / loop / close) to stress-test the BF Core contracts.

**Architecture:** Pack content lives under `packs/product-engineering/` (already-empty directory from Stage 1). v6 plugin (`plugins/blueprintflow/`) is **copied** (not moved) — users can continue using v6 alongside the in-progress v1 Pack until Stage 6's migration guide lands. The 21 vendored OPC roles get triaged per `opc-role-mapping.md`: Core-eligible stay in `roles/`, product-engineering-specific move into `packs/product-engineering/roles/`, `investor` is deleted (per mapping).

**Tech Stack:** Same as Stage 1+2 — Node 18+, Bash, file-based state. No new tooling.

**Source of truth:** `docs/specs/2026-05-16-bf-fork-design.md` + `docs/specs/2026-05-16-bf-fork-design/*.md` (especially `opc-role-mapping.md`, `bf-skill-migration.md`, `core-contracts.md`). When the plan and spec disagree, spec wins; update plan inline.

**Worktree:** Same branch as Stage 1+2 — `worktree-bf-fork-spec`. Continue committing here; PR #100 reflects cumulative progress.

---

## File Structure Overview (delta vs Stage 1+2 end-state)

```
packs/product-engineering/             ← NEW: first Pack
├── pack.json                          ← manifest + state_aliases + routing
├── README.md                          ← Pack overview
├── schemas/
│   ├── blueprint.json                 ← Stage 6 unless small enough
│   ├── phase.json
│   ├── milestone.json
│   └── task.json                      ← Stage 3 must-have
├── flows/
│   ├── brainstorm-task.json           ← probe flow #1
│   ├── breakdown-milestone-to-task.json  ← probe flow #2
│   ├── loop-milestone.json            ← probe flow #3
│   └── close-leaf-task.json           ← probe flow #4
├── protocols/
│   ├── brainstorm-task.md             ← derived from bf-task-fourpiece
│   ├── breakdown-milestone-to-task.md ← derived from bf-implementation-design
│   ├── loop-milestone.md              ← derived from bf-milestone-progress
│   └── close-leaf-task.md             ← derived from bf-task-execute + bf-pr-review-flow + bf-verification
├── roles/                             ← product-engineering-specific roles (12 from OPC + 5 BF team-roles)
│   ├── pm.md
│   ├── designer.md
│   ├── frontend.md, backend.md, devops.md, mobile.md, engineer.md, dd-engineer.md
│   ├── new-user.md, active-user.md, churned-user.md
│   └── (BF team-roles synthesized) PM-bf.md / Architect-bf.md / Dev-bf.md / QA-bf.md / Teamlead-bf.md
└── (v6 reference content copied here, indexed in README)
    ├── reference-v6/
    │   ├── using-plueprint-SKILL.md   ← copies of v6 SKILL.md content for traceability
    │   ├── bf-blueprint-write-SKILL.md
    │   └── ... (one per v6 skill)
    └── (later Stage 6 turns these into authored Pack content)

pipeline/                              ← UPDATED: now has 5-7 vendored protocols
├── gate-protocol.md                   ← vendored from OPC
├── handoff-template.md                ← vendored
├── criteria-lint.md                   ← vendored
├── report-format.md                   ← vendored
├── context-brief.md                   ← vendored
├── role-evaluator-prompt.md           ← vendored (Stage 3 keeps as Core; Pack-specific bits surface as separate Pack protocol if needed)
└── evaluator-prompt.md                ← vendored

roles/                                 ← UPDATED: 9 Core-eligible roles remain; 12 moved to Pack; 1 deleted
├── planner.md, architect.md, devil-advocate.md, skeptic-owner.md
├── tester.md, security.md, a11y.md, compliance.md, user-simulator.md
└── (gone: pm, designer, frontend, backend, devops, mobile, engineer, dd-engineer,
         new-user, active-user, churned-user, investor)

plugins/blueprintflow/                 ← UNCHANGED: v6 plugin stays in place
```

**Not touched in this plan:**
- v6 plugin itself (continues working; users have a stable fallback through v1 cutover)
- `SKILL.md`, `bin/`, `bin/lib/`, `test/` (Stage 1+2 work; not modified by Stage 3)
- `references/` (Stage 1+2 Core contract docs)
- `bin/bf.mjs` dispatcher (still a placeholder; Stage 4 fleshes out)

---

## Stage 3 stages

Five tasks, each a checkpoint with commit.

### Task 3.1: Pack skeleton + manifest

**Files:**
- Create: `packs/product-engineering/.gitkeep` → REMOVE (dir already exists; populate it)
- Create: `packs/product-engineering/pack.json`
- Create: `packs/product-engineering/README.md`
- Create: `packs/product-engineering/schemas/.gitkeep`
- Create: `packs/product-engineering/flows/.gitkeep`
- Create: `packs/product-engineering/protocols/.gitkeep`
- Create: `packs/product-engineering/roles/.gitkeep`

- [ ] **Step 1: Set up directory layout**

```bash
mkdir -p packs/product-engineering/{schemas,flows,protocols,roles,reference-v6}
touch packs/product-engineering/{schemas,flows,protocols,roles,reference-v6}/.gitkeep
```

- [ ] **Step 2: Author `packs/product-engineering/pack.json`**

```jsonc
{
  "bf_compat": ">=0.1",
  "id": "product-engineering",
  "version": "1.0.0-alpha",
  "description": "Blueprint-driven product engineering Pack: blueprint → phase → milestone → task hierarchy, with stance / four-piece / acceptance gates inherited from BF v6.",
  "schemas": {
    "task":      "./schemas/task.json"
  },
  "flows": [
    "./flows/brainstorm-task.json",
    "./flows/breakdown-milestone-to-task.json",
    "./flows/loop-milestone.json",
    "./flows/close-leaf-task.json"
  ],
  "roles_dir": "./roles",
  "protocols_dir": "./protocols",
  "routing": {
    "task,new":          "brainstorm-task",
    "milestone,shaped":  "breakdown-milestone-to-task",
    "milestone,broken_down": "loop-milestone",
    "task,doing":        "close-leaf-task"
  },
  "state_aliases": {
    "reviewed_task_ready": "shaped",
    "accepted_task":       "done",
    "milestone_planned":   "shaped",
    "milestone_done":      "done"
  }
}
```

(Schemas/flows for phase + milestone come in Stage 6. Stage 3 ships task schema + 4 probe flows.)

- [ ] **Step 3: Author `packs/product-engineering/README.md`**

```markdown
# product-engineering Pack

The original Blueprintflow methodology as a BF Pack: blueprint →
phase → milestone → task, with stance, four-piece, and acceptance gates.

This Pack is v1.0.0-alpha. The v6 plugin at `plugins/blueprintflow/`
remains installable side-by-side until v1 cuts over.

## What's here

- `pack.json` — manifest, routing, state_aliases mapping v6 state
  names to BF Core canonical (shaped / broken_down / doing / done)
- `schemas/` — Work Object schemas (task, milestone, phase, blueprint)
- `flows/` — flow graphs (brainstorm / breakdown / loop / close)
- `protocols/` — node execution protocols (derived from v6 skills)
- `roles/` — product-engineering specialist agent prompts
- `reference-v6/` — copies of v6 SKILL.md content, for traceability
  during the v6 → v1 migration. Becomes authored Pack content in
  Stage 6.

## Mapping v6 skills → Pack content

See [bf-skill-migration.md](../../docs/specs/2026-05-16-bf-fork-design/bf-skill-migration.md).
```

- [ ] **Step 4: Verify**

```bash
node -e "JSON.parse(require('fs').readFileSync('packs/product-engineering/pack.json'))" && echo "pack.json valid"
ls packs/product-engineering/
```

Expected: prints "pack.json valid"; listing shows pack.json + README.md + 5 subdirs.

- [ ] **Step 5: Commit**

```bash
git add packs/product-engineering/
git commit -m "feat(bf): scaffold product-engineering Pack skeleton + pack.json

Stage 3 task 3.1. Creates packs/product-engineering/ layout (pack.json,
README.md, schemas/, flows/, protocols/, roles/, reference-v6/) and
authors the manifest with state_aliases mapping v6 state names to BF
Core canonical (shaped/broken_down/doing/done) plus routing for the 4
probe flows landing in Task 3.6."
```

---

### Task 3.2: Copy v6 skill content into `reference-v6/`

The v6 plugin's 21 skills hold the canonical statements of how product-engineering BF works today. Stage 3 doesn't try to author final Pack protocols immediately — it copies v6 SKILL.md and references/ for **each skill** into `packs/product-engineering/reference-v6/`, preserving them as the source the later Pack content is derived from.

**Files:**
- Create: `packs/product-engineering/reference-v6/<v6-skill-name>/...` (one subdir per v6 skill, each containing a copy of its SKILL.md + references/)
- Delete: `packs/product-engineering/reference-v6/.gitkeep` (now populated)

**Why copy not move:** users can keep installing the v6 plugin during the v1 transition; Stage 6 emits the migration guide and we then evaluate retiring the v6 marketplace entry.

- [ ] **Step 1: Inventory v6 skills**

```bash
ls plugins/blueprintflow/skills/ | tee /tmp/v6-skill-list.txt
wc -l /tmp/v6-skill-list.txt
```

Expected: 21 entries (matching `opc-role-mapping.md` count).

- [ ] **Step 2: Copy each v6 skill's content into `reference-v6/`**

```bash
for skill in $(ls plugins/blueprintflow/skills/); do
  mkdir -p "packs/product-engineering/reference-v6/$skill"
  cp -r "plugins/blueprintflow/skills/$skill/." "packs/product-engineering/reference-v6/$skill/"
done
rm -f packs/product-engineering/reference-v6/.gitkeep
ls packs/product-engineering/reference-v6/ | wc -l
```

Expected: 21.

- [ ] **Step 3: Verify integrity**

```bash
for skill in $(ls plugins/blueprintflow/skills/); do
  diff -r "plugins/blueprintflow/skills/$skill" "packs/product-engineering/reference-v6/$skill" >/dev/null && echo "✓ $skill" || echo "✗ MISMATCH: $skill"
done | tail -25
```

All 21 should report `✓`. If any `✗`, investigate (likely a binary file or symlink — adjust the copy command).

- [ ] **Step 4: Commit**

```bash
git add packs/product-engineering/reference-v6/
git commit -m "feat(bf): copy v6 plugin skills into product-engineering reference-v6/

Stage 3 task 3.2. Mirrors all 21 v6 plugin skills under
packs/product-engineering/reference-v6/<skill>/ so Pack content (flows
+ protocols + schemas + roles) can be derived from them without
disturbing the live v6 plugin at plugins/blueprintflow/. The v6 plugin
remains installable side-by-side until the Stage 6 migration guide."
```

---

### Task 3.3: Vendor Core node protocols into `pipeline/`

Stage 1+2 left `pipeline/` empty. Now we vendor the OPC pipeline protocols that are **truly Core** — used by every Pack's `review` / `gate` / `execute` nodes regardless of domain. The Pack-specific ones (implementer-prompt, executor-protocol, etc.) stay out — those get domain protocols inside the Pack.

**Files to vendor verbatim from `/workspace/opc/pipeline/`:**
- `gate-protocol.md` — how a gate computes verdict (mechanical, Core)
- `handoff-template.md` — handshake.json shape (Core; runtime cares)
- `criteria-lint.md` — mechanical lint rules (Core; runtime enforces via bin/lib/criteria-lint.mjs)
- `report-format.md` — presentation JSON schema (Core for cross-Pack reporting)
- `context-brief.md` — how reviewers compose context before evaluation (Core methodology)
- `role-evaluator-prompt.md` — how a role agent produces an eval.md (Core; every Pack's review nodes use this)
- `evaluator-prompt.md` — single-evaluator variant (Core)

**Files explicitly NOT vendored** (Pack-specific):
- `implementer-prompt.md` — product-engineering specific; Pack's close-leaf-task.md derives from it
- `executor-protocol.md` — product-engineering specific (talks about screenshots/CLI; Pack's verify nodes derive from it)
- `discussion-protocol.md` — Pack-specific; brainstorm protocols derive from it
- `test-design-protocol.md` — Pack-specific
- `ux-observer-protocol.md`, `ux-simulation-protocol.md` — Pack-specific
- `loop-protocol.md` — overlapping with BF Core loop semantics; leave to Stage 4 dispatcher rewrite
- `quality-tiers.md` — Pack-specific (per-tier baselines)

- [ ] **Step 1: Vendor the 7 Core protocols**

```bash
mkdir -p pipeline
rm -f pipeline/.gitkeep
for f in gate-protocol.md handoff-template.md criteria-lint.md report-format.md context-brief.md role-evaluator-prompt.md evaluator-prompt.md; do
  cp "/workspace/opc/pipeline/$f" "pipeline/$f"
done
ls pipeline/*.md | wc -l
```

Expected: 7.

- [ ] **Step 2: Brand-rename inside vendored protocols**

```bash
find pipeline -name '*.md' -print0 | xargs -0 sed -i \
  -e 's|opc-harness|bf-harness|g' \
  -e 's|OPC_HARNESS|BF_HARNESS|g' \
  -e 's|opc_compat|bf_compat|g' \
  -e 's|/opc |/bf |g' \
  -e 's|~/.opc/|~/.bf/|g' \
  -e 's|\.harness/|.bf/|g' \
  -e 's|"OPC|"BF|g'
```

- [ ] **Step 3: Scan for residuals**

```bash
grep -rn "opc-harness\|OPC_HARNESS\|opc_compat\|/opc \|~/.opc/" pipeline/ 2>/dev/null || echo CLEAN
```

Expected: CLEAN. (Comments mentioning "OPC" as the upstream project name may remain — those are historical references and OK.)

- [ ] **Step 4: Author `pipeline/README.md`**

```markdown
# pipeline/ — Core Node Protocols

These are protocols that apply to every Pack's flow nodes. They cover
mechanical-evidence interactions (handoff, criteria-lint, gate verdict
computation, report format) and the cross-Pack methodology for review
context (context-brief, role-evaluator).

Pack-specific protocols (implementer-prompt, executor-protocol,
discussion-protocol, test-design, ux-*) live inside each Pack's
`protocols/` directory.

## Files

- [gate-protocol.md](./gate-protocol.md) — verdict synthesis (used by every gate node)
- [handoff-template.md](./handoff-template.md) — handshake.json shape and validation
- [criteria-lint.md](./criteria-lint.md) — acceptance_criteria mechanical lint
- [report-format.md](./report-format.md) — flow-completion report JSON + presentation
- [context-brief.md](./context-brief.md) — pre-review context composition
- [role-evaluator-prompt.md](./role-evaluator-prompt.md) — multi-role review template
- [evaluator-prompt.md](./evaluator-prompt.md) — single-evaluator variant

## Vendored from OPC

These files were vendored verbatim from `/workspace/opc/pipeline/` at
the fork commit (see [`../UPSTREAM.md`](../UPSTREAM.md)) with brand
renames applied (opc-harness → bf-harness, ~/.opc → ~/.bf, etc.).
```

- [ ] **Step 5: Update UPSTREAM.md delta log**

Append a row to the delta log table in `UPSTREAM.md`:

```
| 2026-05-17 | pipeline/{gate-protocol,handoff-template,criteria-lint,report-format,context-brief,role-evaluator-prompt,evaluator-prompt}.md, pipeline/README.md | Stage 3: vendor 7 Core node protocols from OPC pipeline/. Pack-specific protocols (implementer-prompt, executor-protocol, discussion-protocol, test-design-protocol, ux-*) intentionally not vendored — they belong inside each Pack's protocols/ folder. |
```

Also update "Files vendored verbatim" section to list `pipeline/*.md (7 files)`.

- [ ] **Step 6: Run tests to confirm no impact**

```bash
cd test && bash run-all.sh 2>&1 | tail -3
cd -
```

Expected: still `108 passed / 0 failed / 1 deferred`. (pipeline content is markdown — shouldn't affect the test suite, but verify.)

- [ ] **Step 7: Commit**

```bash
git add pipeline/ UPSTREAM.md
git commit -m "feat(bf): vendor 7 Core node protocols into pipeline/

Stage 3 task 3.3. Vendors gate-protocol, handoff-template, criteria-lint,
report-format, context-brief, role-evaluator-prompt, evaluator-prompt
from /workspace/opc/pipeline/ with brand renames applied. Pack-specific
protocols (implementer-prompt, executor-protocol, discussion-protocol,
test-design-protocol, ux-*) intentionally not vendored — they belong
inside each Pack's protocols/. Adds pipeline/README.md and UPSTREAM
delta entry."
```

---

### Task 3.4: Sort the 21 vendored OPC roles into Core vs Pack

Per `opc-role-mapping.md` § Mapping table. Stage 1 dumped all 21 into `roles/` to make tests pass; now we triage.

**Movements** (verify against `opc-role-mapping.md` if any uncertainty):

| Role | Action | Destination |
|---|---|---|
| planner, architect, devil-advocate, skeptic-owner | keep in Core | `roles/<name>.md` (no move) |
| tester, security, a11y, compliance, user-simulator | keep in Core | `roles/<name>.md` (no move) |
| pm, designer | move to Pack | `packs/product-engineering/roles/<name>.md` |
| frontend, backend, devops, mobile, engineer, dd-engineer | move to Pack | `packs/product-engineering/roles/<name>.md` |
| new-user, active-user, churned-user | move to Pack | `packs/product-engineering/roles/<name>.md` |
| investor | delete | (per spec § "Skip"; not relevant to BF's path) |

**Count check**: 9 Core + 11 Pack + 1 deleted = 21 ✓.

- [ ] **Step 1: Move Pack-specific roles**

```bash
mkdir -p packs/product-engineering/roles
for role in pm designer frontend backend devops mobile engineer dd-engineer new-user active-user churned-user; do
  git mv "roles/$role.md" "packs/product-engineering/roles/$role.md"
done
```

- [ ] **Step 2: Delete `investor`**

```bash
git rm roles/investor.md
```

- [ ] **Step 3: Verify final state**

```bash
echo "Core roles ($(ls roles/*.md | wc -l)):"
ls roles/*.md
echo
echo "Pack roles ($(ls packs/product-engineering/roles/*.md | wc -l)):"
ls packs/product-engineering/roles/*.md
```

Expected:
```
Core roles (9):
roles/a11y.md
roles/architect.md
roles/compliance.md
roles/devil-advocate.md
roles/planner.md
roles/security.md
roles/skeptic-owner.md
roles/tester.md
roles/user-simulator.md

Pack roles (11):
packs/product-engineering/roles/active-user.md
packs/product-engineering/roles/backend.md
packs/product-engineering/roles/churned-user.md
packs/product-engineering/roles/dd-engineer.md
packs/product-engineering/roles/designer.md
packs/product-engineering/roles/devops.md
packs/product-engineering/roles/engineer.md
packs/product-engineering/roles/frontend.md
packs/product-engineering/roles/mobile.md
packs/product-engineering/roles/new-user.md
packs/product-engineering/roles/pm.md
```

- [ ] **Step 4: Run tests — confirm role resolution still works**

The OPC tests that rely on mandatory roles (`test-guardrails.sh`, `test-mandatory-role.sh`) check for `skeptic-owner` and `compliance` which are Core (no move). Should still pass.

```bash
cd test && bash run-all.sh 2>&1 | tail -3
cd -
```

Expected: still `108 passed / 0 failed / 1 deferred`. **If any test starts failing**, the role lookup may be hardcoded to a specific role we moved — investigate and either flag to Stage 4 (when bf-run handles flow-level Pack role override) or restore the role to Core with a TODO.

- [ ] **Step 5: Update `UPSTREAM.md` delta log**

```
| 2026-05-17 | roles/* (9 kept, 11 moved to Pack, 1 deleted) | Stage 3: triage of 21 vendored OPC roles per docs/specs/2026-05-16-bf-fork-design/opc-role-mapping.md. Core retains: planner, architect, tester, security, a11y, compliance, devil-advocate, skeptic-owner, user-simulator. Pack receives: pm, designer, frontend, backend, devops, mobile, engineer, dd-engineer, new-user, active-user, churned-user. Deleted: investor (not in BF's path). |
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(bf): triage 21 vendored OPC roles into Core vs Pack

Stage 3 task 3.4. Per docs/specs/2026-05-16-bf-fork-design/opc-role-mapping.md:
keep 9 in Core roles/ (planner, architect, tester, security, a11y,
compliance, devil-advocate, skeptic-owner, user-simulator); move 11 to
packs/product-engineering/roles/ (pm, designer, frontend, backend,
devops, mobile, engineer, dd-engineer, new-user, active-user,
churned-user); delete investor (not in BF's path)."
```

---

### Task 3.5: Author `schemas/task.json`

The probe schema. Defines the task Work Object's state enum, required fields, and the wo.md content conventions. Source: `packs/product-engineering/reference-v6/bf-task-state-standard/SKILL.md` + `core-contracts.md` § Work Object minimum fields.

**Files:**
- Create: `packs/product-engineering/schemas/task.json`

- [ ] **Step 1: Read sources**

```bash
cat packs/product-engineering/reference-v6/bf-task-state-standard/SKILL.md
sed -n '/^## 1\. Work Object/,/^## 2\. Flow/p' docs/specs/2026-05-16-bf-fork-design/core-contracts.md
```

- [ ] **Step 2: Author the schema**

Schema shape (lift the WO field table from `core-contracts.md` § Work Object → Fields, then add Pack-specific bits):

```jsonc
{
  "id": "task",
  "pack": "product-engineering",
  "description": "A leaf-level product-engineering Work Object: one task, one PR, one acceptance loop.",
  "states": [
    "new",
    "shaped",
    "doing",
    "done"
  ],
  "default_desired_state": "done",
  "wo_md_sections": {
    "required": ["Objective", "Boundary", "Acceptance criteria"],
    "optional": ["Notes", "Four-piece", "References"]
  },
  "acceptance_lint_profile": "task",
  "capability_required_hints": ["implementation", "code-review", "verification"]
}
```

(Field names may evolve as we discover them in Stage 3's flow probes — the spec's open questions section in core-contracts.md flags this.)

- [ ] **Step 3: Verify**

```bash
node -e "JSON.parse(require('fs').readFileSync('packs/product-engineering/schemas/task.json'))" && echo "valid"
```

- [ ] **Step 4: Commit**

```bash
git add packs/product-engineering/schemas/task.json
git commit -m "feat(bf): author schemas/task.json for product-engineering Pack

Stage 3 task 3.5. Defines the task Work Object schema: states (new →
shaped → doing → done), required wo.md sections (Objective, Boundary,
Acceptance criteria), and capability hints. Source: bf-task-state-standard
+ core-contracts.md § Work Object.

Field set is intentionally minimal — Stage 3 probe flows pressure-test
this; if anything's missing it'll surface and we'll iterate."
```

---

### Task 3.6: Author 4 probe flows + protocols

The Stage 3 "probe" — one flow of each Core type, each backed by a protocol derived from v6 reference content. Their job is to **make the BF Core contracts real** and surface anything the spec didn't fully think through.

This is the longest task; budget for multiple sub-commits.

#### 3.6a — `brainstorm-task` flow + protocol

**Sources:** `reference-v6/bf-task-fourpiece/SKILL.md`, `reference-v6/bf-brainstorm/SKILL.md`, `pipeline/role-evaluator-prompt.md`.

**Files:**
- Create: `packs/product-engineering/flows/brainstorm-task.json`
- Create: `packs/product-engineering/protocols/brainstorm-task.md`

- [ ] **Step 1: Author flow JSON**

```jsonc
{
  "bf_compat": ">=0.1",
  "id": "brainstorm-task",
  "core_type": "brainstorm",
  "accepts": { "schema": ["task"], "current_state": ["new"] },
  "produces": { "desired_state": "shaped" },
  "nodes": ["discuss", "write-criteria", "criteria-lint", "gate"],
  "edges": {
    "discuss":        { "PASS": "write-criteria" },
    "write-criteria": { "PASS": "criteria-lint" },
    "criteria-lint":  { "PASS": "gate", "ITERATE": "write-criteria" },
    "gate":           { "PASS": null, "FAIL": "discuss", "ITERATE": "write-criteria" }
  },
  "nodeTypes": {
    "discuss": "discussion",
    "write-criteria": "build",
    "criteria-lint": "execute",
    "gate": "gate"
  },
  "limits": { "maxLoopsPerEdge": 3, "maxTotalSteps": 15, "maxNodeReentry": 5 },
  "rolesDir": "../../../roles",
  "protocolDir": "../protocols"
}
```

- [ ] **Step 2: Author the protocol**

Write `packs/product-engineering/protocols/brainstorm-task.md` deriving from `reference-v6/bf-task-fourpiece/SKILL.md` (the four-piece — what / why / boundary / verify — maps to the brainstorm's `discuss` and `write-criteria` nodes).

- [ ] **Step 3: Validate flow JSON via harness**

```bash
node bin/bf-harness.mjs viz --flow-file packs/product-engineering/flows/brainstorm-task.json 2>&1 | head -10
```

Expected: ASCII flow graph showing 4 nodes + edges. (If `viz` complains about `accepts`/`produces`/`core_type` fields it doesn't know, that's a finding — flag it in the commit body and continue. Harness may silently ignore unknown fields.)

- [ ] **Step 4: Commit**

```bash
git add packs/product-engineering/flows/brainstorm-task.json packs/product-engineering/protocols/brainstorm-task.md
git commit -m "feat(bf): probe flow brainstorm-task + protocol

Stage 3 task 3.6a. The first probe flow exercising BF Core's brainstorm
core_type. Derived from v6 bf-task-fourpiece + bf-brainstorm. Validates:
(1) flow.json shape with new BF additions (core_type, accepts, produces)
loads under bf-harness; (2) criteria-lint node calls bin/lib/criteria-lint.mjs
correctly; (3) flow graph viz renders."
```

#### 3.6b — `breakdown-milestone-to-task` flow + protocol

**Sources:** `reference-v6/bf-milestone-breakdown/SKILL.md`, `reference-v6/bf-implementation-design/SKILL.md`.

Mirror the structure of 3.6a:
- flow JSON: nodes `plan-children` (discussion) → `write-children` (build) → `review-breakdown` (review) → `gate`. `accepts: {schema: ["milestone"], current_state: ["shaped"]}`, `produces: {desired_state: "broken_down"}`. `core_type: "breakdown"`.
- protocol: derived from v6 milestone-breakdown content.

Same 4 sub-steps as 3.6a (author JSON / author protocol / viz validate / commit with "Stage 3 task 3.6b" + reasoning).

**Two specific things this probe pressure-tests:**
1. `write-children` should produce N child WO directories (`packs/product-engineering/reference-v6/bf-milestone-breakdown` describes how the breakdown produces task.md files — those become child wo.md). Does Core's `breakdown` core_type support this filesystem materialization? Find out and document.
2. Schema `milestone.json` doesn't exist yet (only `task.json`). Either author a minimal `milestone.json` here or document the gap and defer.

#### 3.6c — `loop-milestone` flow + protocol

**Sources:** `reference-v6/bf-milestone-progress/SKILL.md`.

- flow JSON: nodes `dispatch-children` (execute) → `await-children` (execute) → `aggregate` (review) → `gate`. `accepts: {schema: ["milestone"], current_state: ["broken_down"]}`, `produces: {desired_state: "children_done"}`. `core_type: "loop"`.
- protocol: how to recurse-execute child WOs respecting `depends_on`.

**Probe question this surfaces:** does the BF harness support "this node spawns child runs"? Almost certainly not — that's a Stage 4 dispatcher feature. The protocol may document the gap and note "this flow currently requires manual orchestration via bf-run when it lands in Stage 4". Stage 3 ships the flow JSON and protocol as the spec for what Stage 4 must implement.

#### 3.6d — `close-leaf-task` flow + protocol

**Sources:** `reference-v6/bf-task-execute/SKILL.md`, `reference-v6/bf-pr-review-flow/SKILL.md`, `reference-v6/bf-verification/SKILL.md`. Plus `pipeline/role-evaluator-prompt.md`.

This is the **most important probe** — it's the actual leaf implementation flow (implement → code-review → verify → gate), and OPC's `build-verify` template is its close cousin.

- flow JSON: nodes `implement` (build) → `code-review` (review) → `verify` (execute) → `gate`. `accepts: {schema: ["task"], current_state: ["doing"]}`, `produces: {desired_state: "done"}`. `core_type: "close"`.
- protocol: how the four roles (Dev / QA / PM / Architect, derived from v6 bf-team-roles) operate at each node.

Same 4 sub-steps as 3.6a per sub-task.

#### 3.6 wrap-up

After all 4 sub-tasks (3.6a–3.6d):

- [ ] **Sub-step W1: Find and document Core contract drifts**

While authoring the 4 protocols, the implementer almost certainly encountered cases where the Core contracts (work-object.md / flow.md / etc. in `references/`) didn't fully specify something the protocol needed. Document these in `docs/specs/2026-05-16-bf-fork-design/core-contracts.md` § Open questions of the relevant contract (e.g. WO § Open: "breakdown flow must materialize child directories — Core needs to specify whether harness or flow node performs the mkdir"). One commit per material finding.

- [ ] **Sub-step W2: Run full test suite**

```bash
cd test && bash run-all.sh 2>&1 | tail -3
cd -
```

Expected: still `108 passed / 0 failed / 1 deferred`. (No code changed; just JSON + Markdown content added.)

---

### Task 3.7: Stage 3 demo + retrospective

Make Stage 3 visible: pick a small existing task from `docs/tasks/` and run it through the bf-harness using `brainstorm-task` → `close-leaf-task` flows. Capture the resulting wo.md + runs/ as evidence.

**Files:**
- Create: `docs/specs/2026-05-17-stage-3-demo-trace.md` (the trace)

- [ ] **Step 1: Pick a demo task**

Use one of the smallest existing v6 tasks under `docs/tasks/` (or fabricate a 1-acceptance-criterion task) as the demo. Note its path.

- [ ] **Step 2: Run brainstorm-task by hand-driving bf-harness**

```bash
mkdir -p /tmp/bf-stage3-demo-wo/runs
node bin/bf-harness.mjs init \
  --flow-file packs/product-engineering/flows/brainstorm-task.json \
  --entry discuss \
  --dir /tmp/bf-stage3-demo-wo/runs/run-1 2>&1 | tail -5
```

Walk through each node, writing a handshake.json by hand (or use `bf-harness seal` if it works). At each transition:

```bash
node bin/bf-harness.mjs validate /tmp/bf-stage3-demo-wo/runs/run-1/nodes/<node>/handshake.json
node bin/bf-harness.mjs transition \
  --from <node> --to <next> --verdict PASS \
  --flow-file packs/product-engineering/flows/brainstorm-task.json \
  --dir /tmp/bf-stage3-demo-wo/runs/run-1
```

(The demo is **manual** — Stage 4 dispatcher will automate this. Right now we want to confirm the JSON flow + bf-harness mechanics still work under Pack-supplied flows.)

- [ ] **Step 3: Capture the trace**

Write `docs/specs/2026-05-17-stage-3-demo-trace.md`:

- What flow ran
- The handshakes at each node
- Where things tripped (likely several — Core probe!)
- What was learned about the contracts that doesn't match the references/ docs

- [ ] **Step 4: Retrospective**

In the trace document, end with a "Stage 4 must do" section listing every gap the demo surfaced. This becomes input to Stage 4's plan.

- [ ] **Step 5: Commit**

```bash
git add docs/specs/2026-05-17-stage-3-demo-trace.md /tmp/bf-stage3-demo-wo  # (only if the wo dir is worth committing as an artifact; usually not — it's process trace)
git commit -m "docs(spec): Stage 3 demo trace

Manually walks a small task through brainstorm-task → close-leaf-task
via bf-harness, documents handshake.json at each node, and lists the
Core contract gaps the demo surfaced. These become Stage 4's must-do
list."
```

(The wo home dir is process trace — commit only the trace markdown, not the runs/.)

---

## Stage 3 Definition of Done

- [ ] `packs/product-engineering/` populated: pack.json + README.md + 4 flows + 4 protocols + task.json schema + 11 Pack roles + 21 reference-v6 copies
- [ ] `pipeline/` has 7 vendored Core node protocols
- [ ] `roles/` has 9 Core-eligible roles (others moved or deleted)
- [ ] Stage 3 demo trace documents the manual walk-through
- [ ] Test suite still `108 passed / 0 failed / 1 deferred`
- [ ] All UPSTREAM.md delta entries written
- [ ] Stage 3 gaps documented as Open questions in `core-contracts.md` or as a "Stage 4 must do" list

## Self-Review Notes

- [ ] All file paths anchored at worktree root, no `./` confusion
- [ ] Each Task has commands the implementer can copy
- [ ] No "TBD" or "fill in details" — every step actionable
- [ ] Brand-rename details consistent with Stage 1+2 (no regression of opc-harness → bf-harness)

## Out of Scope (deferred)

- **Stage 4**: live `/bf` dispatcher (replaces `bin/bf.mjs` placeholder), `/opc <verb>` cleanup in vendored code, first npm publish
- **Stage 5**: end-to-end full-Pack demo (currently Stage 3's demo is just probe)
- **Stage 6**: remaining 17 v6 skills → Pack content, phase + milestone + blueprint schemas, retirements (bf-runtime-adapter etc.), v6 → v1 migration guide
