#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
export BF_HOME="$BASE"
export BF_PROJECT="myproj"

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

# --project flag overrides BF_PROJECT (still rejected by arity, but slug should be accepted)
run_bfh --project other-proj list
assert_match "$STDOUT" "\"ok\"" "list with --project flag emits JSON"
assert_not_match "$STDERR" "Usage" "no usage error with valid --project"

# --project flag with malformed slug should fail with usage
run_bfh --project "../bad" list
assert_eq "$RC" "2" "--project with traversal rejected"
assert_match "$STDERR" "invalid project slug" "slug validation error"

# Missing value after --project
run_bfh --project
assert_eq "$RC" "2" "--project without value rejected"
assert_match "$STDERR" "requires a value" "flag missing value error"

# Slug defaults to cwd basename when no BF_PROJECT / flag
unset BF_PROJECT
CWD_PARENT=$(mktemp -d -t bf-slug-XXXXXX)
CWD_DIR="$CWD_PARENT/some-cwd-slug"
mkdir -p "$CWD_DIR" "$BASE/projects/some-cwd-slug/wo-marker"
STDOUT=$(cd "$CWD_DIR" && node "$BFH" list 2>/tmp/bfh-slug-err.$$); RC=$?
STDERR=$(cat /tmp/bfh-slug-err.$$ 2>/dev/null || true); rm -f /tmp/bfh-slug-err.$$
# cmdList walks BF_HOME/<slug>/; we planted wo-marker/ (no bf.md) → expect a warning mentioning wo-marker
assert_match "$STDOUT" "wo-marker" "cwd basename used as projectSlug"
assert_not_match "$STDERR" "Usage" "no usage error with cwd-derived slug"
rm -rf "$CWD_PARENT"
rm -rf "$CWD_PARENT"
rm -rf "$BASE"
unset BF_HOME
pass
