#!/usr/bin/env bash
# 入口：跑所有 test/test-*.sh
set -u
cd "$(dirname "$0")"

shopt -s nullglob
TESTS=( test-*.sh )
shopt -u nullglob

PASS=0
FAIL=0
FAILED_NAMES=()

for t in "${TESTS[@]}"; do
  [ "$t" = "test-helpers.sh" ] && continue
  out=$(bash "$t" 2>&1)
  rc=$?
  if [ $rc -eq 0 ] && echo "$out" | grep -q "^PASS$"; then
    printf '  ok   %s\n' "$t"
    PASS=$((PASS+1))
  else
    printf '  FAIL %s\n' "$t"
    echo "$out" | sed 's/^/      /'
    FAIL=$((FAIL+1))
    FAILED_NAMES+=("$t")
  fi
done

echo
echo "Total: $((PASS+FAIL))  Pass: $PASS  Fail: $FAIL"
if [ $FAIL -gt 0 ]; then
  echo "Failed:"
  printf '  - %s\n' "${FAILED_NAMES[@]}"
  exit 1
fi
