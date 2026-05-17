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
