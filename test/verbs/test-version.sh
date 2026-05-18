#!/usr/bin/env bash
set -e
EXPECTED=$(node -e "console.log(require('./package.json').version)")
ACTUAL=$(node bin/bf.mjs version)
[ "$ACTUAL" = "$EXPECTED" ] || { echo "FAIL: stdout='$ACTUAL' expected='$EXPECTED'"; exit 1; }
node bin/bf.mjs version >/dev/null || { echo "FAIL: exit code nonzero"; exit 1; }
node bin/bf.mjs help | grep -q version || { echo "FAIL: help missing version"; exit 1; }
echo "PASS: bf version prints $EXPECTED"
