#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

read_semantic_body() {
  tr '[:upper:]' '[:lower:]' < "$1" | tr '\n' ' ' | sed 's/[[:space:]][[:space:]]*/ /g'
}

ROLE_BODY=$(read_semantic_body "$REPO_ROOT/roles/interaction-designer.md")
TESTER_BODY=$(read_semantic_body "$REPO_ROOT/roles/tester.md")
SPEC_BODY=$(read_semantic_body "$REPO_ROOT/docs/spec.md")
PACKS_PIPELINES_BODY=$(read_semantic_body "$REPO_ROOT/docs/spec/packs-and-pipelines.md")

assert_match "$ROLE_BODY" "central coordinator-consumable rule" "interaction designer role should centralize routing guidance"
assert_match "$ROLE_BODY" "brainstorm or spec" "interaction designer role should cover brainstorm/spec inclusion"
assert_match "$ROLE_BODY" "implementation design or review" "interaction designer role should cover execution design/review inclusion"
assert_match "$ROLE_BODY" "task verification or final acceptance" "interaction designer role should cover verification/final acceptance inclusion"
assert_match "$ROLE_BODY" "tagged \`interaction-design\`" "interaction designer role should tie signoff to interaction-design AC tags"
assert_match "$ROLE_BODY" "api, cli, backend-only behavior" "interaction designer role should name non-default API/CLI/backend cases"
assert_match "$ROLE_BODY" "invisible ui refactors" "interaction designer role should name non-default invisible UI refactors"
assert_match "$ROLE_BODY" "small clear copy or style edits" "interaction designer role should name non-default copy/style edits"
assert_match "$ROLE_BODY" "unless the accepted ac depends on interaction flow, ui state, layout, or ux judgment" "interaction designer role should preserve the exception for UI interaction judgment"

assert_match "$TESTER_BODY" "do not replace \`interaction-design\` capability signoff" "tester role should keep UI reference guidance separate from interaction-design signoff"

assert_match "$SPEC_BODY" "\`interaction-design\` capability" "top-level spec should record interaction-design routing"
assert_match "$SPEC_BODY" "tagged \`interaction-design\`" "top-level spec should record tagged-AC signoff"
assert_match "$SPEC_BODY" "tester ui review references" "top-level spec should distinguish tester UI references"
assert_match "$SPEC_BODY" "do not replace \`interaction-design\` capability signoff" "top-level spec should keep tester QA distinct from interaction-design"

assert_match "$PACKS_PIPELINES_BODY" "central coordinator-consumable rule" "packs and pipelines spec should record central routing guidance"
assert_match "$PACKS_PIPELINES_BODY" "brainstorm/spec" "packs and pipelines spec should record brainstorm/spec inclusion"
assert_match "$PACKS_PIPELINES_BODY" "implementation design or review" "packs and pipelines spec should record execution design/review inclusion"
assert_match "$PACKS_PIPELINES_BODY" "task verification or final acceptance" "packs and pipelines spec should record verification/final acceptance inclusion"
assert_match "$PACKS_PIPELINES_BODY" "api, cli, backend-only behavior" "packs and pipelines spec should record non-default API/CLI/backend cases"
assert_match "$PACKS_PIPELINES_BODY" "tester ui review references" "packs and pipelines spec should distinguish tester UI QA references"
assert_match "$PACKS_PIPELINES_BODY" "do not replace \`interaction-design\` capability signoff" "packs and pipelines spec should keep tester QA distinct from interaction-design"

pass
