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

# CLI-level: bf-harness list prints one labeled key:value block per bf-wo
# (Id/State/Updated/Desc), blocks separated by `---` on its own line.
# Empty desc renders as `-`. No trailing whitespace. No pipe separator.
BASE=$(make_temp_home)
cp -R "$FIXTURES/clean-wo" "$BASE/clean-wo"
# Add a second wo so we can assert the `---` separator appears between blocks.
mkdir -p "$BASE/second-wo"
cp "$FIXTURES/clean-wo/bf.md" "$BASE/second-wo/bf.md"
# Patch Id field inside bf.md so it matches the dir name.
node -e "
  const fs=require('fs');
  const p='$BASE/second-wo/bf.md';
  fs.writeFileSync(p, fs.readFileSync(p,'utf8').replace(/Id: clean-wo/, 'Id: second-wo'));
"
export BF_HOME="$BASE"
run_bfh list
assert_eq "$RC" "0" "list exit 0"
ID_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^Id: clean-wo$')
assert_eq "$ID_ROWS" "1" "list has one 'Id: clean-wo' line"
STATE_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^State: Draft$')
assert_eq "$STATE_ROWS" "2" "list has two 'State: Draft' lines (clean-wo + second-wo)"
SEP_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^---$')
assert_eq "$SEP_ROWS" "1" "list has '---' separator between the 2 records"
# Labeled shape: no pipe separator anywhere in the output.
if printf "%s\n" "$STDOUT" | grep -qE ' \| '; then
  fail "list output unexpectedly contains pipe separator"
fi
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
