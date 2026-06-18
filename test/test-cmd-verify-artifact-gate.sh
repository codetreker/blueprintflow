#!/usr/bin/env bash
# Task Verification artifact-presence gate (fail-closed).
# Asserts mode-B verify FAILs (naming the artifact) when a declared `output:`
# stage artifact is missing or whitespace-only, PASSes when all are present and
# non-empty, and does not gate stages that declare no `output:`.
set -u
source "$(dirname "$0")/test-helpers.sh"

# Build an isolated wo whose task-a uses a local pipeline that declares one
# `output:` stage (gated) plus one stage with no `output:` (not gated).
setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Tasking/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  # Point task-a at a local pipeline that declares a gated output: stage.
  sed -i.bak 's/^Pipeline: feature/Pipeline: gated-pipe/' "$BASE/works/wo-1/task-a/spec.md"
  mkdir -p "$BASE/works/wo-1/pipelines"
  cat > "$BASE/works/wo-1/pipelines/gated-pipe.yml" <<'EOF'
id: gated-pipe
desc: Local pipeline with one gated output stage and one ungated stage
instruction: |
  Follow this local pipeline for the task.
stages:
  - id: implementation
    capability: software-implementation
    instruction: |
      Implement the task; this stage declares no output: and is not gated.
  - id: validation
    capability: software-implementation
    output: artifacts/validation.md
    instruction: |
      Produce the validation artifact.
EOF
  rm -f "$BASE/works/wo-1"/*.bak "$BASE/works/wo-1"/*/*.bak
}
cleanup() { rm -rf "$REPO" "$BASE"; }

write_signed_review() {
  local dir="$1" role="$2" idx="$3" ac_ids="$4"
  mkdir -p "$dir"
  {
    echo "# Desc"; echo
    echo "## Results"; echo
    echo "### Blocker"; echo "### High"; echo "### Minor"; echo "### Nit"; echo
    echo "## Accepted Criteria"; echo
    for id in $ac_ids; do echo "- $id: signed by $role"; done
  } > "$dir/result_${role}_${idx}.md"
}

run_verify_b() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', woId: 'wo-1', taskId: 'task-a', installDir: '$REPO',
      })));
    });
  ")
}

ART="artifacts/validation.md"

# Case 1: FAIL — declared output: artifact is MISSING. Verify FAILs, result names it,
# and the spec is NOT mutated (no AC flip, state stays Tasking).
setup
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1" tester 1 "AC-1"
# do not create artifacts/validation.md
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$BASE/works/wo-1/task-a/runs/reviews/round_1/verify-result.md"
grep -q "missing artifact" "$RESULT_FILE" || fail "missing artifact not reported"
grep -q "$ART" "$RESULT_FILE" || fail "FAIL result must name the offending artifact"
grep -qE "^- \[ \] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "AC-1 must not flip on artifact-gate FAIL"
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "task-a state changed on artifact-gate FAIL"
cleanup

# Case 2: FAIL — declared output: artifact is WHITESPACE-ONLY. Verify FAILs and names it.
setup
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1" tester 1 "AC-1"
mkdir -p "$BASE/works/wo-1/task-a/artifacts"
printf '   \n\t\n' > "$BASE/works/wo-1/task-a/$ART"
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$BASE/works/wo-1/task-a/runs/reviews/round_1/verify-result.md"
grep -q "empty artifact" "$RESULT_FILE" || fail "empty artifact not reported"
grep -q "$ART" "$RESULT_FILE" || fail "FAIL result must name the empty artifact"
grep -qE "^- \[ \] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "AC-1 must not flip on empty-artifact FAIL"
cleanup

# Case 3: PASS — declared output: artifact present + non-empty. Gate does not block;
# AC sign-off proceeds (AC-1 flips). The ungated stage (no output:) is not checked.
setup
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1" tester 1 "AC-1"
mkdir -p "$BASE/works/wo-1/task-a/artifacts"
printf 'validation evidence: full suite green\n' > "$BASE/works/wo-1/task-a/$ART"
run_verify_b
assert_json_field "$STDOUT" .status "SUCCESS"
assert_json_field "$STDOUT" .mode "Task Verification"
grep -qE "^- \[x\] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "artifact gate blocked the PASS path (AC-1 not flipped)"
RESULT_FILE="$BASE/works/wo-1/task-a/runs/reviews/round_1/verify-result.md"
assert_not_match "$(cat "$RESULT_FILE")" "missing artifact" "PASS path must not report missing artifact"
assert_not_match "$(cat "$RESULT_FILE")" "empty artifact" "PASS path must not report empty artifact"
# The ungated `implementation` stage has no output: dir; its absence must not FAIL.
[ ! -e "$BASE/works/wo-1/task-a/artifacts/implementation.md" ] || fail "fixture sanity"
cleanup

# Case 4: fail-closed — pipeline cannot be resolved → FAIL (gate not silently skipped).
setup
sed -i.bak 's/^Pipeline: gated-pipe/Pipeline: does-not-exist/' "$BASE/works/wo-1/task-a/spec.md"
rm -f "$BASE/works/wo-1/task-a/spec.md.bak"
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1" tester 1 "AC-1"
mkdir -p "$BASE/works/wo-1/task-a/artifacts"
printf 'validation evidence\n' > "$BASE/works/wo-1/task-a/$ART"
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$BASE/works/wo-1/task-a/runs/reviews/round_1/verify-result.md"
grep -q "pipeline not found" "$RESULT_FILE" || fail "unresolvable pipeline must fail closed"
grep -qE "^- \[ \] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "AC-1 must not flip when pipeline unresolved"
cleanup

pass
