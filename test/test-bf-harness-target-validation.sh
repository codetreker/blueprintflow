#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
export BF_HOME="$BASE"

# Path traversal in woId
run_bfh lint "myproj/.."
assert_eq "$RC" "2" "lint .. exits 2"
assert_match "$STDERR" "invalid" "lint .. stderr mentions invalid"

# Path traversal in projectSlug
run_bfh lint "../etc/passwd"
assert_eq "$RC" "2" "lint ../etc rejected"
assert_match "$STDERR" "invalid" "../etc stderr mentions invalid"

# Dot segment
run_bfh discard "p/."
assert_eq "$RC" "2" "discard . rejected"

# Empty segment
run_bfh accept "p/"
assert_eq "$RC" "2" "accept empty woId rejected"

# Too many segments
run_bfh lint "a/b/c/d"
assert_eq "$RC" "2" "lint extra segments rejected"

# Missing target altogether
run_bfh lint
assert_eq "$RC" "2" "missing target rejected"

rm -rf "$BASE"
unset BF_HOME
pass
