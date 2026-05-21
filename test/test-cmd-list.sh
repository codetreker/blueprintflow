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
pass
