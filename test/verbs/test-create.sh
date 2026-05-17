#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT

OUT=$(BF_WO_HOME="$WO_HOME" node bin/bf.mjs create "test-task-1" --pack product-engineering --schema task 2>&1)
echo "$OUT" | grep -q '"created":true' || { echo "FAIL: create did not report success"; echo "$OUT"; exit 1; }
[ -f "$WO_HOME/test-task-1/wo.md" ] || { echo "FAIL: wo.md not created"; exit 1; }
grep -q 'schema: task' "$WO_HOME/test-task-1/wo.md" || { echo "FAIL: schema not written"; exit 1; }
grep -q 'current_state: new' "$WO_HOME/test-task-1/wo.md" || { echo "FAIL: state not new"; exit 1; }
echo "PASS: create scaffolded ~/.bf/wo/test-task-1/wo.md"
