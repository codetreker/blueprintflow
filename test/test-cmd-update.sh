#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

make_npm_shim() {
  local bin_dir="$1" log_file="$2" exit_code="$3"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/npm" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$log_file"
exit "$exit_code"
EOF
  chmod +x "$bin_dir/npm"
}

# Successful update invokes exactly the global latest-package npm upgrade.
HOME_DIR=$(make_temp_home)
BIN_DIR=$(make_temp_home)
LOG_FILE="$HOME_DIR/npm.log"
mkdir -p "$HOME_DIR/.claude" "$HOME_DIR/.codex"
make_npm_shim "$BIN_DIR" "$LOG_FILE" 0
export HOME="$HOME_DIR"
export PATH="$BIN_DIR:$PATH"
run_bf update
assert_eq "$RC" "0" "update exits 0 when npm upgrade succeeds"
assert_match "$STDOUT" "BF update: npm install -g @codetreker/bf@latest" "update prints upgrade command"
assert_eq "$(cat "$LOG_FILE")" "install -g @codetreker/bf@latest" "update invokes expected npm command exactly once"
[ ! -e "$HOME_DIR/.claude/skills/bf" ] || fail "update should not directly refresh Claude snapshot"
[ ! -e "$HOME_DIR/.codex/skills/bf" ] || fail "update should not directly refresh Codex snapshot"
unset HOME
PATH="${PATH#"$BIN_DIR:"}"
rm -rf "$HOME_DIR" "$BIN_DIR"

# Failed npm upgrade propagates as a command failure.
HOME_DIR=$(make_temp_home)
BIN_DIR=$(make_temp_home)
LOG_FILE="$HOME_DIR/npm.log"
make_npm_shim "$BIN_DIR" "$LOG_FILE" 37
export HOME="$HOME_DIR"
export PATH="$BIN_DIR:$PATH"
run_bf update
assert_eq "$RC" "1" "update exits 1 when npm upgrade fails"
assert_match "$STDOUT" "BF update: npm install -g @codetreker/bf@latest" "failed update prints upgrade command"
assert_eq "$(cat "$LOG_FILE")" "install -g @codetreker/bf@latest" "failed update invokes expected npm command"
unset HOME
PATH="${PATH#"$BIN_DIR:"}"
rm -rf "$HOME_DIR" "$BIN_DIR"

# Unsupported arguments are usage errors and do not invoke npm.
HOME_DIR=$(make_temp_home)
BIN_DIR=$(make_temp_home)
LOG_FILE="$HOME_DIR/npm.log"
make_npm_shim "$BIN_DIR" "$LOG_FILE" 0
export HOME="$HOME_DIR"
export PATH="$BIN_DIR:$PATH"
run_bf update --target codex
assert_eq "$RC" "2" "update unsupported argument exits 2"
assert_match "$STDERR" "unknown option: --target" "unsupported update argument reports usage error"
[ ! -e "$LOG_FILE" ] || fail "unsupported update argument should not invoke npm"
unset HOME
PATH="${PATH#"$BIN_DIR:"}"
rm -rf "$HOME_DIR" "$BIN_DIR"

# Help includes the update command.
run_bf --help
assert_eq "$RC" "0" "help exits 0"
assert_match "$STDOUT" "bf update" "help lists update command"

pass
