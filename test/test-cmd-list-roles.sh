#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

# 搭一个临时"repo 根"：roles/ + packs/engineering/
ROOT=$(make_temp_home)
mkdir -p "$ROOT/roles" "$ROOT/packs"
cp -R "$FIXTURES/roles-core/." "$ROOT/roles/"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"

# Core only
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-roles.mjs').then(async (m) => {
    const r = await m.cmdListRoles({ cwd: '$ROOT' });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .roles.0.id "engineer"
assert_json_field "$STDOUT" .roles.0.source "core"
assert_json_field "$STDOUT" .roles.1.id "qa-engineer"
assert_json_field "$STDOUT" .roles.2.id "tester"

# With pack（pack 覆盖 core engineer）
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-roles.mjs').then(async (m) => {
    const r = await m.cmdListRoles({ cwd: '$ROOT', pack: 'engineering' });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .roles.0.id "engineer"
assert_json_field "$STDOUT" .roles.0.source "pack"
assert_json_field "$STDOUT" .roles.0.capabilities '["software-implementation","design"]'

# pack 不存在
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-roles.mjs').then(async (m) => {
    const r = await m.cmdListRoles({ cwd: '$ROOT', pack: 'nope' });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "pack not found: nope" "missing pack error"

rm -rf "$ROOT"

# CLI-level: `bf list-roles` prints one row per role in the documented format
# `<id> | [<caps>] | <source> | <file>`. No trailing whitespace.
ROOT=$(make_temp_home)
mkdir -p "$ROOT/roles" "$ROOT/packs"
cp -R "$FIXTURES/roles-core/." "$ROOT/roles/"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
EMPTY_HOME=$(make_temp_home)
export BF_INSTALL_DIR="$ROOT"
export BF_HOME="$EMPTY_HOME"
run_bf list-roles
assert_eq "$RC" "0" "list-roles exit 0"
ROW_COUNT=$(printf "%s\n" "$STDOUT" | grep -cE '^engineer \| \[.*\] \| core \| .+')
assert_eq "$ROW_COUNT" "1" "list-roles has 1 engineer row in shape"
# Format spec: every non-comment row has exactly 3 ` | ` separators (4 columns).
printf "%s\n" "$STDOUT" | grep -v '^#' | grep -v '^(no ' | while read -r line; do
  [ -z "$line" ] && continue
  sep_count=$(printf "%s" "$line" | grep -o ' | ' | wc -l)
  if [ "$sep_count" != "3" ]; then
    echo "row has $sep_count separators (expected 3): $line" >&2
    exit 1
  fi
done || fail "list-roles row format"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in list-roles stdout"
unset BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$EMPTY_HOME"

pass
