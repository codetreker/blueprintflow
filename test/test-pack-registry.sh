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

# extension packs add new packs and override core packs of the same id
EXT_DIR=$(make_temp_home)
mkdir -p "$EXT_DIR/ext-packs/extra-pack" "$EXT_DIR/ext-packs/engineering"
cat > "$EXT_DIR/ext-packs/extra-pack/pack.md" <<'EOF'
---
Id: extra-pack
Desc: extension-only pack
---

## When to Use

extension testing
EOF
cat > "$EXT_DIR/ext-packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: extension override of core engineering pack
---

## When to Use

override
EOF

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(m => {
    const r = m.buildPackRegistry({
      packsDir: '$TMP/packs',
      extensionPacksDirs: ['$EXT_DIR/ext-packs'],
    });
    const eng = r.packs.get('engineering');
    const extra = r.packs.get('extra-pack');
    process.stdout.write(JSON.stringify({
      ids: [...r.packs.keys()].sort(),
      engineeringDesc: eng?.desc,
      engineeringSource: eng?.source,
      extraSource: extra?.source,
    }));
  });
")
assert_json_field "$STDOUT" .ids '["engineering","extra-pack"]'
assert_json_field "$STDOUT" .engineeringSource "extension"
assert_json_field "$STDOUT" .engineeringDesc "extension override of core engineering pack"
assert_json_field "$STDOUT" .extraSource "extension"

rm -rf "$TMP" "$EXT_DIR"
pass
