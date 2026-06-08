#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

for file in brainstorm spec-authoring execution; do
  [ -f "$REPO_ROOT/references/$file.md" ] || fail "missing references/$file.md"
done

FIRST=$(sed -n '1p' "$REPO_ROOT/references/brainstorm.md")
assert_eq "$FIRST" "# Brainstorm" "brainstorm H1"
FIRST=$(sed -n '1p' "$REPO_ROOT/references/spec-authoring.md")
assert_eq "$FIRST" "# Spec Authoring" "spec-authoring H1"
FIRST=$(sed -n '1p' "$REPO_ROOT/references/execution.md")
assert_eq "$FIRST" "# Execution" "execution H1"

SPEC_AUTHORING_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/spec-authoring.md")
assert_match "$SPEC_AUTHORING_BODY" "scope contract" "spec authoring defines task specs as scope contracts"
assert_match "$SPEC_AUTHORING_BODY" "not implementation design" "spec authoring separates specs from implementation design"
assert_match "$SPEC_AUTHORING_BODY" "contract gaps" "spec review blocks contract gaps"
assert_match "$SPEC_AUTHORING_BODY" "execution design" "spec authoring leaves details to execution design"
assert_match "$SPEC_AUTHORING_BODY" "accepted user-facing contract" "spec authoring preserves accepted-detail exception"
assert_match "$SPEC_AUTHORING_BODY" "spawn exactly three reviewer subagents" "spec authoring fixes Spec Review reviewer count"
assert_match "$SPEC_AUTHORING_BODY" "same spec review round must be a distinct subagent instance" "spec authoring requires same-round reviewer independence"
assert_match "$SPEC_AUTHORING_BODY" "three independent reviewer subagents with the \`pipeline-review\` capability" "spec authoring fixes local pipeline review count"

RUNTIME_WORKFLOW_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/runtime-layout-and-workflow.md")
assert_match "$RUNTIME_WORKFLOW_BODY" "spawn exactly three reviewer subagents" "workflow docs fix Spec Review reviewer count"
assert_match "$RUNTIME_WORKFLOW_BODY" "same spec review round must be a distinct subagent instance" "workflow docs require same-round reviewer independence"

PACKS_PIPELINES_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/packs-and-pipelines.md")
assert_match "$PACKS_PIPELINES_BODY" "three independent reviewer subagents with the" "pipeline docs fix local pipeline review count"
assert_match "$PACKS_PIPELINES_BODY" "\`pipeline-review\` capability" "pipeline docs name pipeline-review as capability"

if rg -n "phase-1|phase-2|phase-3" \
  "$REPO_ROOT/README.md" "$REPO_ROOT/SKILL.md" "$REPO_ROOT/docs" "$REPO_ROOT/references" \
  >/tmp/bf-semantic-refs.$$; then
  cat /tmp/bf-semantic-refs.$$ >&2
  rm -f /tmp/bf-semantic-refs.$$
  fail "active runtime/docs still reference old phase filenames"
fi
rm -f /tmp/bf-semantic-refs.$$

if rg -n "spawn 1-3 reviewer subagents|spawn 1–3 reviewer subagents|one to three subagents|capped at ten|cap total at 10" \
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/docs" "$REPO_ROOT/references" \
  >/tmp/bf-semantic-stale-reviewers.$$; then
  cat /tmp/bf-semantic-stale-reviewers.$$ >&2
  rm -f /tmp/bf-semantic-stale-reviewers.$$
  fail "active runtime/docs still reference stale Spec Review reviewer-count guidance"
fi
rm -f /tmp/bf-semantic-stale-reviewers.$$

pass
