#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

ID="loop-smoke"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: milestone
current_state: broken_down
desired_state: children_done
pack: product-engineering
---

# loop smoke
EOF

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs loop "$ID" 2>&1)
RC=$?
[ $RC -eq 0 ] || { echo "FAIL: loop exit $RC"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q '"deferred":true' || { echo "FAIL: loop did not defer"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q 'Stage 5' || { echo "FAIL: missing Stage 5 hint"; echo "$OUT"; exit 1; }
echo "PASS: loop deferred to Stage 5"
