#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

make_src() {
  SRC=$(make_temp_home)
  mkdir -p "$SRC/roles" "$SRC/packs/sample" "$SRC/templates" "$SRC/references" "$SRC/bin/lib"
  echo "# SKILL" > "$SRC/SKILL.md"
  echo "# arch role" > "$SRC/roles/architect.md"
  echo "# eng role" > "$SRC/roles/engineer.md"
  echo "# sample pack" > "$SRC/packs/sample/pack.md"
  echo "# bf template" > "$SRC/templates/bf.md"
  echo "# Brainstorm" > "$SRC/references/brainstorm.md"
  echo "# Spec Authoring" > "$SRC/references/spec-authoring.md"
  echo "# Execution" > "$SRC/references/execution.md"
  echo "#!/usr/bin/env node" > "$SRC/bin/bf.mjs"
  cat > "$SRC/package.json" <<'JSON'
{"name":"@codetreker/bf","version":"9.9.9"}
JSON
}

assert_snapshot() {
  local target="$1"
  [ -f "$target/SKILL.md" ] || fail "SKILL.md not copied to $target"
  [ -f "$target/roles/architect.md" ] || fail "roles/architect.md not copied to $target"
  [ -f "$target/roles/engineer.md" ] || fail "roles/engineer.md not copied to $target"
  [ -f "$target/packs/sample/pack.md" ] || fail "packs/sample/pack.md not copied to $target"
  [ -f "$target/templates/bf.md" ] || fail "templates/bf.md not copied to $target"
  [ -f "$target/references/brainstorm.md" ] || fail "references/brainstorm.md not copied to $target"
  [ -f "$target/references/spec-authoring.md" ] || fail "references/spec-authoring.md not copied to $target"
  [ -f "$target/references/execution.md" ] || fail "references/execution.md not copied to $target"
  [ ! -e "$target/bin" ] || fail "bin/ should not be copied to discovery snapshot"
  [ ! -e "$target/package.json" ] || fail "package.json should not be copied to discovery snapshot"
  [ ! -e "$target/extensions" ] || fail "extensions/ should not exist in discovery snapshot"
}

assert_metadata() {
  local target="$1" expected_target="$2" expected_version="$3"
  local metadata="$target/.bf-install.json"
  [ -f "$metadata" ] || fail ".bf-install.json not written to $target"
  assert_json_field "$(cat "$metadata")" .schema "1"
  assert_json_field "$(cat "$metadata")" .package "@codetreker/bf"
  assert_json_field "$(cat "$metadata")" .target "$expected_target"
  assert_json_field "$(cat "$metadata")" .version "$expected_version"
}

run_install_json() {
  local home="$1" target="${2:-}"
  local target_arg=""
  if [ -n "$target" ]; then target_arg=", target: '$target'"; fi
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then(async (m) => {
      const r = await m.cmdInstall({ srcDir: '$SRC', home: '$home', log: () => {} $target_arg });
      process.stdout.write(JSON.stringify(r));
    });
  ")
}

make_src

# Auto-detect both host roots.
HOME_DIR=$(make_temp_home)
mkdir -p "$HOME_DIR/.claude" "$HOME_DIR/.agents"
run_install_json "$HOME_DIR"
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .version "9.9.9"
assert_json_field "$STDOUT" .targets.0.target "claude"
assert_json_field "$STDOUT" .targets.0.status "installed"
assert_match "$STDOUT" '"version":"9.9.9"' "install result records installed version"
assert_json_field "$STDOUT" .targets.1.target "codex"
assert_json_field "$STDOUT" .targets.1.status "installed"
assert_snapshot "$HOME_DIR/.claude/skills/bf"
assert_snapshot "$HOME_DIR/.agents/skills/bf"
assert_metadata "$HOME_DIR/.claude/skills/bf" "claude" "9.9.9"
assert_metadata "$HOME_DIR/.agents/skills/bf" "codex" "9.9.9"
rm -rf "$HOME_DIR"

# Auto-detect Claude only.
HOME_DIR=$(make_temp_home)
mkdir -p "$HOME_DIR/.claude"
run_install_json "$HOME_DIR"
assert_json_field "$STDOUT" .targets.0.target "claude"
[ -f "$HOME_DIR/.claude/skills/bf/SKILL.md" ] || fail "Claude target should be installed"
[ ! -e "$HOME_DIR/.agents/skills/bf" ] || fail "Codex target should not be installed"
rm -rf "$HOME_DIR"

# Auto-detect none: no-op success.
HOME_DIR=$(make_temp_home)
run_install_json "$HOME_DIR"
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .targets '[]'
[ ! -e "$HOME_DIR/.claude/skills/bf" ] || fail "Claude target should not be created"
[ ! -e "$HOME_DIR/.agents/skills/bf" ] || fail "Codex target should not be created"
rm -rf "$HOME_DIR"

# Explicit target bypasses detection.
HOME_DIR=$(make_temp_home)
run_install_json "$HOME_DIR" "codex"
assert_json_field "$STDOUT" .targets.0.target "codex"
assert_json_field "$STDOUT" .targets.0.status "installed"
assert_snapshot "$HOME_DIR/.agents/skills/bf"
assert_metadata "$HOME_DIR/.agents/skills/bf" "codex" "9.9.9"
[ ! -e "$HOME_DIR/.claude/skills/bf" ] || fail "explicit codex target should not install Claude"
rm -rf "$HOME_DIR"

# Reinstall with no metadata refreshes an existing snapshot from unknown version.
HOME_DIR=$(make_temp_home)
mkdir -p "$HOME_DIR/.agents/skills/bf/roles" "$HOME_DIR/.agents/skills/bf/extensions/roles"
echo "# stale" > "$HOME_DIR/.agents/skills/bf/roles/stale.md"
echo "# old extension" > "$HOME_DIR/.agents/skills/bf/extensions/roles/old.md"
run_install_json "$HOME_DIR" "codex"
assert_json_field "$STDOUT" .targets.0.status "updated-from-unknown"
assert_match "$STDOUT" '"previousVersion":null' "unknown update records null previous version"
assert_match "$STDOUT" '"version":"9.9.9"' "unknown update records installed version"
assert_snapshot "$HOME_DIR/.agents/skills/bf"
assert_metadata "$HOME_DIR/.agents/skills/bf" "codex" "9.9.9"
[ ! -e "$HOME_DIR/.agents/skills/bf/roles/stale.md" ] || fail "stale role should be removed by snapshot refresh"
[ ! -e "$HOME_DIR/.agents/skills/bf/extensions" ] || fail "old discovery-target extensions should be removed by snapshot refresh"
rm -rf "$HOME_DIR"

# Reinstall with same metadata is refreshed.
HOME_DIR=$(make_temp_home)
run_install_json "$HOME_DIR" "codex"
run_install_json "$HOME_DIR" "codex"
assert_json_field "$STDOUT" .targets.0.status "refreshed"
assert_match "$STDOUT" '"previousVersion":"9.9.9"' "refresh records previous version"
assert_match "$STDOUT" '"version":"9.9.9"' "refresh records installed version"
assert_metadata "$HOME_DIR/.agents/skills/bf" "codex" "9.9.9"
rm -rf "$HOME_DIR"

# Reinstall with older metadata is updated.
HOME_DIR=$(make_temp_home)
mkdir -p "$HOME_DIR/.agents/skills/bf"
cat > "$HOME_DIR/.agents/skills/bf/.bf-install.json" <<'JSON'
{"schema":1,"package":"@codetreker/bf","version":"9.9.8","target":"codex","installedAt":"2026-06-04T00:00:00.000Z"}
JSON
run_install_json "$HOME_DIR" "codex"
assert_json_field "$STDOUT" .targets.0.status "updated"
assert_match "$STDOUT" '"previousVersion":"9.9.8"' "update records previous version"
assert_match "$STDOUT" '"version":"9.9.9"' "update records installed version"
assert_metadata "$HOME_DIR/.agents/skills/bf" "codex" "9.9.9"
rm -rf "$HOME_DIR"

# CLI invalid target is usage error and mutates nothing.
HOME_DIR=$(make_temp_home)
export HOME="$HOME_DIR"
export BF_INSTALL_DIR="$SRC"
run_bf install
assert_eq "$RC" "0" "install no detected target exits 0"
assert_match "$STDOUT" "BF v9.9.9 install" "install no-op prints version header"
assert_match "$STDOUT" "Detected: none" "install no-op reports no detected targets"
assert_match "$STDOUT" "--target" "install no-op suggests explicit target"
run_bf install --target nope
assert_eq "$RC" "2" "invalid target exits 2"
run_bf install --target
assert_eq "$RC" "2" "missing target value exits 2"
run_bf install --target claude --target codex
assert_eq "$RC" "2" "repeated target exits 2"
run_bf install --target Codex
assert_eq "$RC" "2" "target is case-sensitive"
[ ! -e "$HOME_DIR/.claude/skills/bf" ] || fail "invalid target should not mutate Claude"
[ ! -e "$HOME_DIR/.agents/skills/bf" ] || fail "invalid target should not mutate Codex"
unset HOME BF_INSTALL_DIR
rm -rf "$HOME_DIR" "$SRC"

# CLI output summarizes auto-detected targets and explicit target installs.
make_src
HOME_DIR=$(make_temp_home)
mkdir -p "$HOME_DIR/.claude" "$HOME_DIR/.agents"
export HOME="$HOME_DIR"
export BF_INSTALL_DIR="$SRC"
run_bf install
assert_eq "$RC" "0" "install detected targets exits 0"
assert_match "$STDOUT" "BF v9.9.9 install" "install prints version header"
assert_match "$STDOUT" "Detected: claude, codex" "install prints detected targets"
assert_match "$STDOUT" "claude: installed 9.9.9" "install summarizes Claude install"
assert_match "$STDOUT" "codex: installed 9.9.9" "install summarizes Codex install"
assert_match "$STDOUT" "Extensions: ~/.bf/extensions unchanged" "install reports extension location"
run_bf install --target codex
assert_eq "$RC" "0" "explicit install exits 0"
assert_match "$STDOUT" "Target: codex" "explicit install prints target"
assert_match "$STDOUT" "codex: refreshed 9.9.9" "explicit install summarizes refresh"
unset HOME BF_INSTALL_DIR
rm -rf "$HOME_DIR" "$SRC"

# Real package snapshot includes semantic references and pipeline-designer role.
HOME_DIR=$(make_temp_home)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-install.mjs').then(async (m) => {
    const r = await m.cmdInstall({ srcDir: '$REPO_ROOT', home: '$HOME_DIR', target: 'codex', log: () => {} });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok true
TARGET="$HOME_DIR/.agents/skills/bf"
[ -f "$TARGET/roles/pipeline-designer.md" ] || fail "pipeline-designer role not copied"
[ -f "$TARGET/references/brainstorm.md" ] || fail "brainstorm reference not copied"
[ -f "$TARGET/references/spec-authoring.md" ] || fail "spec-authoring reference not copied"
[ -f "$TARGET/references/execution.md" ] || fail "execution reference not copied"
[ -f "$TARGET/templates/pipeline.yml" ] || fail "pipeline template not copied"
rm -rf "$HOME_DIR"

pass
