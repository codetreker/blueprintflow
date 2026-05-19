#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

run_bf --help
assert_eq "$RC" "0" "bf --help exit code"
assert_match "$STDOUT" "bf list-roles" "bf --help output"

run_bfh --help
assert_eq "$RC" "0" "bf-harness --help exit code"
assert_match "$STDOUT" "bf-harness" "bf-harness --help output"

run_bf nonexistent
assert_eq "$RC" "2" "bf unknown subcmd exit code"

run_bfh nonexistent
assert_eq "$RC" "2" "bf-harness unknown subcmd exit code"

pass
