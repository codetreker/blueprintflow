#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
export BF_HOME="$BASE"

# Path traversal in woId
run_bfh lint ".."
assert_eq "$RC" "2" "lint .. exits 2"
assert_match "$STDERR" "invalid" "lint .. stderr mentions invalid"

# Path traversal segment
run_bfh lint "../etc"
assert_eq "$RC" "2" "lint ../etc rejected"
assert_match "$STDERR" "invalid" "../etc stderr mentions invalid"

# Dot segment as task
run_bfh verify "wo-x/."
assert_eq "$RC" "2" "verify . task rejected"

# Empty segment
run_bfh verify "wo-x/"
assert_eq "$RC" "2" "verify empty taskId rejected"

# Too many segments
run_bfh lint "a/b/c"
assert_eq "$RC" "2" "lint extra segments rejected"

# Missing target altogether (lint requires wo)
run_bfh lint
assert_eq "$RC" "2" "missing target rejected"
assert_match "$STDERR" "lint requires" "lint arity error"

# Arity: list must not have positional target
run_bfh list "wo-x"
assert_eq "$RC" "2" "list with positional rejected"
assert_match "$STDERR" "list" "list arity error mentions list"

# Arity: accept must not have taskId
run_bfh accept "wo-x/task-1"
assert_eq "$RC" "2" "accept with taskId rejected"
assert_match "$STDERR" "task" "accept arity error mentions task"

# Arity: discard must not have taskId
run_bfh discard "wo-x/task-1"
assert_eq "$RC" "2" "discard with taskId rejected"

# Arity: next requires woId
run_bfh next
assert_eq "$RC" "2" "next without woId rejected"

# Arity: status requires woId and rejects taskId
run_bfh status
assert_eq "$RC" "2" "status without woId rejected"
assert_match "$STDERR" "status requires" "status arity error"
run_bfh status "wo-x/task-1"
assert_eq "$RC" "2" "status with taskId rejected"
assert_match "$STDERR" "status does not accept a task id" "status task arity error"

# baseHome defaults to <cwd>/.bf when BF_HOME unset
unset BF_HOME
CWD_DIR=$(mktemp -d -t bf-cwd-XXXXXX)
mkdir -p "$CWD_DIR/.bf/works/wo-marker"
STDOUT=$(cd "$CWD_DIR" && node "$BFH" list 2>/tmp/bfh-cwd-err.$$); RC=$?
STDERR=$(cat /tmp/bfh-cwd-err.$$ 2>/dev/null || true); rm -f /tmp/bfh-cwd-err.$$
# cmdList walks baseHome/works; wo-marker has no bf.md, so the warning should name it.
assert_match "$STDOUT" "wo-marker" "default baseHome is <cwd>/.bf"
assert_not_match "$STDERR" "Usage" "no usage error with default baseHome"
rm -rf "$CWD_DIR"
rm -rf "$BASE"
pass
