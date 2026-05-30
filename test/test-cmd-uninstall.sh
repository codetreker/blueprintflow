#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

make_target() {
  local target="$1"
  mkdir -p "$target/roles" "$target/packs"
  echo "# SKILL" > "$target/SKILL.md"
  echo "# role" > "$target/roles/engineer.md"
  echo "# pack" > "$target/packs/pack.md"
}

run_uninstall_json() {
  local home="$1" target="${2:-}"
  local target_arg=""
  if [ -n "$target" ]; then target_arg=", target: '$target'"; fi
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/bf/cmd-uninstall.mjs').then(async (m) => {
      const r = await m.cmdUninstall({ home: '$home', log: () => {} $target_arg });
      process.stdout.write(JSON.stringify(r));
    });
  ")
}

# Auto-detect both existing targets and remove both snapshots.
HOME_DIR=$(make_temp_home)
make_target "$HOME_DIR/.claude/skills/bf"
make_target "$HOME_DIR/.agents/skills/bf"
run_uninstall_json "$HOME_DIR"
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .targets.0.target "claude"
assert_json_field "$STDOUT" .targets.0.status "removed"
assert_json_field "$STDOUT" .targets.1.target "codex"
assert_json_field "$STDOUT" .targets.1.status "removed"
[ ! -e "$HOME_DIR/.claude/skills/bf" ] || fail "Claude target should be removed"
[ ! -e "$HOME_DIR/.agents/skills/bf" ] || fail "Codex target should be removed"
rm -rf "$HOME_DIR"

# Auto-detect only Claude.
HOME_DIR=$(make_temp_home)
make_target "$HOME_DIR/.claude/skills/bf"
run_uninstall_json "$HOME_DIR"
assert_json_field "$STDOUT" .targets.0.target "claude"
assert_json_field "$STDOUT" .targets.0.status "removed"
[ ! -e "$HOME_DIR/.claude/skills/bf" ] || fail "Claude target should be removed"
[ ! -e "$HOME_DIR/.agents/skills/bf" ] || fail "Codex target should not be created"
rm -rf "$HOME_DIR"

# Auto-detect none: no-op success.
HOME_DIR=$(make_temp_home)
run_uninstall_json "$HOME_DIR"
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .targets '[]'
rm -rf "$HOME_DIR"

# Explicit target removes only selected snapshot.
HOME_DIR=$(make_temp_home)
make_target "$HOME_DIR/.claude/skills/bf"
make_target "$HOME_DIR/.agents/skills/bf"
run_uninstall_json "$HOME_DIR" "codex"
assert_json_field "$STDOUT" .targets.0.target "codex"
assert_json_field "$STDOUT" .targets.0.status "removed"
[ -f "$HOME_DIR/.claude/skills/bf/SKILL.md" ] || fail "explicit codex uninstall should leave Claude"
[ ! -e "$HOME_DIR/.agents/skills/bf" ] || fail "explicit codex target should be removed"
rm -rf "$HOME_DIR"

# Explicit missing target is success with missing status.
HOME_DIR=$(make_temp_home)
run_uninstall_json "$HOME_DIR" "codex"
assert_json_field "$STDOUT" .targets.0.target "codex"
assert_json_field "$STDOUT" .targets.0.status "missing"
rm -rf "$HOME_DIR"

# CLI invalid target is usage error and mutates nothing.
HOME_DIR=$(make_temp_home)
export HOME="$HOME_DIR"
run_bf uninstall
assert_eq "$RC" "0" "uninstall no detected target exits 0"
assert_match "$STDOUT" "--target" "uninstall no-op suggests explicit target"
make_target "$HOME_DIR/.claude/skills/bf"
run_bf uninstall --target nope
assert_eq "$RC" "2" "invalid target exits 2"
run_bf uninstall --target
assert_eq "$RC" "2" "missing target value exits 2"
run_bf uninstall --target claude --target codex
assert_eq "$RC" "2" "repeated target exits 2"
run_bf uninstall --target Codex
assert_eq "$RC" "2" "target is case-sensitive"
[ -f "$HOME_DIR/.claude/skills/bf/SKILL.md" ] || fail "invalid target should not mutate Claude"
unset HOME
rm -rf "$HOME_DIR"

pass
