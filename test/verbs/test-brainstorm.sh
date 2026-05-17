#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

ID="brainstorm-smoke"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: new
desired_state: shaped
pack: product-engineering
---

# brainstorm smoke
EOF

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs brainstorm "$ID" 2>&1)
echo "$OUT" | grep -q '"finalized":true' || { echo "FAIL: brainstorm did not finalize"; echo "$OUT"; exit 1; }
grep -q 'current_state: shaped' "$WO_HOME/$ID/wo.md" || { echo "FAIL: state not shaped"; cat "$WO_HOME/$ID/wo.md"; exit 1; }
echo "PASS: brainstorm new → shaped"
