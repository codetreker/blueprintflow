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
