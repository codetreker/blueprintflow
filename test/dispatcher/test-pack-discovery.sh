#!/usr/bin/env bash
set -e

OUT=$(node -e "
  import('./bin/lib/dispatcher/pack-discovery.mjs').then(m => {
    m.discoverPacks().then(p => console.log(JSON.stringify(p)));
  });
")
echo "$OUT" | grep -q '"id":"product-engineering"' || { echo "FAIL: did not find product-engineering Pack"; exit 1; }
echo "$OUT" | grep -q '"version":"1.0.0-alpha"' || { echo "FAIL: did not read version from manifest"; exit 1; }
echo "PASS: pack-discovery found product-engineering Pack"
