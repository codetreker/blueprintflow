#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

# Build a fake srcDir + install it, then test uninstall behaviors.
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
    const r = await m.cmdUninstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .mode "noop"

# --- Test 2: install + uninstall removes managed files ---
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} }));
" >/dev/null
TARGET="$HOME_DIR/.claude/skills/bf"
[ -f "$TARGET/SKILL.md" ] || fail "precondition: install did not create SKILL.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "removed"
[ ! -e "$TARGET" ] || fail "skill dir should be gone after clean uninstall"

# --- Test 3: uninstall preserves custom roles ---
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then((m) =>
    m.cmdInstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} }));
" >/dev/null
echo "# my custom role" > "$TARGET/roles/my-custom.md"
echo "# my custom pack" > "$TARGET/packs/my-pack.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ srcDir: '$SRC', home: '$HOME_DIR', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "removed"
[ -f "$TARGET/roles/my-custom.md" ] || fail "custom role should be preserved"
[ -f "$TARGET/packs/my-pack.md" ] || fail "custom pack should be preserved"
[ ! -f "$TARGET/roles/architect.md" ] || fail "managed role should be removed"
[ ! -f "$TARGET/roles/engineer.md" ] || fail "managed role should be removed"
[ ! -d "$TARGET/packs/sample" ] || fail "managed pack should be removed"
[ ! -f "$TARGET/SKILL.md" ] || fail "managed SKILL.md should be removed"

# --- Test 4: symlink uninstall removes only the link ---
HOME_DIR2=$(make_temp_home)
mkdir -p "$HOME_DIR2/.claude/skills"
ln -s "$SRC" "$HOME_DIR2/.claude/skills/bf"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
    const r = await m.cmdUninstall({ srcDir: '$SRC', home: '$HOME_DIR2', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .mode "symlink-removed"
[ ! -e "$HOME_DIR2/.claude/skills/bf" ] || fail "symlink should be gone"
[ -d "$SRC" ] || fail "symlink target dir should be untouched"
[ -f "$SRC/SKILL.md" ] || fail "symlink source files should be untouched"

rm -rf "$SRC" "$HOME_DIR" "$HOME_DIR2"
pass
