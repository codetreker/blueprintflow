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

# CLI-level: `bf list-roles` prints one labeled key:value block per role
# (Id/Desc/Capabilities/Source/File). Blocks separated by `---` on its own
# line. No pipe separator. No trailing whitespace.
ROOT=$(make_temp_home)
mkdir -p "$ROOT/roles" "$ROOT/packs"
cp -R "$FIXTURES/roles-core/." "$ROOT/roles/"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
EMPTY_HOME=$(make_temp_home)
export BF_INSTALL_DIR="$ROOT"
export BF_HOME="$EMPTY_HOME"
run_bf list-roles
assert_eq "$RC" "0" "list-roles exit 0"
ID_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^Id: engineer$')
assert_eq "$ID_ROWS" "1" "list-roles has one 'Id: engineer' line"
SRC_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^Source: core$')
# roles-core fixture has 3 roles → 3 'Source: core' lines.
assert_eq "$SRC_ROWS" "3" "list-roles has 3 'Source: core' lines"
# At least one capability line on its own.
CAP_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^Capabilities: \[')
assert_eq "$CAP_ROWS" "3" "list-roles has 3 'Capabilities: [...]' lines"
# Block separator `---` appears between the 3 records → 2 separators.
SEP_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^---$')
assert_eq "$SEP_ROWS" "2" "list-roles has 2 '---' separators (between 3 records)"
# Labeled shape: no pipe separator anywhere in the output.
if printf "%s\n" "$STDOUT" | grep -qE ' \| '; then
  fail "list-roles output unexpectedly contains pipe separator"
fi
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in list-roles stdout"
unset BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$EMPTY_HOME"

pass
