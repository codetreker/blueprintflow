#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

# 用 fixture: packs-engineering 在 fixtures 根，pack-registry 需要一个含子目录的 packs/ root
TMP=$(make_temp_home)
mkdir -p "$TMP/packs"
cp -R "$FIXTURES/packs-engineering" "$TMP/packs/engineering"

# 加一个 id mismatch 的 pack
mkdir -p "$TMP/packs/bogus"
cat > "$TMP/packs/bogus/pack.md" <<'EOF'
---
Id: wrong-id
Desc: id 跟目录不一致
---

## When to Use

testing
EOF

# 加一个缺 pack.md 的
mkdir -p "$TMP/packs/empty-pack"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(m => {
    const r = m.buildPackRegistry({ packsDir: '$TMP/packs' });
    process.stdout.write(JSON.stringify({
      ids: [...r.packs.keys()].sort(),
      warnings: r.warnings,
      engRolesDir: r.packs.get('engineering')?.rolesDir,
    }));
  });
")
assert_json_field "$STDOUT" .ids '["engineering"]'
assert_match "$STDOUT" "bogus" "id mismatch warning"
assert_match "$STDOUT" "empty-pack" "missing pack.md warning"
assert_match "$STDOUT" "/packs/engineering/roles" "rolesDir resolved"

# extension packs add new packs and merge same-id packs as layers
EXT_DIR=$(make_temp_home)
PROJECT_EXT_DIR=$(make_temp_home)
mkdir -p "$EXT_DIR/ext-packs/extra-pack" "$EXT_DIR/ext-packs/engineering/roles" "$EXT_DIR/ext-packs/engineering/pipelines"
mkdir -p "$PROJECT_EXT_DIR/ext-packs/engineering/roles" "$PROJECT_EXT_DIR/ext-packs/engineering/pipelines"
write_pack_md "$EXT_DIR/ext-packs/extra-pack/pack.md" "extra-pack" "extension-only pack"
write_pack_md "$EXT_DIR/ext-packs/engineering/pack.md" "engineering" "global engineering overlay"
write_pack_md "$PROJECT_EXT_DIR/ext-packs/engineering/pack.md" "engineering" "project engineering overlay"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(m => {
    const r = m.buildPackRegistry({
      packsDir: '$TMP/packs',
      extensionPacksDirs: ['$EXT_DIR/ext-packs', '$PROJECT_EXT_DIR/ext-packs'],
    });
    const eng = r.packs.get('engineering');
    const extra = r.packs.get('extra-pack');
    process.stdout.write(JSON.stringify({
      ids: [...r.packs.keys()].sort(),
      engineeringDesc: eng?.desc,
      engineeringPaths: eng?.paths,
      engineeringRolesDirs: eng?.rolesDirs,
      engineeringPipelinesDirs: eng?.pipelinesDirs,
      extraPaths: extra?.paths,
    }));
  });
")
assert_json_field "$STDOUT" .ids '["engineering","extra-pack"]'
assert_json_field "$STDOUT" .engineeringDesc "project engineering overlay"
assert_match "$STDOUT" "$TMP/packs/engineering/pack.md" "core pack path kept"
assert_match "$STDOUT" "$EXT_DIR/ext-packs/engineering/pack.md" "global extension pack path kept"
assert_match "$STDOUT" "$PROJECT_EXT_DIR/ext-packs/engineering/pack.md" "project extension pack path kept"
assert_match "$STDOUT" "$EXT_DIR/ext-packs/engineering/roles" "global roles dir kept"
assert_match "$STDOUT" "$PROJECT_EXT_DIR/ext-packs/engineering/pipelines" "project pipelines dir kept"
assert_match "$STDOUT" "$EXT_DIR/ext-packs/extra-pack/pack.md" "extension-only pack path"

# invalid extension layer does not remove lower valid pack
mkdir -p "$PROJECT_EXT_DIR/ext-packs/bad-pack"
write_pack_md "$PROJECT_EXT_DIR/ext-packs/bad-pack/pack.md" "wrong-id" "bad project layer"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(m => {
    const r = m.buildPackRegistry({
      packsDir: '$TMP/packs',
      extensionPacksDirs: ['$PROJECT_EXT_DIR/ext-packs'],
    });
    process.stdout.write(JSON.stringify({
      hasEngineering: r.packs.has('engineering'),
      warnings: r.warnings,
    }));
  });
")
assert_json_field "$STDOUT" .hasEngineering true
assert_match "$STDOUT" "bad-pack" "invalid extension layer warning"

rm -rf "$TMP" "$EXT_DIR" "$PROJECT_EXT_DIR"
pass
