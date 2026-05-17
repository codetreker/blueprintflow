#!/bin/bash
set -e

source "$(dirname "$0")/test-helpers.sh"
setup_tmpdir
setup_git

echo "Test: Negative — Handshake Validation"
echo "================================================"
echo ""

$HARNESS init --flow build-verify --entry build --dir .bf 2>/dev/null >/dev/null

# ── Test 1: missing required fields ──
echo "1. validate rejects handshake missing nodeId"
mkdir -p .bf/nodes/build
cat > .bf/nodes/build/handshake.json <<'EOF'
{"nodeType":"build","runId":"run_1","status":"completed","verdict":"PASS","summary":"ok","timestamp":"2026-01-01T00:00:00.000Z","artifacts":[{"type":"code","path":"x"}]}
EOF
touch .bf/nodes/build/x
VAL=$($HARNESS validate --node build --dir .bf 2>/dev/null || true)
VALID=$(echo "$VAL" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('valid', d.get('passed', 'missing')))" 2>/dev/null)
if [ "$VALID" = "False" ] || [ "$VALID" = "false" ]; then
  echo "  ✅ missing nodeId rejected"
  PASS=$((PASS + 1))
else
  echo "  ❌ valid=$VALID output=$VAL"
  FAIL=$((FAIL + 1))
fi

# ── Test 2: invalid nodeType ──
echo "2. validate rejects invalid nodeType"
cat > .bf/nodes/build/handshake.json <<'EOF'
{"nodeId":"build","nodeType":"banana","runId":"run_1","status":"completed","verdict":"PASS","summary":"ok","timestamp":"2026-01-01T00:00:00.000Z","artifacts":[{"type":"code","path":"x"}]}
EOF
VAL2=$($HARNESS validate --node build --dir .bf 2>/dev/null || true)
VALID2=$(echo "$VAL2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('valid', d.get('passed', 'missing')))" 2>/dev/null)
if [ "$VALID2" = "False" ] || [ "$VALID2" = "false" ]; then
  echo "  ✅ invalid nodeType rejected"
  PASS=$((PASS + 1))
else
  echo "  ❌ valid=$VALID2"
  FAIL=$((FAIL + 1))
fi

# ── Test 3: artifacts not array ──
echo "3. validate rejects non-array artifacts"
cat > .bf/nodes/build/handshake.json <<'EOF'
{"nodeId":"build","nodeType":"build","runId":"run_1","status":"completed","verdict":"PASS","summary":"ok","timestamp":"2026-01-01T00:00:00.000Z","artifacts":"not-array"}
EOF
VAL3=$($HARNESS validate --node build --dir .bf 2>/dev/null || true)
VALID3=$(echo "$VAL3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('valid', d.get('passed', 'missing')))" 2>/dev/null)
if [ "$VALID3" = "False" ] || [ "$VALID3" = "false" ]; then
  echo "  ✅ non-array artifacts rejected"
  PASS=$((PASS + 1))
else
  echo "  ❌ valid=$VALID3"
  FAIL=$((FAIL + 1))
fi

# ── Test 4: review node with <2 eval artifacts ──
echo "4. validate rejects review node with only 1 eval"
mkdir -p .bf/nodes/code-review
cat > .bf/nodes/code-review/handshake.json <<'EOF'
{"nodeId":"code-review","nodeType":"review","runId":"run_1","status":"completed","verdict":"PASS","summary":"ok","timestamp":"2026-01-01T00:00:00.000Z","artifacts":[{"type":"eval","path":"eval-a.md"}]}
EOF
echo "# Eval A" > .bf/nodes/code-review/eval-a.md
VAL4=$($HARNESS validate --node code-review --dir .bf 2>/dev/null || true)
VALID4=$(echo "$VAL4" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('valid', d.get('passed', 'missing')))" 2>/dev/null)
if [ "$VALID4" = "False" ] || [ "$VALID4" = "false" ]; then
  echo "  ✅ review with <2 evals rejected"
  PASS=$((PASS + 1))
else
  echo "  ❌ valid=$VALID4"
  FAIL=$((FAIL + 1))
fi

print_results
