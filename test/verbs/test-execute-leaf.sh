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

# With Stage 6.1 routing (task,shaped → close-leaf-task), execute drives
# the WO new → shaped → doing → done in a single invocation under stub agents.
OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
grep -q 'current_state: done' "$WO_HOME/$ID/wo.md" || {
  echo "FAIL: execute did not drive new → done"
  echo "$OUT"
  cat "$WO_HOME/$ID/wo.md"
  exit 1
}

echo "PASS: execute drove new → shaped → doing → done (single call)"
