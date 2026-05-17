#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

# Create a leaf task at state 'doing' (skips the brainstorm step)
ID="orch-shape-test"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: doing
desired_state: done
pack: product-engineering
---

# orch shape test

## Objective
verify the orchestrator envelope shape.

## Boundary
shape-only — no real agents called.

## Acceptance criteria
- node-runner under BF_ORCHESTRATOR=skill returns agents-needed envelope
EOF

OUT=$(BF_ORCHESTRATOR=skill BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
echo "$OUT" | grep -q '"status":"agents-needed"' || { echo "FAIL: missing agents-needed envelope"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q '"roles":' || { echo "FAIL: missing roles list"; exit 1; }
echo "$OUT" | grep -q '"expectedArtifacts":' || { echo "FAIL: missing expectedArtifacts"; exit 1; }
echo "$OUT" | grep -q '"runDir":' || { echo "FAIL: missing runDir"; exit 1; }
echo "$OUT" | grep -q '"nodeId":' || { echo "FAIL: missing nodeId"; exit 1; }
echo "$OUT" | grep -q '"nodeType":' || { echo "FAIL: missing nodeType"; exit 1; }
echo "$OUT" | grep -q '"woPath":' || { echo "FAIL: missing woPath"; exit 1; }
echo "$OUT" | grep -q '"flowFile":' || { echo "FAIL: missing flowFile"; exit 1; }

echo "PASS: orchestrator envelope shape correct"

# Simulate orchestrator: write the expected artifacts, then re-invoke with BF_RESUME_NODE
RUN_DIR=$(echo "$OUT" | grep -o '"runDir":"[^"]*"' | head -1 | sed 's/.*"runDir":"\([^"]*\)"/\1/')
NODE_ID=$(echo "$OUT" | grep -o '"nodeId":"[^"]*"' | head -1 | sed 's/.*"nodeId":"\([^"]*\)"/\1/')
for r in $(echo "$OUT" | grep -o 'eval-[a-zA-Z0-9_-]*\.md'); do
  role=$(echo "$r" | sed 's/eval-//;s/\.md//')
  cat > "$RUN_DIR/$r" <<EOF
---
role: $role
verdict: PASS
---
synthetic resume test
EOF
done

OUT2=$(BF_ORCHESTRATOR=skill BF_RESUME_NODE=$NODE_ID BF_WO_HOME="$WO_HOME" node bin/bf.mjs execute "$ID" 2>&1)
# After resume-node, the run should advance past the node (new agents-needed for next node, or finalized)
echo "$OUT2" | grep -q '"status":"agents-needed"\|"finalized":true\|"done":true' || { echo "FAIL: resume did not advance"; echo "$OUT2"; exit 1; }
echo "PASS: --resume-node advances correctly"
