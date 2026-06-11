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
  cp -R "$FIXTURES/clean-wo" "$BASE/wo-1"
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/wo-1/bf.md"
  sed -i.bak 's/^- \[ \] AC-1/- [x] AC-1/' "$BASE/wo-1/bf.md"
  for t in task-a task-b; do
    sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/wo-1/$t/spec.md"
  done
  rm -f "$BASE/wo-1"/*.bak "$BASE/wo-1"/*/*.bak
}

cleanup() { rm -rf "$REPO" "$BASE"; }

write_verify_result() {
  local mode="$1" scope="$2" result="${3:-SUCCESS}"
  local dir="$BASE/wo-1/runs/reviews/round_1"
  mkdir -p "$dir"
  cat > "$dir/verify-result.md" <<EOF
---
Result: $result
Mode: $mode
Scope: $scope
Round: 1
Timestamp: 2026-06-11 10:00
---
EOF
  touch -d "2026-06-11 10:00:30" "$dir/verify-result.md"
}

write_success_verify() {
  write_verify_result "Final Acceptance" "wo-1" "SUCCESS"
  cat >> "$BASE/wo-1/runs/reviews/round_1/verify-result.md" <<'EOF'
## AC Sign-off
- AC-1: signed (by tester)

## Flipped
- AC-1
EOF
  touch -d "2026-06-11 10:00:00" "$BASE/wo-1/bf.md"
  touch -d "2026-06-11 10:00:00" "$BASE/wo-1/task-a/spec.md"
  touch -d "2026-06-11 10:00:00" "$BASE/wo-1/task-b/spec.md"
  touch -d "2026-06-11 10:00:30" "$BASE/wo-1/runs/reviews/round_1/verify-result.md"
}

run_complete_json() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-complete.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdComplete({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO', now: new Date('2026-06-11T10:30:00Z'),
      })));
    });
  ")
}

run_complete_cli() {
  export BF_HOME="$BASE"
  export BF_INSTALL_DIR="$REPO"
  run_bfh complete "wo-1"
  unset BF_HOME BF_INSTALL_DIR
}

# non-Implementing bf state blocks complete
setup
sed -i.bak 's/^State: Implementing/State: Accepted/' "$BASE/wo-1/bf.md"
write_success_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "State: Implementing" "non-Implementing bf rejected"
cleanup

# unchecked bf AC blocks complete
setup
sed -i.bak 's/^- \[x\] AC-1/- [ ] AC-1/' "$BASE/wo-1/bf.md"
write_success_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "unchecked AC" "unchecked bf AC rejected"
cleanup

# incomplete task blocks complete
setup
sed -i.bak 's/^State: Completed/State: Tasking/' "$BASE/wo-1/task-b/spec.md"
write_success_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "not all tasks completed" "incomplete task rejected"
cleanup

# missing verify blocks complete
setup
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Final Acceptance SUCCESS" "missing final verify rejected"
cleanup

# bf.md changed after final verify blocks complete
setup
write_success_verify
touch -d "2026-06-11 10:01:00" "$BASE/wo-1/bf.md"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "changed after latest Final Acceptance SUCCESS" "stale final verify rejected"
cleanup

# task spec changed after final verify blocks complete
setup
write_success_verify
touch -d "2026-06-11 10:01:00" "$BASE/wo-1/task-a/spec.md"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "changed after latest Final Acceptance SUCCESS" "stale task spec rejected"
cleanup

# wrong verify mode blocks complete
setup
write_verify_result "Task Verification" "wo-1" "SUCCESS"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Final Acceptance SUCCESS" "wrong final verify mode rejected"
cleanup

# wrong verify scope blocks complete
setup
write_verify_result "Final Acceptance" "other-wo" "SUCCESS"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Final Acceptance SUCCESS" "wrong final verify scope rejected"
cleanup

# failed latest final verify blocks complete
setup
write_verify_result "Final Acceptance" "wo-1" "FAIL"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Final Acceptance SUCCESS" "failed final verify rejected"
cleanup

# successful final complete moves bf.md to Completed
setup
write_success_verify
run_complete_cli
assert_eq "$RC" "0" "complete wo CLI exit"
assert_match "$STDOUT" "SUCCESS" "complete wo success"
assert_match "$STDOUT" "bf.md: Implementing -> Completed" "complete wo transition"
grep -q "^State: Completed" "$BASE/wo-1/bf.md" || fail "bf.md not Completed"
cleanup

pass
