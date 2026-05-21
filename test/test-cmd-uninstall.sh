#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

# Build a fake srcDir, install + exercise uninstall variants.
SRC=$(make_temp_home)
mkdir -p "$SRC/roles" "$SRC/packs/sample" "$SRC/templates" "$SRC/references" "$SRC/bin"
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

# --- Test 1: nothing to remove ---
HOME_DIR=$(make_temp_home)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .mode "noop"

# --- Test 2: install + uninstall removes the whole skill dir when no extensions ---
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} }));
" >/dev/null
TARGET="$HOME_DIR/.claude/skills/bf"
[ -f "$TARGET/SKILL.md" ] || fail "precondition: install did not create SKILL.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "removed"
[ ! -e "$TARGET" ] || fail "skill dir should be gone after clean uninstall"

# --- Test 3: uninstall preserves the extensions/ folder (whatever is inside) ---
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} }));
" >/dev/null
mkdir -p "$TARGET/extensions/roles" "$TARGET/extensions/packs"
echo "# my custom role" > "$TARGET/extensions/roles/my-custom.md"
echo "# my custom pack root" > "$TARGET/extensions/packs/my-pack.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "removed"
[ -f "$TARGET/extensions/roles/my-custom.md" ] || fail "custom extension role should be preserved"
[ -f "$TARGET/extensions/packs/my-pack.md" ] || fail "custom extension pack should be preserved"
[ ! -f "$TARGET/roles/architect.md" ] || fail "managed role should be removed"
[ ! -d "$TARGET/packs/sample" ] || fail "managed pack should be removed"
[ ! -f "$TARGET/SKILL.md" ] || fail "managed SKILL.md should be removed"
[ -d "$TARGET" ] || fail "skill dir should remain when extensions/ is non-empty"

# --- Test 4: uninstall removes the skill dir when extensions/ exists but is empty ---
rm -rf "$TARGET"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} }));
" >/dev/null
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "removed"
[ ! -e "$TARGET" ] || fail "skill dir should be gone when extensions/ was never created"

# --- Test 5: symlink uninstall removes only the link ---
HOME_DIR2=$(make_temp_home)
mkdir -p "$HOME_DIR2/.claude/skills"
ln -s "$SRC" "$HOME_DIR2/.claude/skills/bf"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ home: '$HOME_DIR2', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "symlink-removed"
[ ! -e "$HOME_DIR2/.claude/skills/bf" ] || fail "symlink should be gone"
[ -d "$SRC" ] || fail "symlink target dir should be untouched"
[ -f "$SRC/SKILL.md" ] || fail "symlink source files should be untouched"

rm -rf "$SRC" "$HOME_DIR" "$HOME_DIR2"
pass
