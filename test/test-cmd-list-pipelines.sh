#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

ROOT=$(make_temp_home)
mkdir -p "$ROOT/packs"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$ROOT' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .pipelines.0.id "feature"
assert_json_field "$STDOUT" .pipelines.0.desc "Feature task pipeline"
assert_json_field "$STDOUT" .pipelines.0.pack "engineering"
assert_json_field "$STDOUT" .pipelines.0.source "core"
assert_match "$STDOUT" "packs/engineering/pipelines/feature.yml" "pipeline path"

# --pack filters to the effective pack registry entry.
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$ROOT', pack: 'engineering' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .pipelines.0.id "feature"

# Missing pack matches list-roles --pack behavior.
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$ROOT', pack: 'nope' })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "pack not found: nope" "missing pack error"

rm -rf "$ROOT"

# Extension pack overrides the core pack as a whole; pipelines do not merge.
ROOT=$(make_temp_home)
EXT=$(make_temp_home)
mkdir -p "$ROOT/packs" "$EXT/packs/engineering/pipelines"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
cat > "$EXT/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Extension engineering pack
---

## When to Use

Extension pack.
EOF
cat > "$EXT/packs/engineering/pipelines/custom.yml" <<'EOF'
id: custom
desc: Custom extension pipeline
EOF
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({
      cwd: '$ROOT', pack: 'engineering', extensionPacksDirs: ['$EXT/packs'],
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .pipelines.0.id "custom"
assert_json_field "$STDOUT" .pipelines.0.source "extension"
assert_not_match "$STDOUT" "feature" "core pipeline hidden by extension pack override"
rm -rf "$ROOT" "$EXT"

# CLI-level: `bf list-pipelines` prints one labeled key:value block per pipeline.
ROOT=$(make_temp_home)
mkdir -p "$ROOT/packs"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
EMPTY_HOME=$(make_temp_home)
export BF_INSTALL_DIR="$ROOT"
export BF_HOME="$EMPTY_HOME"
run_bf list-pipelines --pack engineering
assert_eq "$RC" "0" "list-pipelines exit 0"
for label in "Id:" "Desc:" "Path:"; do
  count=$(printf "%s\n" "$STDOUT" | grep -c "^${label}")
  assert_eq "$count" "1" "list-pipelines stdout has exactly one '^${label}' line"
done
assert_match "$STDOUT" "Id: feature" "Id line value"
assert_not_match "$STDOUT" "Pack:" "list-pipelines omits pack details"
assert_not_match "$STDOUT" "Source:" "list-pipelines omits source details"
assert_not_match "$STDOUT" "Stages:" "list-pipelines does not print stage details"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in list-pipelines stdout"
unset BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$EMPTY_HOME"

pass
