#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
mkdir -p "$BASE/wo-x"
echo "hi" > "$BASE/wo-x/bf.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-discard.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdDiscard({ baseHome: '$BASE', woId: 'wo-x' })));
  });
")
assert_json_field "$STDOUT" .ok true
[ ! -d "$BASE/wo-x" ] || fail "wo-x not removed"

# 不存在
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-discard.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdDiscard({ baseHome: '$BASE', woId: 'wo-x' })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "not found" "missing wo error"

# 路径逃逸
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-discard.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdDiscard({ baseHome: '$BASE', woId: '..' })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "invalid woId" "escape rejected"

rm -rf "$BASE"

# CLI-level: bf-harness discard prints `Removed <abs-path>` and exits 0.
# No trailing whitespace.
BASE=$(make_temp_home)
mkdir -p "$BASE/wo-y"
echo "hi" > "$BASE/wo-y/bf.md"
export BF_HOME="$BASE"
run_bfh discard "wo-y"
assert_eq "$RC" "0" "discard exit 0"
case "$STDOUT" in
  "Removed "/*) ;;
  *) fail "discard stdout does not start with 'Removed <abs-path>': $STDOUT" ;;
esac
[ ! -d "$BASE/wo-y" ] || fail "wo-y not removed"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in discard stdout"
unset BF_HOME
rm -rf "$BASE"

pass
