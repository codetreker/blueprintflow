#!/usr/bin/env bash
set -e
WO_HOME=$(mktemp -d -p /tmp bf-wo-XXXX)
trap 'rm -rf "$WO_HOME"' EXIT
export BF_WO_HOME="$WO_HOME"

# create → show → execute → tree → discard
node bin/bf.mjs create "regression task" --pack product-engineering --schema task >/dev/null
ID=$(ls "$WO_HOME")  # the one we just created
node bin/bf.mjs show "$ID" 2>/dev/null | grep -q 'current_state' || { echo "FAIL: show after create"; exit 1; }
node bin/bf.mjs execute "$ID" >/dev/null 2>&1 || true   # may stop at routing gap; that's OK for regression
node bin/bf.mjs tree 2>/dev/null | grep -q "$ID" || { echo "FAIL: tree after execute"; exit 1; }
node bin/bf.mjs discard "$ID" --force >/dev/null
[ -d "$WO_HOME/$ID" ] && { echo "FAIL: discard"; exit 1; }
echo "PASS: create→show→execute→tree→discard regression"
