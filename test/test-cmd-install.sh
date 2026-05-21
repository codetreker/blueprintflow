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
# bin/ and package.json are intentionally NOT copied; they live in the npm package dir.
[ ! -e "$TARGET/bin" ] || fail "bin/ should not be copied (lives in npm package dir)"
[ ! -e "$TARGET/package.json" ] || fail "package.json should not be copied (lives in npm package dir)"

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

# --- Test 4: install never touches extensions/ ---
HOME_DIR3=$(make_temp_home)
mkdir -p "$HOME_DIR3/.claude/skills/bf/extensions/roles"
echo "# user-custom role" > "$HOME_DIR3/.claude/skills/bf/extensions/roles/my-role.md"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR3', log: () => {} }));
" >/dev/null
[ -f "$HOME_DIR3/.claude/skills/bf/extensions/roles/my-role.md" ] || fail "install must not touch extensions/"
[ -f "$HOME_DIR3/.claude/skills/bf/SKILL.md" ] || fail "install must still write SKILL.md"

# --- Test 5: install removes orphans from previous version ---
HOME_DIR4=$(make_temp_home)
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR4', log: () => {} }));
" >/dev/null
# Simulate an orphan: a role file present in the installed copy but not in the new srcDir
echo "# old role removed in this version" > "$HOME_DIR4/.claude/skills/bf/roles/removed.md"
[ -f "$HOME_DIR4/.claude/skills/bf/roles/removed.md" ] || fail "precondition: orphan should exist"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR4', log: () => {} }));
" >/dev/null
[ ! -f "$HOME_DIR4/.claude/skills/bf/roles/removed.md" ] || fail "orphan role should be removed by nuke+replace"
[ -f "$HOME_DIR4/.claude/skills/bf/roles/architect.md" ] || fail "current role should still be present"

rm -rf "$SRC" "$HOME_DIR" "$HOME_DIR2" "$HOME_DIR3" "$HOME_DIR4"
pass
