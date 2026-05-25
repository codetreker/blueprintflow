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
          baseHome: '$BASE', woId: 'wo-1', taskId: '$task_arg', installDir: '$REPO',
        })));
      });
    ")
  else
    STDOUT=$(node --input-type=module -e "
      import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
        process.stdout.write(JSON.stringify(await m.cmdVerify({
          baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
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

# CLI-level: phase-mismatch (a setup failure) routes to stderr with the
# `bf-harness verify:` prefix and exits 1 (command-level failure — exit 2 is
# reserved for CLI argument errors per the acceptance criteria). Stdout
# stays empty so the FAIL prefix on stdout always means "verification ran
# and produced a FAIL result", never "the command couldn't start".
setup
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh verify "wo-1/task-a"
assert_eq "$RC" "1" "verify setup failure exit 1"
assert_eq "$STDOUT" "" "verify setup failure stdout empty"
assert_match "$STDERR" "bf-harness verify:" "verify setup failure stderr prefix"
assert_match "$STDERR" "phase mismatch" "verify setup failure stderr body"
unset BF_HOME BF_INSTALL_DIR
cleanup

pass
