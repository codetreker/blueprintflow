#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

run_validate() {
  STDOUT=$(node --input-type=module -e "
    Promise.all([
      import('$REPO_ROOT/bin/lib/harness/load-wo.mjs'),
      import('$REPO_ROOT/bin/lib/harness/validate-wo.mjs'),
    ]).then(async ([l, v]) => {
      const bundle = await l.loadWo({ baseHome: '$BASE', woId: process.argv[1], installDir: '$REPO' });
      process.stdout.write(JSON.stringify(v.validateWo(bundle)));
    });
  " "$1")
}

setup; cp -R "$FIXTURES/clean-wo" "$BASE/clean-wo"
run_validate clean-wo
assert_json_field "$STDOUT" .ok true
cleanup

setup; cp -R "$FIXTURES/missing-capability-wo" "$BASE/missing-cap-wo"
run_validate missing-cap-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "CAPABILITY_UNKNOWN" "missing cap"
cleanup

# dep cycle: 把 task-a 改成依赖 task-b（task-b 已经依赖 task-a）
setup; cp -R "$FIXTURES/clean-wo" "$BASE/cycle-wo"
sed -i.bak 's/^- task-a$/- task-a: task-b/' "$BASE/cycle-wo/bf.md"
run_validate cycle-wo
assert_match "$STDOUT" "DEP_CYCLE" "cycle detected"
cleanup

# task specs must carry an explicit Evidence section before lint can pass
setup; cp -R "$FIXTURES/clean-wo" "$BASE/missing-evidence-section-wo"
sed -i.bak '/^## Evidence$/,/^## Boundary$/d' "$BASE/missing-evidence-section-wo/task-a/spec.md"
run_validate missing-evidence-section-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_SECTION_MISSING" "missing Evidence section detected"
cleanup

# every task AC needs at least one Evidence entry in the explicit section
setup; cp -R "$FIXTURES/clean-wo" "$BASE/missing-evidence-entry-wo"
sed -i.bak '/^- EV-/d' "$BASE/missing-evidence-entry-wo/task-a/spec.md"
run_validate missing-evidence-entry-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_MISSING" "missing Evidence entry detected"
cleanup

# Evidence must reference an AC in the same task spec
setup; cp -R "$FIXTURES/clean-wo" "$BASE/bad-evidence-ref-wo"
sed -i.bak 's/^- EV-1|AC-1|review-note:/- EV-1|AC-99|review-note:/' "$BASE/bad-evidence-ref-wo/task-a/spec.md"
run_validate bad-evidence-ref-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_AC_UNKNOWN" "unknown evidence AC detected"
cleanup

# Evidence ids are stable handles and must be unique within one task spec
setup; cp -R "$FIXTURES/clean-wo" "$BASE/duplicate-evidence-id-wo"
sed -i.bak '/^## Boundary$/i - EV-1|AC-1|review-note: duplicate id should fail lint' "$BASE/duplicate-evidence-id-wo/task-a/spec.md"
run_validate duplicate-evidence-id-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_DUPLICATE_ID" "duplicate Evidence id detected"
cleanup

# Evidence kind is a linted vocabulary, not arbitrary prose
setup; cp -R "$FIXTURES/clean-wo" "$BASE/unknown-evidence-kind-wo"
sed -i.bak 's/^- EV-1|AC-1|review-note:/- EV-1|AC-1|memo:/' "$BASE/unknown-evidence-kind-wo/task-a/spec.md"
run_validate unknown-evidence-kind-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_KIND_UNKNOWN" "unknown Evidence kind detected"
cleanup

# Evidence text must state the required proof, not just reserve an id
setup; cp -R "$FIXTURES/clean-wo" "$BASE/empty-evidence-text-wo"
sed -i.bak 's#^- EV-1|AC-1|review-note:.*$#- EV-1|AC-1|command:   #' "$BASE/empty-evidence-text-wo/task-a/spec.md"
run_validate empty-evidence-text-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_TEXT_EMPTY" "empty Evidence text detected"
cleanup

pass
