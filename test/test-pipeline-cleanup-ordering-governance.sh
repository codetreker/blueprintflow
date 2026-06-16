#!/usr/bin/env bash
# Governance: no shipped engineering pipeline may instruct the coordinator to run
# cleanup "after Final Acceptance". Per-task cleanup runs immediately after
# `bf-harness complete` succeeds (see references/execution.md and feature.yml).
# The pipeline set is derived DYNAMICALLY from the pack directory so a future
# pipeline that reintroduces the stale ordering is also caught.
set -u
source "$(dirname "$0")/test-helpers.sh"

PIPELINE_DIR="$REPO_ROOT/packs/engineering/pipelines"
[ -d "$PIPELINE_DIR" ] || fail "missing engineering pipeline dir: $PIPELINE_DIR"

shopt -s nullglob
PIPELINES=( "$PIPELINE_DIR"/*.yml )
shopt -u nullglob
[ "${#PIPELINES[@]}" -gt 0 ] || fail "no engineering pipelines found under $PIPELINE_DIR"

OFFENDERS=()
for f in "${PIPELINES[@]}"; do
  # Match cleanup-ordering text regardless of case; the stale phrase couples
  # "cleanup" with "after Final Acceptance".
  if grep -qiE "cleanup after final acceptance" "$f"; then
    OFFENDERS+=( "$(basename "$f")" )
  fi
done

if [ "${#OFFENDERS[@]}" -gt 0 ]; then
  fail "pipeline(s) instruct cleanup 'after Final Acceptance' (must be 'after bf-harness complete succeeds'): ${OFFENDERS[*]}"
fi

# Positive anchor: the one pipeline that names a cleanup-ordering rule should
# point cleanup at `complete`, not Final Acceptance.
CDA="$PIPELINE_DIR/code-deep-audit.yml"
[ -f "$CDA" ] || fail "missing code-deep-audit pipeline"
grep -qi "cleanup after bf-harness complete succeeds" "$CDA" \
  || fail "code-deep-audit.yml should run cleanup after 'bf-harness complete succeeds'"

pass
