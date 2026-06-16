#!/usr/bin/env bash
# Regression: pack registry must tolerate a bad directory entry. A dangling
# symlink inside a packs dir (statSync follows it and throws ENOENT) must be
# skipped-with-warning, and buildPackRegistry must still return the valid packs
# without throwing. (Finding B, EV-3.)
set -u
source "$(dirname "$0")/test-helpers.sh"

TMP=$(make_temp_home)
mkdir -p "$TMP/packs"
# A valid pack alongside the bad entry.
cp -R "$FIXTURES/packs-engineering" "$TMP/packs/engineering"

# A DETERMINISTIC dangling symlink: points at a path that does not exist, so
# statSync (which follows symlinks) throws ENOENT — the exact crash from
# Finding B. Not a racy entry.
ln -s "$TMP/packs/does-not-exist-target" "$TMP/packs/dangling"
# Sanity: the link exists but its target does not (dangling).
[ -L "$TMP/packs/dangling" ] || fail "setup: dangling symlink not created"
[ -e "$TMP/packs/dangling" ] && fail "setup: symlink target should not exist"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(m => {
    const r = m.buildPackRegistry({ packsDir: '$TMP/packs' });
    process.stdout.write(JSON.stringify({
      ids: [...r.packs.keys()].sort(),
      warnings: r.warnings,
    }));
  }).catch(e => {
    process.stdout.write(JSON.stringify({ threw: e.message }));
  });
")

# No throw: the valid pack is still returned.
assert_not_match "$STDOUT" "threw" "buildPackRegistry must not throw on a dangling symlink"
assert_json_field "$STDOUT" .ids '["engineering"]'
# The bad entry is skipped-with-warning, naming it.
assert_match "$STDOUT" "dangling" "skip warning names the bad entry"

rm -rf "$TMP"

# A dangling symlink in a (highest-precedence) extension packs dir is equally
# tolerated and does not remove the valid lower pack.
TMP2=$(make_temp_home)
EXT=$(make_temp_home)
mkdir -p "$TMP2/packs"
cp -R "$FIXTURES/packs-engineering" "$TMP2/packs/engineering"
mkdir -p "$EXT/ext-packs"
ln -s "$EXT/ext-packs/missing-target" "$EXT/ext-packs/dangling-ext"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(m => {
    const r = m.buildPackRegistry({
      packsDir: '$TMP2/packs',
      extensionPacksDirs: ['$EXT/ext-packs'],
    });
    process.stdout.write(JSON.stringify({
      hasEngineering: r.packs.has('engineering'),
      warnings: r.warnings,
    }));
  }).catch(e => {
    process.stdout.write(JSON.stringify({ threw: e.message }));
  });
")
assert_not_match "$STDOUT" "threw" "extension-dir dangling symlink must not throw"
assert_json_field "$STDOUT" .hasEngineering true
assert_match "$STDOUT" "dangling-ext" "extension-dir bad entry skipped with warning"

rm -rf "$TMP2" "$EXT"

pass
