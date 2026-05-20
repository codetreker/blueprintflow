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
  import('$REPO_ROOT/bin/lib/cmd-list-roles.mjs').then(async (m) => {
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
  import('$REPO_ROOT/bin/lib/cmd-list-roles.mjs').then(async (m) => {
    const r = await m.cmdListRoles({ cwd: '$ROOT', pack: 'engineering' });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .roles.0.id "engineer"
assert_json_field "$STDOUT" .roles.0.source "pack"
assert_json_field "$STDOUT" .roles.0.capabilities '["software-implementation","design"]'

# pack 不存在
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-list-roles.mjs').then(async (m) => {
    const r = await m.cmdListRoles({ cwd: '$ROOT', pack: 'nope' });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "pack not found: nope" "missing pack error"

rm -rf "$ROOT"
pass
