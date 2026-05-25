#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

ROOT=$(make_temp_home)
mkdir -p "$ROOT/packs"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-packs.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPacks({ cwd: '$ROOT' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .packs.0.id "engineering"
assert_json_field "$STDOUT" .packs.0.desc "软件工程类工作"

# 没 packs/ 目录
EMPTY=$(make_temp_home)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-packs.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPacks({ cwd: '$EMPTY' })));
  });
")
assert_json_field "$STDOUT" .packs '[]'

rm -rf "$ROOT" "$EMPTY"

# CLI-level: `bf list-packs` prints one row per pack in the documented
# format `<id> | <desc> | <source>`. No trailing whitespace.
ROOT=$(make_temp_home)
mkdir -p "$ROOT/packs"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
export BF_INSTALL_DIR="$ROOT"
# Force empty extension dirs by pointing BF_HOME at a fresh dir.
EMPTY_HOME=$(make_temp_home)
export BF_HOME="$EMPTY_HOME"
run_bf list-packs
assert_eq "$RC" "0" "list-packs exit 0"
ROW_COUNT=$(printf "%s\n" "$STDOUT" | grep -cE '^engineering \| .* \| core$')
assert_eq "$ROW_COUNT" "1" "list-packs has 1 engineering row in '<id> | <desc> | <source>' shape"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in list-packs stdout"
unset BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$EMPTY_HOME"

# Empty (no packs dir): prints the placeholder.
EMPTY=$(make_temp_home)
export BF_INSTALL_DIR="$EMPTY"
export BF_HOME="$EMPTY"
run_bf list-packs
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
assert_eq "$FIRST_LINE" "(no packs installed)" "list-packs empty placeholder"
unset BF_INSTALL_DIR BF_HOME
rm -rf "$EMPTY"

pass
