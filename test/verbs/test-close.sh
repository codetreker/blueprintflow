#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

ID="close-smoke"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: doing
desired_state: done
pack: product-engineering
---

# close smoke
EOF

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs close "$ID" 2>&1)
echo "$OUT" | grep -q '"finalized":true' || { echo "FAIL: close did not finalize"; echo "$OUT"; exit 1; }
grep -q 'current_state: done' "$WO_HOME/$ID/wo.md" || { echo "FAIL: state not done"; cat "$WO_HOME/$ID/wo.md"; exit 1; }
echo "PASS: close doing → done"
