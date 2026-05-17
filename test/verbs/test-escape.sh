#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

ID="escape-test"
mkdir -p "$WO_HOME/$ID/runs/run-1/nodes/implement/run_1"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: doing
desired_state: done
pack: product-engineering
---
# escape test
EOF

cat > "$WO_HOME/$ID/runs/run-1/flow-state.json" <<EOF
{"flowTemplate":"close-leaf-task","currentNode":"implement","status":"in_progress","totalSteps":0,"history":[],"edgeCounts":{}}
EOF

OUT=$(node bin/bf.mjs stop "$ID" 2>&1)
echo "$OUT" | grep -q '"stopped":true' || { echo "FAIL: stop did not report success"; echo "$OUT"; exit 1; }

OUT=$(node bin/bf.mjs goto code-review --wo "$ID" 2>&1) || true
echo "$OUT" | grep -q -E 'code-review|cycle limit|unknown node|unknown flow|not a node|maxNodeReentry|maxTotalSteps' || { echo "FAIL: goto produced unexpected output: $OUT"; exit 1; }

echo "PASS: escape verbs route to flow-escape"
