#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

assert_file() {
  local path="$1"
  [ -f "$REPO_ROOT/$path" ] || fail "missing $path"
}

assert_file "docs/spec/automation-runs.md"
assert_file "references/automation.md"

SPEC_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/automation-runs.md")
ROOT_SPEC_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec.md")
SKILL_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/SKILL.md")
REF_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/automation.md")

assert_match "$ROOT_SPEC_BODY" "automation runs" "design entrypoint should expose automation runs"
assert_match "$ROOT_SPEC_BODY" "spec/automation-runs.md" "design entrypoint should link automation run design"

for term in \
  "external trigger" \
  "bounded run" \
  "cursor" \
  "run record" \
  "no-op" \
  "ordinary bf work object" \
  ".bf/automations/<automation-id>/definition.md" \
  ".bf/automations/<automation-id>/cursor.json" \
  ".bf/automations/<automation-id>/runs/<timestamp>/run.md"
do
  assert_match "$SPEC_BODY" "$term" "automation design should define $term"
done

for term in "scheduler" "daemon" "polling" "webhook server" "worker pool" "lease" "retry" "automation cli" "automatic approval" "automatic merge"; do
  assert_match "$SPEC_BODY" "$term" "automation design should state v1 non-goal $term"
done

assert_match "$SKILL_BODY" "references/automation.md" "root runtime should expose automation reference"
assert_match "$SKILL_BODY" "externally triggered automation run" "root runtime should scope automation to external triggers"
assert_match "$SKILL_BODY" "ordinary \$bf execution remains user-driven" "root runtime should preserve normal BF entry behavior"
assert_match "$SKILL_BODY" "not automatic background work" "root runtime should reject background automation on normal BF entry"

assert_not_match "$REF_BODY" "docs/" "automation runtime reference must not depend on docs/"
assert_not_match "$REF_BODY" "docs/spec" "automation runtime reference must not depend on design docs"

for term in \
  "external trigger" \
  "one bounded automation run" \
  "definition.md" \
  "cursor.json" \
  "runs/<timestamp>/run.md" \
  "run record" \
  "update the cursor" \
  "no-op" \
  "ordinary bf work object" \
  "normal bf gates" \
  "independent verification" \
  "pr readiness"
do
  assert_match "$REF_BODY" "$term" "automation runtime reference should cover $term"
done

BOUNDARY=$(awk '/^## V1 Boundary/{flag=1;next}/^## /{flag=0}flag' "$REPO_ROOT/references/automation.md" | tr '[:upper:]' '[:lower:]')
assert_match "$BOUNDARY" "do not" "automation runtime boundary should be directive"
for term in "scheduler" "daemon" "polling" "webhook server" "worker pool" "lease" "retry" "automation cli"; do
  assert_match "$BOUNDARY" "$term" "automation runtime boundary should exclude $term"
done

pass
