#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
HOME_DIR="$BASE/projects/my-proj"
mkdir -p "$HOME_DIR"
cp -R "$FIXTURES/clean-wo" "$HOME_DIR/clean-wo"

# 加一个坏 wo
mkdir -p "$HOME_DIR/broken-wo"
echo "not yaml" > "$HOME_DIR/broken-wo/bf.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-list.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdList({ baseHome: '$BASE', projectSlug: 'my-proj' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .woList.0.id "clean-wo"
assert_json_field "$STDOUT" .woList.0.state "Draft"
assert_match "$STDOUT" "broken-wo" "broken entry in warnings"

# 不存在的 project
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-list.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdList({ baseHome: '$BASE', projectSlug: 'nope' })));
  });
")
assert_json_field "$STDOUT" .woList '[]'

rm -rf "$BASE"
pass
