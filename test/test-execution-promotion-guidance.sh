#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/references/execution.md"

grep -q "^## Pipeline promotion suggestions$" "$FILE" || fail "execution reference must include pipeline promotion suggestion section"
grep -q "advisory only" "$FILE" || fail "promotion suggestion must be advisory only"
grep -q "must not promote local pipelines" "$FILE" || fail "execution reference must forbid automatic promotion"
grep -q "edit extension packs" "$FILE" || fail "execution reference must forbid extension pack edits"
grep -q "create files" "$FILE" || fail "execution reference must forbid file creation"
grep -q "open a PR" "$FILE" || fail "execution reference must forbid PR creation"
grep -q "explicit user request" "$FILE" || fail "promotion workflow must require explicit user request"
grep -q "bf-wo local pipeline" "$FILE" || fail "guidance must mention bf-wo local pipeline"

pass
