#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
# Use a fake wo directory under ~/.bf/wo/
WO_DIR="$HOME/.bf/wo/__sandbox-test__/runs/run-1"
rm -rf "$HOME/.bf/wo/__sandbox-test__"
mkdir -p "$WO_DIR"
trap 'rm -rf "$HOME/.bf/wo/__sandbox-test__"' EXIT

OUT=$($HARNESS init --flow review --entry review --dir "$WO_DIR" 2>&1) || true
if echo "$OUT" | grep -q "outside cwd"; then
  echo "FAIL: --dir sandbox rejects ~/.bf/wo/<id>/runs/ path"
  echo "  got: $OUT"
  exit 1
fi
echo "PASS: --dir ~/.bf/wo/<id>/runs/ accepted"
