#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

TEMPLATE_FILES=()
while IFS= read -r file; do
  TEMPLATE_FILES+=("$file")
done < <(find "$REPO_ROOT/templates" -maxdepth 1 -type f | sort)

[ "${#TEMPLATE_FILES[@]}" -gt 0 ] || fail "expected shipped runtime templates"

if rg -n '[\p{Han}]' "$REPO_ROOT/templates" >/tmp/bf-template-language.$$; then
  cat /tmp/bf-template-language.$$ >&2
  rm -f /tmp/bf-template-language.$$
  fail "shipped runtime templates must not contain Chinese text"
fi
rm -f /tmp/bf-template-language.$$

BF_TEMPLATE=$(cat "$REPO_ROOT/templates/bf.md")
assert_match "$BF_TEMPLATE" "State: Draft|Accepted|Implementing|Completed" "bf template keeps state values"
assert_match "$BF_TEMPLATE" "## Acceptance Criteria" "bf template keeps AC heading"
assert_match "$BF_TEMPLATE" "- [ ] {id1}|{capability}:" "bf template keeps AC marker example"
assert_match "$BF_TEMPLATE" "## Task List" "bf template keeps task-list heading"

DISCUSSION_TEMPLATE=$(cat "$REPO_ROOT/templates/discussion.md")
assert_match "$DISCUSSION_TEMPLATE" "# Discussion Log" "discussion template keeps English H1"
assert_match "$DISCUSSION_TEMPLATE" "bf.md is derived from discussion.md" "discussion template keeps bf relationship"

TASK_TEMPLATE=$(cat "$REPO_ROOT/templates/task-spec.md")
assert_match "$TASK_TEMPLATE" "State: Draft|Ready|Tasking|Completed" "task template keeps state values"
assert_match "$TASK_TEMPLATE" "Requires-Worktree: true|false" "task template keeps worktree field"
assert_match "$TASK_TEMPLATE" "## Evidence" "task template keeps Evidence heading"
assert_match "$TASK_TEMPLATE" "- {evidence-id}|{ac-id}|{kind}:" "task template keeps Evidence grammar"
assert_match "$TASK_TEMPLATE" "EV-1|AC-1|command:" "task template keeps command evidence example"

REVIEW_TEMPLATE=$(cat "$REPO_ROOT/templates/review-result.md")
assert_match "$REVIEW_TEMPLATE" "### Blocker" "review template keeps Blocker heading"
assert_match "$REVIEW_TEMPLATE" "### High" "review template keeps High heading"
assert_match "$REVIEW_TEMPLATE" "### Minor" "review template keeps Minor heading"
assert_match "$REVIEW_TEMPLATE" "### Nit" "review template keeps Nit heading"
assert_match "$REVIEW_TEMPLATE" "## Accepted Criteria" "review template keeps accepted criteria heading"
assert_match "$REVIEW_TEMPLATE" "at least one provider-role review file" "review template keeps provider-role semantics"

ROLE_TEMPLATE=$(cat "$REPO_ROOT/templates/role.md")
assert_match "$ROLE_TEMPLATE" "Capabilities:" "role template keeps capabilities field"
assert_match "$ROLE_TEMPLATE" "  - <capability-1>" "role template keeps capability list shape"
assert_match "$ROLE_TEMPLATE" "## Identity" "role template keeps Identity heading"

PACK_TEMPLATE=$(cat "$REPO_ROOT/templates/pack.md")
assert_match "$PACK_TEMPLATE" "## When to Use" "pack template keeps required When to Use heading"
assert_match "$PACK_TEMPLATE" "## Brainstorm Guidance" "pack template keeps Brainstorm Guidance heading"
assert_match "$PACK_TEMPLATE" "## Execute Guidance" "pack template keeps Execute Guidance heading"

PIPELINE_TEMPLATE=$(cat "$REPO_ROOT/templates/pipeline.yml")
assert_match "$PIPELINE_TEMPLATE" "id: <pipeline-id>" "pipeline template keeps id field"
assert_match "$PIPELINE_TEMPLATE" "stages:" "pipeline template keeps stages field"
assert_match "$PIPELINE_TEMPLATE" "capability: <capability>" "pipeline template keeps scalar capability field"
assert_match "$PIPELINE_TEMPLATE" "reviews: <artifact-path>" "pipeline template keeps reviews field"

pass
