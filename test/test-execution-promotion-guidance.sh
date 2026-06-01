#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/references/execution.md"

grep -q "^## Pipeline promotion suggestions$" "$FILE" || fail "execution reference must include pipeline promotion suggestion section"
grep -q "advisory only" "$FILE" || fail "promotion suggestion must be advisory only"
grep -q "must not promote" "$FILE" || fail "execution reference must forbid automatic promotion"
grep -q "explicit user request" "$FILE" || fail "promotion workflow must require explicit user request"
grep -q "bf-wo local pipeline" "$FILE" || fail "guidance must mention bf-wo local pipeline"

pass
