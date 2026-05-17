#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$DIR"' EXIT

# Use a fake Pack manifest declaring `compliance` as mandatory
mkdir -p "$DIR/fake-pack"
cat > "$DIR/fake-pack/pack.json" <<EOF
{"bf_compat":">=0.1","id":"fake","version":"1","mandatory_roles":["compliance"],"routing":{},"state_aliases":{}}
EOF

$HARNESS init --flow review --entry review --dir "$DIR" --pack "$DIR/fake-pack/pack.json" >/dev/null 2>&1 || true
mkdir -p "$DIR/nodes/review/run_1"
cat > "$DIR/nodes/review/run_1/eval-tester.md" <<EOF
# tester eval
**PASS**
notes: tester-side check ok
EOF
cat > "$DIR/nodes/review/run_1/eval-security.md" <<EOF
# security eval
**PASS**
notes: security-side check ok, no findings
EOF
$HARNESS seal --node review --dir "$DIR" >/dev/null

# Transition should refuse because `compliance` (Pack-declared mandatory) is missing
OUT=$($HARNESS transition --from review --to gate --verdict PASS --flow review --dir "$DIR" --pack "$DIR/fake-pack/pack.json" 2>&1) || true
if echo "$OUT" | grep -q 'Missing mandatory role.*compliance'; then
  echo "PASS: Pack-declared mandatory role enforced"
else
  echo "FAIL: Pack mandatory_roles ignored"
  echo "  got: $OUT"
  exit 1
fi
