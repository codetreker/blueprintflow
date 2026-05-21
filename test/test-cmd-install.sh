#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

# Build a minimal fake srcDir so we can install/uninstall without touching the real repo.
SRC=$(make_temp_home)
mkdir -p "$SRC/roles" "$SRC/packs/sample" "$SRC/templates" "$SRC/references" "$SRC/bin/lib"
echo "# SKILL" > "$SRC/SKILL.md"
echo "# arch role" > "$SRC/roles/architect.md"
echo "# eng role" > "$SRC/roles/engineer.md"
echo "# sample pack" > "$SRC/packs/sample/pack.md"
echo "# bf template" > "$SRC/templates/bf.md"
echo "# phase 1" > "$SRC/references/phase-1.md"
echo "#!/usr/bin/env node" > "$SRC/bin/bf.mjs"
cat > "$SRC/package.json" <<'JSON'
{"name":"@codetreker/bf","version":"9.9.9"}
JSON

HOME_DIR=$(make_temp_home)
TARGET="$HOME_DIR/.claude/skills/bf"

# --- Test 1: fresh install copies all managed entries ---
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then(async (m) => {
    const r = await m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .mode "copied"
assert_json_field "$STDOUT" .version "9.9.9"
[ -f "$TARGET/SKILL.md" ] || fail "SKILL.md not copied"
[ -f "$TARGET/roles/architect.md" ] || fail "roles/architect.md not copied"
[ -f "$TARGET/roles/engineer.md" ] || fail "roles/engineer.md not copied"
[ -f "$TARGET/packs/sample/pack.md" ] || fail "packs/sample/pack.md not copied"
[ -f "$TARGET/templates/bf.md" ] || fail "templates/bf.md not copied"
[ -f "$TARGET/references/phase-1.md" ] || fail "references/phase-1.md not copied"
[ -f "$TARGET/bin/bf.mjs" ] || fail "bin/bf.mjs not copied"
[ -f "$TARGET/package.json" ] || fail "package.json not copied"

# --- Test 2: re-install overwrites with fresh content ---
echo "# updated SKILL" > "$SRC/SKILL.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then(async (m) => {
    const r = await m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "copied"
grep -q "updated SKILL" "$TARGET/SKILL.md" || fail "re-install did not refresh SKILL.md"

# --- Test 3: symlink-mode install is a no-op ---
HOME_DIR2=$(make_temp_home)
mkdir -p "$HOME_DIR2/.claude/skills"
ln -s "$SRC" "$HOME_DIR2/.claude/skills/bf"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then(async (m) => {
    const r = await m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR2', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "linked"
[ -L "$HOME_DIR2/.claude/skills/bf" ] || fail "symlink unexpectedly replaced"

rm -rf "$SRC" "$HOME_DIR" "$HOME_DIR2"
pass
