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

rm -rf "$TMP"
pass
