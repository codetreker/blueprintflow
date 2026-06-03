#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/references/execution.md"
WORKFLOW_DOC="$REPO_ROOT/docs/spec/runtime-layout-and-workflow.md"
PACKS_DOC="$REPO_ROOT/docs/spec/packs-and-pipelines.md"

grep -q "^## Pipeline promotion suggestions$" "$FILE" || fail "execution reference must include pipeline promotion suggestion section"
grep -q "advisory only" "$FILE" || fail "promotion suggestion must be advisory only"
grep -q "must not promote local pipelines" "$FILE" || fail "execution reference must forbid automatic promotion"
grep -q "edit extension packs" "$FILE" || fail "execution reference must forbid extension pack edits"
grep -q "create files" "$FILE" || fail "execution reference must forbid file creation"
grep -q "open a PR" "$FILE" || fail "execution reference must forbid PR creation"
grep -q "explicit user request" "$FILE" || fail "promotion workflow must require explicit user request"
grep -q "bf-wo local pipeline" "$FILE" || fail "guidance must mention bf-wo local pipeline"

grep -q "must not promote local pipelines" "$WORKFLOW_DOC" || fail "workflow docs must forbid automatic promotion"
grep -q "edit extension packs" "$WORKFLOW_DOC" || fail "workflow docs must forbid extension pack edits"
grep -q "create files" "$WORKFLOW_DOC" || fail "workflow docs must forbid file creation"
grep -q "open a PR" "$WORKFLOW_DOC" || fail "workflow docs must forbid PR creation"
grep -q "explicit user request" "$WORKFLOW_DOC" || fail "workflow docs must require explicit user request"

grep -q "explicit user request" "$PACKS_DOC" || fail "pack pipeline docs must require explicit user request for promotion"
if grep -q "pack-level pipeline" "$PACKS_DOC"; then
  fail "pack pipeline docs must not use outdated pack-level pipeline promotion wording"
fi

pass
