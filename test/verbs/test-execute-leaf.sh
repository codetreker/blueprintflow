#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

ID="exec-smoke-test"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: new
desired_state: done
pack: product-engineering
---

# exec smoke test
EOF

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
grep -q 'current_state: shaped' "$WO_HOME/$ID/wo.md" || { echo "FAIL: brainstorm did not advance to shaped"; echo "$OUT"; cat "$WO_HOME/$ID/wo.md"; exit 1; }

# v0.2 routing gap: shaped → doing transition is manual until Stage 5.
sed -i 's/current_state: shaped/current_state: doing/' "$WO_HOME/$ID/wo.md"

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
grep -q 'current_state: done' "$WO_HOME/$ID/wo.md" || {
  echo "FAIL: close-leaf-task did not advance to done"
  echo "$OUT"
  exit 1
}

echo "PASS: execute drove new → shaped → (manual) → doing → done"
