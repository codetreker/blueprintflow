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

# CLI-level: `bf list-packs` prints one labeled key:value block per pack
# (Id/Desc/Source). No pipe separator. No trailing whitespace.
ROOT=$(make_temp_home)
mkdir -p "$ROOT/packs"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
export BF_INSTALL_DIR="$ROOT"
# Force empty extension dirs by pointing BF_HOME at a fresh dir.
EMPTY_HOME=$(make_temp_home)
export BF_HOME="$EMPTY_HOME"
run_bf list-packs
assert_eq "$RC" "0" "list-packs exit 0"
ID_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^Id: engineering$')
assert_eq "$ID_ROWS" "1" "list-packs has one 'Id: engineering' line"
SRC_ROWS=$(printf "%s\n" "$STDOUT" | grep -cE '^Source: core$')
assert_eq "$SRC_ROWS" "1" "list-packs has one 'Source: core' line"
# Labeled shape: no pipe separator anywhere in the output.
if printf "%s\n" "$STDOUT" | grep -qE ' \| '; then
  fail "list-packs output unexpectedly contains pipe separator"
fi
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in list-packs stdout"
unset BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$EMPTY_HOME"

# CLI-level: global extensions live under $HOME/.bf/extensions; host discovery
# extensions are ignored.
ROOT=$(make_temp_home)
HOME_DIR=$(make_temp_home)
BASE=$(make_temp_home)
mkdir -p "$ROOT/packs" "$HOME_DIR/.bf/extensions/packs/global-pack" "$HOME_DIR/.claude/skills/bf/extensions/packs/ignored-pack"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
cat > "$HOME_DIR/.bf/extensions/packs/global-pack/pack.md" <<'EOF'
---
Id: global-pack
Desc: Global extension pack
---

## When to Use

Testing global extension pack discovery.
EOF
cat > "$HOME_DIR/.claude/skills/bf/extensions/packs/ignored-pack/pack.md" <<'EOF'
---
Id: ignored-pack
Desc: Ignored host discovery pack
---

## When to Use

Should not be read.
EOF
export HOME="$HOME_DIR"
export BF_INSTALL_DIR="$ROOT"
export BF_HOME="$BASE"
run_bf list-packs
assert_eq "$RC" "0" "list-packs with global extensions exit 0"
assert_match "$STDOUT" "Id: global-pack" "global extension pack listed"
assert_not_match "$STDOUT" "ignored-pack" "host discovery extension pack ignored"
unset HOME BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$HOME_DIR" "$BASE"

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
