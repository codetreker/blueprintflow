#!/usr/bin/env bash
set -e
ACTUAL=$(node bin/bf.mjs greeting)
[ "$ACTUAL" = "hello, blueprintflow!" ] || { echo "FAIL: stdout='$ACTUAL'"; exit 1; }
node bin/bf.mjs greeting >/dev/null || { echo "FAIL: exit code"; exit 1; }
node bin/bf.mjs help | grep -q greeting || { echo "FAIL: help missing"; exit 1; }
echo "PASS: bf greeting"
