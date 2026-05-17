#!/usr/bin/env bash
set -e

OUT=$(node bin/bf.mjs pack list 2>&1)
echo "$OUT" | grep -q 'product-engineering' || { echo "FAIL: pack list missing product-engineering"; echo "$OUT"; exit 1; }

OUT=$(node bin/bf.mjs pack info product-engineering 2>&1)
echo "$OUT" | grep -q '"version":"1.0.0-alpha"' || { echo "FAIL: pack info missing version"; echo "$OUT"; exit 1; }

OUT=$(node bin/bf.mjs flow list product-engineering 2>&1)
echo "$OUT" | grep -q 'close-leaf-task' || { echo "FAIL: flow list missing close-leaf-task"; echo "$OUT"; exit 1; }

OUT=$(node bin/bf.mjs flow viz brainstorm-task 2>&1)
echo "$OUT" | grep -q 'discuss' || { echo "FAIL: flow viz did not render nodes"; echo "$OUT"; exit 1; }

echo "PASS: pack/flow meta verbs work"
