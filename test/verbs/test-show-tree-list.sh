#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

# Setup 3 WOs
for i in 1 2 3; do
  mkdir -p "$WO_HOME/wo-$i"
  cat > "$WO_HOME/wo-$i/wo.md" <<EOF
---
schema: task
current_state: $([ $i -eq 1 ] && echo new || echo doing)
desired_state: done
pack: product-engineering
---
# wo-$i
EOF
done

# show
OUT=$(node bin/bf.mjs show wo-1 2>&1)
echo "$OUT" | grep -q "wo-1" || { echo "FAIL: show missing wo-1"; exit 1; }
echo "$OUT" | grep -q "current_state.*new" || { echo "FAIL: show missing state"; exit 1; }

# tree
OUT=$(node bin/bf.mjs tree 2>&1)
echo "$OUT" | grep -q "wo-1" && echo "$OUT" | grep -q "wo-2" && echo "$OUT" | grep -q "wo-3" || { echo "FAIL: tree missing entries"; exit 1; }

# list with state filter
OUT=$(node bin/bf.mjs list --state doing 2>&1)
echo "$OUT" | grep -q "wo-2" || { echo "FAIL: list --state doing missing wo-2"; exit 1; }
echo "$OUT" | grep -q "wo-1" && { echo "FAIL: list --state doing should not include wo-1"; exit 1; }

# discard
node bin/bf.mjs discard wo-3 --force >/dev/null
[ -d "$WO_HOME/wo-3" ] && { echo "FAIL: discard did not remove wo-3"; exit 1; }

echo "PASS: show/tree/list/discard all behave"
