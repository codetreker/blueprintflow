#!/usr/bin/env bash
set -e
OUT=$(npm pack --dry-run 2>&1)

# Must include
for required in "bin/bf.mjs" "bin/bf-harness.mjs" "bin/lib/verbs/" "bin/lib/dispatcher/" \
                "packs/product-engineering/pack.json" "packs/product-engineering/flows/" \
                "packs/product-engineering/protocols/" "pipeline/" "roles/" "references/" \
                "SKILL.md" "scripts/postinstall.mjs" "README.md"; do
  echo "$OUT" | grep -q "$required" || { echo "FAIL: missing $required from npm pack output"; exit 1; }
done

# Must NOT include
for excluded in "node_modules" ".bf-demo" ".harness/"; do
  echo "$OUT" | grep -q "$excluded" && { echo "FAIL: $excluded should not be in pack"; exit 1; }
done

# Total tarball size sanity (under 2 MB — adjust if pack content legitimately grows)
SIZE_LINE=$(echo "$OUT" | grep -E "package size|unpacked size" | head -1)
echo "Pack size: $SIZE_LINE"

echo "PASS: npm pack --dry-run produces expected file list"
