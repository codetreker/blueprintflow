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
echo "$OUT" | grep -q '"verdict"' && echo "$OUT" | grep -q 'eval.md' || true
# Read handshake to confirm type
TYPE=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$DIR/nodes/review/handshake.json','utf8')).artifacts.find(a=>a.path.endsWith('eval.md')).type)")
if [ "$TYPE" != "eval" ]; then
  echo "FAIL: eval.md was not inferred as type 'eval' (got: $TYPE)"
  echo "  seal output: $OUT"
  exit 1
fi
echo "PASS: eval.md inferred as type 'eval'"
