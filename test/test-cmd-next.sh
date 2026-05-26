#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup_accepted() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
  cp -R "$FIXTURES/clean-wo" "$BASE/wo-1"
  sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/wo-1/task-b/spec.md"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

# First next: claim task-a; bf -> Implementing
setup_accepted
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .task.taskId "task-a"
assert_json_field "$STDOUT" .task.pipeline "feature"
assert_match "$STDOUT" "packs/engineering/pipelines/feature.yml" "pipeline path present"
grep -q "^State: Tasking" "$BASE/wo-1/task-a/spec.md" || fail "task-a not Tasking"
grep -q "^State: Implementing" "$BASE/wo-1/bf.md" || fail "bf not Implementing"

# Second next: task-a still Tasking, task-b blocked by deps -> return task-a, no state change
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .task.taskId "task-a"

# Dep unlock: task-a -> Completed, next returns task-b and flips to Tasking
sed -i.bak 's/^State: Tasking/State: Completed/' "$BASE/wo-1/task-a/spec.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .task.taskId "task-b"
grep -q "^State: Tasking" "$BASE/wo-1/task-b/spec.md" || fail "task-b not Tasking"

cleanup

# Wrong bf state -> reject
setup_accepted
sed -i.bak 's/^State: Accepted/State: Draft/' "$BASE/wo-1/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "wrong state" "draft rejected"
cleanup

# All completed -> no eligible
setup_accepted
sed -i.bak 's/^State: Ready/State: Completed/' "$BASE/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Ready/State: Completed/' "$BASE/wo-1/task-b/spec.md"
sed -i.bak 's/^State: Accepted/State: Implementing/' "$BASE/wo-1/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "no eligible task" "all completed"
cleanup

# CLI-level OUT-3: bf-harness next prints one labeled line per field, exactly
# one `^Task:`, `^Pipeline:`, `^Pipeline path:`, `^Pack:`, `^Spec:`,
# `^Dir:`. No trailing whitespace.
setup_accepted
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh next "wo-1"
assert_eq "$RC" "0" "next wo-1 exit 0"
for label in "Task:" "Pipeline:" "Pipeline path:" "Pack:" "Spec:" "Dir:"; do
  count=$(printf "%s\n" "$STDOUT" | grep -c "^${label}")
  assert_eq "$count" "1" "next stdout has exactly one '^${label}' line"
done
assert_match "$STDOUT" "Task: task-a" "Task line value"
assert_match "$STDOUT" "Pipeline: feature" "Pipeline line value"
assert_match "$STDOUT" "Pack: engineering" "Pack line value"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in next stdout"
unset BF_HOME BF_INSTALL_DIR
cleanup

pass
