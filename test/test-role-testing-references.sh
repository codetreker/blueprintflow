#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

assert_file_contains() {
  local file="$1" needle="$2" msg="${3:-}"
  if ! grep -F "$needle" "$file" >/dev/null; then
    fail "$msg: $file does not contain '$needle'"
  fi
}

assert_file_not_contains() {
  local file="$1" needle="$2" msg="${3:-}"
  if grep -F "$needle" "$file" >/dev/null; then
    fail "$msg: $file unexpectedly contains '$needle'"
  fi
}

TESTER="$REPO_ROOT/roles/tester.md"
UI_REF="$REPO_ROOT/roles/references/ui-testing.md"
API_REF="$REPO_ROOT/roles/references/api-testing.md"

[ -f "$UI_REF" ] || fail "missing UI testing reference: $UI_REF"
[ -f "$API_REF" ] || fail "missing API testing reference: $API_REF"

assert_file_contains "$TESTER" "roles/references/ui-testing.md" "tester should name UI testing reference"
assert_file_contains "$TESTER" "roles/references/api-testing.md" "tester should name API testing reference"
assert_file_contains "$TESTER" "reviewed scope includes UI behavior" "tester should route UI reference by reviewed scope"
assert_file_contains "$TESTER" "reviewed scope includes API behavior" "tester should route API reference by reviewed scope"
assert_file_contains "$TESTER" "Load both" "tester should allow mixed UI/API scope"
assert_file_contains "$TESTER" "Load neither" "tester should avoid unrelated references"

assert_file_not_contains "$UI_REF" "Capabilities:" "UI testing reference must not be a role"
assert_file_not_contains "$API_REF" "Capabilities:" "API testing reference must not be a role"

for topic in \
  "UI journeys" \
  "states" \
  "input behavior" \
  "accessibility" \
  "responsive behavior" \
  "layout reasonableness" \
  "UX validation" \
  "state consistency" \
  "evidence quality"
do
  assert_file_contains "$UI_REF" "$topic" "UI reference should cover $topic"
done

for topic in \
  "API contract shape" \
  "auth and authorization" \
  "input validation" \
  "behavior and state" \
  "error semantics" \
  "integration boundaries" \
  "evidence quality"
do
  assert_file_contains "$API_REF" "$topic" "API reference should cover $topic"
done

pass
