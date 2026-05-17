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

## Deferred to Stage 4 (bf-run skill)

User-visible slash-command strings still reference `/opc` (e.g. `flow-escape.mjs` "SKIPPED via /opc skip", "/opc pass only works on gates", "Use /opc skip instead", and `loop-advance.mjs` "Execute unit … using /opc …"). These belong to the dispatcher UX, which is replaced by the `bf-run` skill in Stage 4. They will be swept at that time.

Search to find them later: `grep -rn '/opc ' plugins/bf/runtime/ --include='*.mjs'`
