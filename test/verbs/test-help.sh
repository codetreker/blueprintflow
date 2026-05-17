#!/usr/bin/env bash
set -e
OUT=$(node bin/bf.mjs help 2>&1)
echo "$OUT" | grep -q 'execute' || { echo "FAIL: help missing 'execute' verb"; exit 1; }
echo "$OUT" | grep -q 'create' || { echo "FAIL: help missing 'create' verb"; exit 1; }
OUT=$(node bin/bf.mjs help execute 2>&1)
echo "$OUT" | grep -q -i 'desired_state' || { echo "FAIL: help execute missing semantic hint"; exit 1; }
echo "PASS: help and help <verb> work"
