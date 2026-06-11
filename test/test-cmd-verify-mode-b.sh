#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  local fixture="${1:-clean-wo}"
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
  cp -R "$FIXTURES/$fixture" "$BASE/wo-1"
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Tasking/' "$BASE/wo-1/task-a/spec.md"
  [ -f "$BASE/wo-1/task-b/spec.md" ] && sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/wo-1/task-b/spec.md"
  rm -f "$BASE/wo-1"/*.bak "$BASE/wo-1"/*/*.bak
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

write_blocker_review() {
  local dir="$1" role="$2" idx="$3"
  mkdir -p "$dir"
  cat > "$dir/result_${role}_${idx}.md" <<EOF
# Desc

## Results

### Blocker

- task-a/src.mjs:10 something bad

### High
### Minor
### Nit

## Accepted Criteria
EOF
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

# Case 1: SUCCESS - clean-wo, tester signs AC-1 -> flip AC and leave task Tasking
setup clean-wo
write_signed_review "$BASE/wo-1/task-a/runs/reviews/round_1" tester 1 "AC-1"
run_verify_b
assert_json_field "$STDOUT" .status "SUCCESS"
assert_json_field "$STDOUT" .mode "Task Verification"
grep -qE "^- \[x\] AC-1\|" "$BASE/wo-1/task-a/spec.md" || fail "AC-1 not flipped"
grep -q "^State: Tasking" "$BASE/wo-1/task-a/spec.md" || fail "verify should leave task-a Tasking"
grep -q "^State: Implementing" "$BASE/wo-1/bf.md" || fail "bf.md state changed unexpectedly"
RESULT_FILE="$BASE/wo-1/task-a/runs/reviews/round_1/verify-result.md"
grep -q "AC-1: signed" "$RESULT_FILE" || fail "AC sign-off in result"
grep -q "Tasking -> Completed" "$RESULT_FILE" && fail "verify should not record terminal state transition"
cleanup

# Case 2: FAIL on Blocker
setup clean-wo
write_blocker_review "$BASE/wo-1/task-a/runs/reviews/round_1" tester 1
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
grep -qE "^- \[ \] AC-1\|" "$BASE/wo-1/task-a/spec.md" || fail "AC-1 unexpectedly flipped"
grep -q "^State: Tasking" "$BASE/wo-1/task-a/spec.md" || fail "task-a state changed on Blocker"
cleanup

# Case 3: FAIL on missing signoff (no AC signed)
setup clean-wo
write_signed_review "$BASE/wo-1/task-a/runs/reviews/round_1" tester 1 ""
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$BASE/wo-1/task-a/runs/reviews/round_1/verify-result.md"
grep -q "AC-1: missing" "$RESULT_FILE" || fail "AC-1 missing not reported"
grep -qE "^- \[ \] AC-1\|" "$BASE/wo-1/task-a/spec.md" || fail "AC-1 unexpectedly flipped"
cleanup

# Case 4: multi-reviewer-wo + only tester signs → still SUCCESS (OR semantics)
setup multi-reviewer-wo
write_signed_review "$BASE/wo-1/task-a/runs/reviews/round_1" tester 1 "AC-1"
run_verify_b
assert_json_field "$STDOUT" .status "SUCCESS"
grep -qE "^- \[x\] AC-1\|" "$BASE/wo-1/task-a/spec.md" || fail "OR semantics: AC-1 should flip"
RESULT_FILE="$BASE/wo-1/task-a/runs/reviews/round_1/verify-result.md"
grep -q "AC-1: signed" "$RESULT_FILE" || fail "OR semantics: AC-1 should be signed"
cleanup

# Case 5: multi-reviewer-wo + nobody signs → FAIL
setup multi-reviewer-wo
write_signed_review "$BASE/wo-1/task-a/runs/reviews/round_1" tester 1 ""
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
cleanup

# Case 6: phase mismatch — bf.md.State=Draft + task → rejected
setup clean-wo
sed -i.bak 's/^State: Implementing/State: Draft/' "$BASE/wo-1/bf.md"
run_verify_b
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "phase mismatch" "draft+task rejected"
cleanup

pass
