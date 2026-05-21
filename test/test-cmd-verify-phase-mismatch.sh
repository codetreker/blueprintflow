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
}
cleanup() { rm -rf "$REPO" "$BASE"; }

run_verify() {
  local task_arg="$1"
  if [ -n "$task_arg" ]; then
    STDOUT=$(node --input-type=module -e "
      import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
        process.stdout.write(JSON.stringify(await m.cmdVerify({
          baseHome: '$BASE', woId: 'wo-1', taskId: '$task_arg', repoRoot: '$REPO',
        })));
      });
    ")
  else
    STDOUT=$(node --input-type=module -e "
      import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
        process.stdout.write(JSON.stringify(await m.cmdVerify({
          baseHome: '$BASE', woId: 'wo-1', repoRoot: '$REPO',
        })));
      });
    ")
  fi
}

# Draft + task → mismatch
setup
run_verify "task-a"
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "phase mismatch" "draft+task"
cleanup

# Accepted + no task → mismatch
setup
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/wo-1/bf.md"
run_verify ""
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "phase mismatch" "accepted+nowo"
cleanup

# Completed + 任何 → mismatch
setup
sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/wo-1/bf.md"
run_verify ""
assert_json_field "$STDOUT" .ok false
run_verify "task-a"
assert_json_field "$STDOUT" .ok false
cleanup

pass
