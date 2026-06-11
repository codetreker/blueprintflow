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
assert_match "$STDOUT" '"id":"e2e-verification-setup"' "e2e setup pipeline included"
assert_match "$STDOUT" '"desc":"Set up reusable E2E verification for repositories without a local protocol"' "e2e setup pipeline description"
assert_match "$STDOUT" '"id":"feature"' "feature pipeline included"
assert_match "$STDOUT" '"desc":"Feature task pipeline"' "feature pipeline description"
assert_json_field "$STDOUT" .pipelines.0.pack "engineering"
assert_json_field "$STDOUT" .pipelines.0.source "core"
assert_match "$STDOUT" "packs/engineering/pipelines/feature.yml" "pipeline path"
assert_match "$STDOUT" "packs/engineering/pipelines/e2e-verification-setup.yml" "e2e pipeline path"

# --pack filters to the effective pack registry entry.
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$ROOT', pack: 'engineering' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_match "$STDOUT" '"id":"e2e-verification-setup"' "pack filter includes e2e setup pipeline"
assert_match "$STDOUT" '"id":"feature"' "pack filter includes feature pipeline"

# Missing pack matches list-roles --pack behavior.
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$ROOT', pack: 'nope' })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "pack not found: nope" "missing pack error"

rm -rf "$ROOT"

# Extension pack pipelines merge with core pack pipelines; same id overrides.
ROOT=$(make_temp_home)
EXT=$(make_temp_home)
PROJECT_EXT=$(make_temp_home)
mkdir -p "$ROOT/packs" "$EXT/packs/engineering/pipelines" "$PROJECT_EXT/packs/engineering/pipelines"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
cat > "$EXT/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Global extension engineering pack
---

## When to Use

Extension pack.
EOF
cat > "$EXT/packs/engineering/pipelines/custom.yml" <<'EOF'
id: custom
desc: Custom extension pipeline
EOF
cat > "$EXT/packs/engineering/pipelines/feature.yml" <<'EOF'
id: feature
desc: Global feature override
EOF
cat > "$PROJECT_EXT/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Project extension engineering pack
---

## When to Use

Project extension pack.
EOF
cat > "$PROJECT_EXT/packs/engineering/pipelines/project-only.yml" <<'EOF'
id: project-only
desc: Project-only extension pipeline
EOF
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({
      cwd: '$ROOT', pack: 'engineering', extensionPacksDirs: ['$EXT/packs', '$PROJECT_EXT/packs'],
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_match "$STDOUT" "custom" "global extension pipeline included"
assert_match "$STDOUT" "project-only" "project extension pipeline included"
assert_match "$STDOUT" "Global feature override" "global extension feature overrides core feature"
assert_not_match "$STDOUT" "Feature task pipeline" "core feature pipeline overridden"
rm -rf "$ROOT" "$EXT" "$PROJECT_EXT"

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
  assert_eq "$count" "2" "list-pipelines stdout has exactly two '^${label}' lines"
done
assert_match "$STDOUT" "Id: e2e-verification-setup" "E2E setup Id line value"
assert_match "$STDOUT" "Desc: Set up reusable E2E verification for repositories without a local protocol" "E2E setup Desc line value"
assert_match "$STDOUT" "Id: feature" "Id line value"
assert_not_match "$STDOUT" "Pack:" "list-pipelines omits pack details"
assert_not_match "$STDOUT" "Source:" "list-pipelines omits source details"
assert_not_match "$STDOUT" "Stages:" "list-pipelines does not print stage details"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in list-pipelines stdout"
unset BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$EMPTY_HOME"

# CLI-level: global extension pack pipelines live under $HOME/.bf/extensions.
ROOT=$(make_temp_home)
HOME_DIR=$(make_temp_home)
BASE=$(make_temp_home)
mkdir -p "$ROOT/packs" "$HOME_DIR/.bf/extensions/packs/engineering/pipelines" "$HOME_DIR/.codex/skills/bf/extensions/packs/engineering/pipelines"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
cat > "$HOME_DIR/.bf/extensions/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Global extension engineering pack
---

## When to Use

Testing global extension pipeline discovery.
EOF
cat > "$HOME_DIR/.bf/extensions/packs/engineering/pipelines/custom.yml" <<'EOF'
id: custom
desc: Custom global extension pipeline
EOF
cat > "$HOME_DIR/.codex/skills/bf/extensions/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Ignored host discovery engineering pack
---

## When to Use

Should not be read.
EOF
cat > "$HOME_DIR/.codex/skills/bf/extensions/packs/engineering/pipelines/ignored.yml" <<'EOF'
id: ignored
desc: Ignored host discovery pipeline
EOF
export HOME="$HOME_DIR"
export BF_INSTALL_DIR="$ROOT"
export BF_HOME="$BASE"
run_bf list-pipelines --pack engineering
assert_eq "$RC" "0" "list-pipelines with global extension pack exit 0"
assert_match "$STDOUT" "Id: custom" "global extension pipeline listed"
assert_match "$STDOUT" "feature" "core pipeline remains when global extension adds custom pipeline"
assert_not_match "$STDOUT" "ignored" "host discovery extension pipeline ignored"
unset HOME BF_INSTALL_DIR BF_HOME
rm -rf "$ROOT" "$HOME_DIR" "$BASE"

pass
