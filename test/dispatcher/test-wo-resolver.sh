#!/usr/bin/env bash
set -e

# Setup a fake WO home under TMPDIR
WO_HOME=$(mktemp -d -p /tmp bf-wo-test-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

mkdir -p "$WO_HOME/auth-v1/login"
cat > "$WO_HOME/auth-v1/wo.md" <<EOF
---
schema: blueprint
current_state: shaped
pack: product-engineering
---
# Auth v1
EOF
cat > "$WO_HOME/auth-v1/login/wo.md" <<EOF
---
schema: task
current_state: new
pack: product-engineering
---
# Login subtask
EOF

OUT=$(BF_WO_HOME="$WO_HOME" node -e "
  import('./bin/lib/dispatcher/wo-resolver.mjs').then(m => {
    m.resolveWo('auth-v1/login').then(r => console.log(JSON.stringify(r)));
  });
")

echo "$OUT" | grep -q '"schema":"task"' || { echo "FAIL: wrong schema"; exit 1; }
echo "$OUT" | grep -q '"current_state":"new"' || { echo "FAIL: wrong state"; exit 1; }
echo "$OUT" | grep -q '"exists":true' || { echo "FAIL: exists flag"; exit 1; }

# Missing intermediate wo.md → invalid path
rm "$WO_HOME/auth-v1/wo.md"
OUT=$(BF_WO_HOME="$WO_HOME" node -e "
  import('./bin/lib/dispatcher/wo-resolver.mjs').then(m => {
    m.resolveWo('auth-v1/login').then(r => console.log(JSON.stringify(r)));
  });
")
echo "$OUT" | grep -q '"exists":false' || { echo "FAIL: should reject broken chain"; exit 1; }

echo "PASS: wo-resolver handles valid + broken chain"
