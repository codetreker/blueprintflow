#!/usr/bin/env bash
# Regression for audit #3: the Final-Acceptance staleness gate must fail CLOSED
# when a Completed task's `Updated` is missing or unparseable. Today an empty set
# of parseable completion timestamps leaves latestCompletedMs at -Infinity and
# the gate returns "fresh" (fail-open). After the fix, an unparseable/missing
# `Updated` on a Completed task is a stale/invalid error and verify FAILs.
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
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
  for t in task-a task-b; do
    sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/$t/spec.md"
  done
  rm -f "$BASE/works/wo-1"/*.bak "$BASE/works/wo-1"/*/*.bak
  ROUND_DIR="$BASE/works/wo-1/runs/reviews/round_1"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

write_signed_review() {
  local dir="$1"
  mkdir -p "$dir"
  {
    echo "# Desc"; echo
    echo "## Results"; echo
    echo "### Blocker"; echo "### High"; echo "### Minor"; echo "### Nit"; echo
    echo "## Accepted Criteria"; echo
    echo "- AC-1: signed by tester"
  } > "$dir/result_tester_1.md"
}

run_verify_c() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
      })));
    });
  ")
}

# --- Case 1: every Completed task's `Updated` is UNPARSEABLE -> fail CLOSED. ---
setup
sed -i.bak 's/^Updated: .*/Updated: not-a-real-timestamp/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^Updated: .*/Updated: also-bogus/' "$BASE/works/wo-1/task-b/spec.md"
rm -f "$BASE/works/wo-1"/*/*.bak
write_signed_review "$ROUND_DIR"
# Make the round file appear "fresh" by mtime so only the Updated parse can fail it.
touch -d "2026-05-19 11:00" "$ROUND_DIR/result_tester_1.md"
run_verify_c
assert_json_field "$STDOUT" .status "FAIL"
grep -qE "^- \[x\] AC-1\|" "$BASE/works/wo-1/bf.md" && fail "bf.md AC-1 must not flip on a fail-closed staleness error"
grep -q "^State: Implementing" "$BASE/works/wo-1/bf.md" || fail "bf.md state must remain Implementing on FAIL"
cleanup

# --- Case 2: a Completed task with a MISSING `Updated` value -> fail CLOSED. ---
setup
sed -i.bak 's/^Updated: .*/Updated:/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^Updated: .*/Updated: 2026-05-19 10:00/' "$BASE/works/wo-1/task-b/spec.md"
rm -f "$BASE/works/wo-1"/*/*.bak
write_signed_review "$ROUND_DIR"
touch -d "2026-05-19 11:00" "$ROUND_DIR/result_tester_1.md"
run_verify_c
assert_json_field "$STDOUT" .status "FAIL"
grep -qE "^- \[x\] AC-1\|" "$BASE/works/wo-1/bf.md" && fail "bf.md AC-1 must not flip when a Completed task lacks Updated"
cleanup

# --- Case 3 (regression guard): all `Updated` parseable + round fresh -> SUCCESS. ---
setup
sed -i.bak 's/^Updated: .*/Updated: 2026-05-19 10:00/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^Updated: .*/Updated: 2026-05-19 10:00/' "$BASE/works/wo-1/task-b/spec.md"
rm -f "$BASE/works/wo-1"/*/*.bak
write_signed_review "$ROUND_DIR"
touch -d "2026-05-19 11:00" "$ROUND_DIR/result_tester_1.md"
run_verify_c
assert_json_field "$STDOUT" .status "SUCCESS"
grep -qE "^- \[x\] AC-1\|" "$BASE/works/wo-1/bf.md" || fail "valid parseable timestamps + fresh round must still flip AC-1"
cleanup

pass
