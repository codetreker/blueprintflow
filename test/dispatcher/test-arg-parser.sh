#!/usr/bin/env bash
set -e

run() {
  node -e "
    import('./bin/lib/dispatcher/arg-parser.mjs').then(m => {
      const out = m.parseArgs($1);
      console.log(JSON.stringify(out));
    });
  "
}

# Test 1: execute with positional + flag
OUT=$(run '["execute","auth-v1/login","--one-step"]')
echo "$OUT" | grep -q '"verb":"execute"' || { echo "FAIL t1: verb"; exit 1; }
echo "$OUT" | grep -q '"oneStep":true' || { echo "FAIL t1: flag"; exit 1; }
echo "$OUT" | grep -q '"auth-v1/login"' || { echo "FAIL t1: arg"; exit 1; }

# Test 2: create with quoted description + --pack
OUT=$(run '["create","implement v1 auth","--pack","product-engineering"]')
echo "$OUT" | grep -q '"verb":"create"' || { echo "FAIL t2: verb"; exit 1; }
echo "$OUT" | grep -q '"pack":"product-engineering"' || { echo "FAIL t2: pack"; exit 1; }

# Test 3: empty → help
OUT=$(run '[]')
echo "$OUT" | grep -q '"verb":"help"' || { echo "FAIL t3: empty→help"; exit 1; }

# Test 4: --help alias
OUT=$(run '["--help"]')
echo "$OUT" | grep -q '"verb":"help"' || { echo "FAIL t4: --help"; exit 1; }

echo "PASS: arg-parser handles 4 cases"
