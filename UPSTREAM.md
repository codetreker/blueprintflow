# UPSTREAM — OPC Fork Provenance

BF's `runtime/` and `test/` directories were vendored from OPC at the fork point below. We do not auto-pump from upstream; cherry-picks are documented in the delta log.

## Fork point

- Source: https://github.com/iamtouchskyer/opc (local clone at `/workspace/opc`)
- Commit: bf7910aa38a5310cb8ac392472b87568c5d7c779
- HARNESS_VERSION at fork: 0.10.0 (see runtime/lib/flow-templates.mjs)
- Files vendored verbatim:
  - `bin/opc-harness.mjs` → `runtime/opc-harness.mjs` (entry file renamed to `bf-harness.mjs` in Task 1.4; the rename is recorded in the delta log below)
  - `bin/lib/*.mjs` (40 files) → `runtime/lib/*.mjs`
  - `test/run-all.sh` + `test/test-*.sh` (110 scripts) + `test/test-helpers.sh` + `test/fixtures/`
  - `roles/*.md` (21 files)
  - `pipeline/*.md` (7 files)

Note: the fork plan estimated 111 `test-*.sh` scripts; actual count at the
captured SHA is 110. The plan's count appears to have included `run-all.sh`
or `test-helpers.sh` in the total. No scripts are missing — all `test-*.sh`
files present in upstream were copied.

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
| 2026-05-17 | roles/*.md (21 files), test/deferred-tests.txt, test/run-all.sh | Vendor OPC roles so harness mandatory-role checks work; add a skip-by-name mechanism to run-all.sh and defer test-install-hooks.sh (depends on bin/opc.mjs which is not vendored). Discovered during Task 1.3 baseline run. |
| 2026-05-17 | runtime/*.mjs (rename map), test/*.sh (rename map), runtime/lib/clean.mjs (BF_DIR_PATTERN) | Brand renames per spec § 'Replaced (brand words)': opc-harness → bf-harness; .harness → .bf (with .harness still recognized for legacy cleanup in clean.mjs); ~/.opc → ~/.bf; opc_compat → bf_compat; OPC_* env vars → BF_*; user-visible help text 'OPC' → 'BF'. Generic vocabulary (flow / node / verdict / handshake / gate / route / transition / synthesize / FLOW_TEMPLATES / HARNESS_VERSION) kept. Suite remains at 108 passed / 0 failed / 1 deferred. |
| 2026-05-17 | repo layout (runtime/→bin/, core/→references/, plugins/bf/ → root), +package.json +SKILL.md +scripts/postinstall.mjs +bin/bf.mjs +pipeline/.gitkeep | Reorganized from plugin form to bare-skill + npm form (@codetreker/bf). Mirrors OPC's distribution model. .claude-plugin/marketplace.json no longer registers bf — npm is the only distribution channel. Tests still 108/0/1 under new layout. |
| 2026-05-17 | pipeline/{gate-protocol,handoff-template,criteria-lint,report-format,context-brief,role-evaluator-prompt,evaluator-prompt}.md, pipeline/README.md | Stage 3: vendor 7 Core node protocols from OPC pipeline/. Pack-specific protocols (implementer-prompt, executor-protocol, discussion-protocol, test-design-protocol, ux-*) intentionally not vendored — they belong inside each Pack's protocols/ folder. |
| 2026-05-17 | roles/* (9 kept, 11 moved to packs/product-engineering/roles/, 1 deleted), test/test-guardrails.sh (fixture rename) | Stage 3 task 3.4: triage of 21 vendored OPC roles per docs/specs/2026-05-16-bf-fork-design/opc-role-mapping.md. Core retains: planner, architect, tester, security, a11y, compliance, devil-advocate, skeptic-owner, user-simulator. Pack receives: pm, designer, frontend, backend, devops, mobile, engineer, dd-engineer, new-user, active-user, churned-user. Deleted: investor (not in BF's path). test-guardrails.sh fixtures swapped engineer/frontend → tester/security (the original choice was incidental; mandatory-role enforcement mechanism is what's under test). |
| 2026-05-17 | bin/lib/{flow-escape,runbooks,loop-advance}.mjs | Stage 4 task 4.1: sweep 9 deferred `/opc <verb>` user-facing strings to `/bf <verb>`. The literal word "OPC" referring to the upstream project name is unchanged. |
| 2026-05-17 | bin/lib/{util,flow-core,flow-transition,viz-commands}.mjs, packs/product-engineering/{pack.json,protocols/*.md}, test/{run-all.sh,test-seal-advance.sh,harness-hardening/test-{a,b,c,d,e,f}-*.sh} | Stage 4 task 4.2: harden bf-harness per Stage 3 demo findings. Six sub-tasks, each TDD'd: (a) 998abe2 widen `--dir` sandbox to accept `$TMPDIR/bf-*`; (b) d108969 seal auto-creates `nodes/<id>/run_1/` and hard-fails on empty artifact set; (c) 708e14b inference regex accepts bare `eval.md` (`^eval(-.+)?\.md$`) + 4 Pack protocols document the `eval-<role>.md` convention; (d) c7dd08b seal returns `sealed:false` when `validationErrors` non-empty (test-seal-advance group 1 fixture updated — the old lenient sealed:true on validator errors was a footgun); (e) 7bedcb0 Pack-overridable `mandatory_roles` via new `--pack` flag, product-engineering pack.json declares `["skeptic-owner"]` explicitly; (f) 5dc70dc viz renders all non-PASS back-edges per node (was: dropped second back-edge when both FAIL and ITERATE were present). Suite: 108 → 114 passed / 0 failed. |

## Deferred to Stage 4 (bf-run skill)

(Section closed: Stage 4 swept all 9 deferred `/opc <verb>` user-facing
strings to `/bf <verb>` in commit 3f155a7. Search to confirm later:
`grep -rn '/opc ' bin/lib/`.)
