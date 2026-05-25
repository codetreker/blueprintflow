#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
cp -R "$FIXTURES/clean-wo" "$BASE/clean-wo"

# add a broken wo
mkdir -p "$BASE/broken-wo"
echo "not yaml" > "$BASE/broken-wo/bf.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-list.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdList({ baseHome: '$BASE' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .woList.0.id "clean-wo"
assert_json_field "$STDOUT" .woList.0.state "Draft"
assert_match "$STDOUT" "broken-wo" "broken entry in warnings"

# nonexistent baseHome
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-list.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdList({ baseHome: '$BASE/does-not-exist' })));
  });
")
assert_json_field "$STDOUT" .woList '[]'

rm -rf "$BASE"

# CLI-level: bf-harness list prints one row per wo in `<id> | <state> | ...`
# format (pipe separator — see format-list.mjs). Empty desc renders as `-`
# (no trailing whitespace).
BASE=$(make_temp_home)
cp -R "$FIXTURES/clean-wo" "$BASE/clean-wo"
export BF_HOME="$BASE"
run_bfh list
assert_eq "$RC" "0" "list exit 0"
ROW_COUNT=$(printf "%s\n" "$STDOUT" | grep -cE '^clean-wo \| Draft \| ')
assert_eq "$ROW_COUNT" "1" "list has 1 row for clean-wo"
# Every non-comment row has exactly 3 ` | ` separators (4 columns).
printf "%s\n" "$STDOUT" | grep -v '^#' | grep -v '^(no ' | while read -r line; do
  [ -z "$line" ] && continue
  sep_count=$(printf "%s" "$line" | grep -o ' | ' | wc -l)
  if [ "$sep_count" != "3" ]; then
    echo "row has $sep_count separators (expected 3): $line" >&2
    exit 1
  fi
done || fail "list row format"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in list stdout"
unset BF_HOME
rm -rf "$BASE"

# CLI-level empty: prints the placeholder, not a blank line.
EMPTY=$(make_temp_home)
export BF_HOME="$EMPTY"
run_bfh list
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
assert_eq "$FIRST_LINE" "(no bf-wos)" "list empty placeholder"
unset BF_HOME
rm -rf "$EMPTY"

pass
