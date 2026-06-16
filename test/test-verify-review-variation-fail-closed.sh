#!/usr/bin/env bash
# Regression for audit #1 at the verify gate: a review round whose blocking
# finding uses an ordinary heading variation must make `bf-harness verify` FAIL
# and flip NO acceptance-criteria checkbox; and an unrecognized/unparseable
# Results section must make verify fail CLOSED (acceptedIds not honored).
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
  copy_fixture clean-wo "$BASE/works/wo-1"
  # bf Implementing; task-a Tasking so Task Verification (mode B) applies.
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Tasking/' "$BASE/works/wo-1/task-a/spec.md"
  rm -f "$BASE/works/wo-1"/*.bak "$BASE/works/wo-1"/*/*.bak
  ROUND_DIR="$BASE/works/wo-1/task-a/runs/reviews/round_1"
  mkdir -p "$ROUND_DIR"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

run_verify_b() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', woId: 'wo-1', taskId: 'task-a', installDir: '$REPO',
      })));
    });
  ")
}

# --- Case 1: blocker under plural '### Blockers' + signs AC-1 -> verify FAIL,
#     AC-1 stays unchecked. ---
setup
cat > "$ROUND_DIR/result_tester_1.md" <<'EOF'
# Desc

## Results

### Blockers

- the implementation is fundamentally broken

## Accepted Criteria

- AC-1: signed despite the blocker
EOF
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
grep -qE "^- \[ \] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "AC-1 must stay unchecked when a variant-heading blocker is present"
grep -qE "^- \[x\] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" && fail "AC-1 must not flip on a variant-heading blocker"
cleanup

# --- Case 2: no recognizable Results section but signs AC-1 -> fail CLOSED.
#     verify must not run to SUCCESS and must not flip AC-1. ---
setup
cat > "$ROUND_DIR/result_tester_1.md" <<'EOF'
# Desc

review with no Results wrapper at all

## Accepted Criteria

- AC-1: signed despite missing Results
EOF
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
grep -qE "^- \[x\] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" && fail "unparseable Results must not flip AC-1"
grep -qE "^- \[ \] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "AC-1 must stay unchecked on fail-closed Results parse"
cleanup

pass
