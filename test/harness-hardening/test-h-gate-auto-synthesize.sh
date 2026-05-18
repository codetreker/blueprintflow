#!/usr/bin/env bash
set -e
# Stage 6.1 finding #3: gate-type nodes must auto-synthesize verdict
# from upstream evals; they must NOT return `agents-needed`.
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

ID="gate-auto-synth"
mkdir -p "$WO_HOME/$ID"
cat > "$WO_HOME/$ID/wo.md" <<EOF
---
schema: task
current_state: doing
desired_state: done
pack: product-engineering
---
# gate auto-synth
## Acceptance criteria
- [ ] gate node seals without returning agents-needed
EOF

# First envelope.
OUT=$(BF_ORCHESTRATOR=skill node bin/bf.mjs execute "$ID" 2>&1)

SAW_GATE_AGENTS_NEEDED=no
ITER=0
while [ $ITER -lt 15 ]; do
  ITER=$((ITER + 1))
  if echo "$OUT" | grep -q 'current_state: done\|"done":true\|"finalized":true'; then
    :
  fi
  if grep -q 'current_state: done' "$WO_HOME/$ID/wo.md"; then
    break
  fi
  if ! echo "$OUT" | grep -q '"status":"agents-needed"'; then
    echo "FAIL: stuck without agents-needed and not done"
    echo "$OUT"
    exit 1
  fi

  NODE_ID=$(echo "$OUT" | grep -o '"nodeId":"[^"]*"' | head -1 | sed 's/.*"nodeId":"\([^"]*\)".*/\1/')
  NODE_TYPE=$(echo "$OUT" | grep -o '"nodeType":"[^"]*"' | head -1 | sed 's/.*"nodeType":"\([^"]*\)".*/\1/')
  RUN_DIR=$(echo "$OUT" | grep -o '"runDir":"[^"]*"' | head -1 | sed 's/.*"runDir":"\([^"]*\)".*/\1/')

  if [ "$NODE_TYPE" = "gate" ]; then
    SAW_GATE_AGENTS_NEEDED=yes
    break
  fi

  for f in $(echo "$OUT" | grep -o '"eval-[^"]*\.md"' | tr -d '"'); do
    cat > "$RUN_DIR/$f" <<E2
---
role: $(echo "$f" | sed 's/eval-//;s/\.md//')
verdict: PASS
---
**PASS**
synthetic
E2
  done
  if [ "$NODE_TYPE" = "execute" ]; then
    echo "ok" > "$RUN_DIR/cli-output.log"
  fi

  OUT=$(BF_ORCHESTRATOR=skill BF_RESUME_NODE="$NODE_ID" node bin/bf.mjs execute "$ID" 2>&1)
done

if [ "$SAW_GATE_AGENTS_NEEDED" = "yes" ]; then
  echo "FAIL: gate node returned agents-needed envelope (finding #3 not fixed)"
  exit 1
fi

if ! grep -q 'current_state: done' "$WO_HOME/$ID/wo.md"; then
  echo "FAIL: WO did not finalize to done"
  cat "$WO_HOME/$ID/wo.md"
  exit 1
fi

echo "PASS: gate node auto-synthesized; WO reached done without agent dispatch on gates"
