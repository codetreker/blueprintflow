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

# extension 覆盖 core；多个 extension dir 后者覆盖前者（project > global）
EXT_DIR=$(make_temp_home)
mkdir -p "$EXT_DIR/global" "$EXT_DIR/project"
# global extension overrides core engineer
cat > "$EXT_DIR/global/engineer.md" <<'EOF'
---
Id: engineer
Desc: global-extension override
Capabilities:
  - software-implementation
  - global-cap
---
body
EOF
# project extension overrides global+core engineer; also adds a brand-new role
cat > "$EXT_DIR/project/engineer.md" <<'EOF'
---
Id: engineer
Desc: project-extension override
Capabilities:
  - software-implementation
  - project-cap
---
body
EOF
cat > "$EXT_DIR/project/custom.md" <<'EOF'
---
Id: custom
Desc: project-only role
Capabilities:
  - novel-cap
---
body
EOF

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then(m => {
    const r = m.buildRoleRegistry({
      coreRolesDir: '$FIXTURES/roles-core',
      extensionRolesDirs: ['$EXT_DIR/global', '$EXT_DIR/project'],
    });
    const eng = r.roles.get('engineer');
    const custom = r.roles.get('custom');
    process.stdout.write(JSON.stringify({
      ids: [...r.roles.keys()].sort(),
      engineerSource: eng?.source,
      engineerCaps: eng?.capabilities,
      customSource: custom?.source,
    }));
  });
")
assert_json_field "$STDOUT" .engineerSource "extension"
assert_json_field "$STDOUT" .engineerCaps '["software-implementation","project-cap"]'
assert_json_field "$STDOUT" .customSource "extension"
assert_json_field "$STDOUT" .ids '["custom","engineer","qa-engineer","tester"]'

rm -rf "$EXT_DIR"
pass
