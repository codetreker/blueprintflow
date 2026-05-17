#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

ID="breakdown-smoke"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: milestone
current_state: shaped
desired_state: broken_down
pack: product-engineering
---

# breakdown smoke
EOF

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs breakdown "$ID" 2>&1)
echo "$OUT" | grep -q '"finalized":true' || { echo "FAIL: breakdown did not finalize"; echo "$OUT"; exit 1; }
grep -q 'current_state: broken_down' "$WO_HOME/$ID/wo.md" || { echo "FAIL: state not broken_down"; cat "$WO_HOME/$ID/wo.md"; exit 1; }
echo "PASS: breakdown shaped → broken_down"
