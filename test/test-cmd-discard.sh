#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
mkdir -p "$BASE/projects/p/wo-x"
echo "hi" > "$BASE/projects/p/wo-x/bf.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-discard.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdDiscard({ baseHome: '$BASE', projectSlug: 'p', woId: 'wo-x' })));
  });
")
assert_json_field "$STDOUT" .ok true
[ ! -d "$BASE/projects/p/wo-x" ] || fail "wo-x not removed"

# 不存在
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-discard.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdDiscard({ baseHome: '$BASE', projectSlug: 'p', woId: 'wo-x' })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "not found" "missing wo error"

# 路径逃逸
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-discard.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdDiscard({ baseHome: '$BASE', projectSlug: 'p', woId: '..' })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "invalid woId" "escape rejected"

rm -rf "$BASE"
pass
