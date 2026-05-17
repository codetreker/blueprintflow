#!/bin/bash
# Run all OPC test files
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
DEFERRED_LIST="$DIR/deferred-tests.txt"
declare -A DEFERRED
if [ -f "$DEFERRED_LIST" ]; then
  while IFS= read -r line; do
    name="${line%%#*}"
    name="${name%"${name##*[![:space:]]}"}"
    name="${name#"${name%%[![:space:]]*}"}"
    [ -z "$name" ] && continue
    DEFERRED["$name"]=1
  done < "$DEFERRED_LIST"
fi
TOTAL_PASS=0
TOTAL_FAIL=0

for f in "$DIR"/test-*.sh "$DIR"/harness-hardening/test-*.sh; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "test-helpers.sh" ] && continue
  base="$(basename "$f")"
  if [ -n "${DEFERRED[$base]:-}" ]; then
    echo ""
    echo "─── skipping (deferred): $base"
    continue
  fi
  echo ""
  echo "═══════════════════════════════════════════"
  echo "  Running $base"
  echo "═══════════════════════════════════════════"
  if bash "$f"; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
  else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    echo "  ⚠️  $base had failures"
  fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "  Suite: $TOTAL_PASS files passed, $TOTAL_FAIL files failed"
echo "═══════════════════════════════════════════"

[ "$TOTAL_FAIL" -eq 0 ] || exit 1
