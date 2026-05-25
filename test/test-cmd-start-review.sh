#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

BASE=$(make_temp_home)
mkdir -p "$BASE"
cp -R "$FIXTURES/clean-wo" "$BASE/wo-1"

# wo level round 1
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-start-review.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdStartReview({ baseHome: '$BASE', woId: 'wo-1' })));
  });
")
assert_json_field "$STDOUT" .round "1"
assert_match "$STDOUT" "runs/reviews/round_1" "wo-level round path"
[ -d "$BASE/wo-1/runs/reviews/round_1" ] || fail "round_1 dir not created"

# wo level round 2
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-start-review.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdStartReview({ baseHome: '$BASE', woId: 'wo-1' })));
  });
")
assert_json_field "$STDOUT" .round "2"

# task level round 1
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-start-review.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdStartReview({ baseHome: '$BASE', woId: 'wo-1', taskId: 'task-a' })));
  });
")
assert_json_field "$STDOUT" .round "1"
assert_match "$STDOUT" "task-a/runs/reviews/round_1" "task-level round path"

# scope not found
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-start-review.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdStartReview({ baseHome: '$BASE', woId: 'nope' })));
  });
")
assert_json_field "$STDOUT" .ok false

rm -rf "$BASE"

# CLI-level: bf-harness start-review prints just the absolute round-dir
# path on its own line (no JSON wrapping). No trailing whitespace.
BASE=$(make_temp_home)
mkdir -p "$BASE"
cp -R "$FIXTURES/clean-wo" "$BASE/wo-1"
export BF_HOME="$BASE"
run_bfh start-review "wo-1"
assert_eq "$RC" "0" "start-review exit 0"
LINE_COUNT=$(printf "%s\n" "$STDOUT" | grep -c .)
assert_eq "$LINE_COUNT" "1" "start-review stdout is exactly one non-empty line"
# Output is an absolute path containing the expected suffix.
case "$STDOUT" in
  /*runs/reviews/round_1*) ;;
  *) fail "start-review stdout not an absolute round-dir path: $STDOUT" ;;
esac
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in start-review stdout"
unset BF_HOME
rm -rf "$BASE"

pass
