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
if echo "$OUT" | grep -q '"sealed":true'; then
  echo "FAIL: sealed:true returned with non-empty validationErrors"
  echo "  got: $OUT"
  exit 1
fi
echo "PASS: sealed:false when validationErrors non-empty"
