#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

# pack 覆盖 core 同名 role
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then(m => {
    const r = m.buildRoleRegistry({
      coreRolesDir: '$FIXTURES/roles-core',
      packRolesDir: '$FIXTURES/packs-engineering/roles',
    });
    const out = {
      ids: [...r.roles.keys()].sort(),
      engineerCaps: r.roles.get('engineer').capabilities,
      engineerSource: r.roles.get('engineer').source,
      qaRoles: r.byCapability.get('quality-assurance').map(x=>x.id),
      designRoles: r.byCapability.get('design').map(x=>x.id),
    };
    process.stdout.write(JSON.stringify(out));
  });
")
assert_json_field "$STDOUT" .ids '["engineer","qa-engineer","tester"]'
assert_json_field "$STDOUT" .engineerSource "pack"
assert_json_field "$STDOUT" .engineerCaps '["software-implementation","design"]'
assert_json_field "$STDOUT" .qaRoles '["qa-engineer","tester"]'
assert_json_field "$STDOUT" .designRoles '["engineer"]'

# 没有 packRolesDir 也 ok
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then(m => {
    const r = m.buildRoleRegistry({ coreRolesDir: '$FIXTURES/roles-core' });
    process.stdout.write(JSON.stringify({ ids: [...r.roles.keys()].sort() }));
  });
")
assert_json_field "$STDOUT" .ids '["engineer","qa-engineer","tester"]'

# 不存在的目录 → 空
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then(m => {
    const r = m.buildRoleRegistry({ coreRolesDir: '/nonexistent/path' });
    process.stdout.write(JSON.stringify({ count: r.roles.size }));
  });
")
assert_json_field "$STDOUT" .count "0"

pass
