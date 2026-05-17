#!/usr/bin/env bash
set -e
HARNESS="node bin/bf-harness.mjs"
FLOW=packs/product-engineering/flows/brainstorm-task.json

OUT=$($HARNESS viz --flow-file "$FLOW")
# The brainstorm-task flow has back-edges on both `criteria-lint` (ITERATE)
# and `gate` (FAIL and ITERATE). The renderer must surface both literal
# verdict strings somewhere in the ASCII output. Pre-fix, the renderer
# preferred FAIL over ITERATE on the gate row and dropped the second
# back-edge — gate showed only `← FAIL → discuss`, so ITERATE still appeared
# (from criteria-lint) but the gate's own ITERATE back-edge was hidden.
echo "$OUT" | grep -q 'ITERATE' || {
  echo "FAIL: viz did not render ITERATE back-edges"
  echo "  got: $OUT"
  exit 1
}
echo "$OUT" | grep -q 'FAIL' || {
  echo "FAIL: viz did not render FAIL back-edges"
  echo "  got: $OUT"
  exit 1
}
# Gate row must include BOTH of its back-edges (FAIL → discuss AND ITERATE → write-criteria)
GATE_REGION=$(echo "$OUT" | grep -A1 -E '^\s*[○▶✅]\s+gate\b' | head -2)
echo "$GATE_REGION" | grep -q 'FAIL' || {
  echo "FAIL: gate row missing FAIL back-edge"
  echo "  gate region: $GATE_REGION"
  exit 1
}
echo "$GATE_REGION" | grep -q 'ITERATE' || {
  echo "FAIL: gate row missing ITERATE back-edge (only one back-edge rendered)"
  echo "  gate region: $GATE_REGION"
  exit 1
}
echo "PASS: viz renders both ITERATE and FAIL back-edges (including gate's multi-back-edges)"
