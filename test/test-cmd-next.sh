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

add_ready_task_like_a() {
  local task_id="$1"
  cp -R "$BASE/wo-1/task-a" "$BASE/wo-1/$task_id"
  sed -i.bak "s/^Desc: task A/Desc: $task_id/" "$BASE/wo-1/$task_id/spec.md"
}

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
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId "task-a"
assert_json_field "$STDOUT" .tasks.0.pipeline "feature"
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
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId "task-a"

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
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId "task-b"
grep -q "^State: Tasking" "$BASE/wo-1/task-b/spec.md" || fail "task-b not Tasking"

cleanup

# Batch next returns all eligible tasks in bf.md task-list order and claims
# every Ready task in the returned batch.
setup_accepted
sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/wo-1/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 2
assert_json_field "$STDOUT" .tasks.0.taskId "task-a"
assert_json_field "$STDOUT" .tasks.1.taskId "task-b"
grep -q "^State: Tasking" "$BASE/wo-1/task-a/spec.md" || fail "batch did not claim task-a"
grep -q "^State: Tasking" "$BASE/wo-1/task-b/spec.md" || fail "batch did not claim task-b"
cleanup

# Batch next returns at most five independent tasks and leaves later Ready tasks
# unclaimed for a future coordinator loop.
setup_accepted
for id in task-c task-d task-e task-f; do
  add_ready_task_like_a "$id"
done
perl -0pi -e 's/## Task List\n\n[\s\S]*$/## Task List\n\n- task-a\n- task-b\n- task-c\n- task-d\n- task-e\n- task-f\n/s' "$BASE/wo-1/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 5
assert_json_field "$STDOUT" .tasks.0.taskId "task-a"
assert_json_field "$STDOUT" .tasks.1.taskId "task-b"
assert_json_field "$STDOUT" .tasks.2.taskId "task-c"
assert_json_field "$STDOUT" .tasks.3.taskId "task-d"
assert_json_field "$STDOUT" .tasks.4.taskId "task-e"
grep -q "^State: Tasking" "$BASE/wo-1/task-e/spec.md" || fail "batch did not claim fifth task"
grep -q "^State: Ready" "$BASE/wo-1/task-f/spec.md" || fail "batch claimed more than five tasks"
cleanup

# Already Tasking tasks are all returned for resume, even when there are more
# than the Ready-claim batch size. Ready task claiming remains capped separately.
setup_accepted
for id in task-c task-d task-e task-f task-g; do
  add_ready_task_like_a "$id"
done
perl -0pi -e 's/## Task List\n\n[\s\S]*$/## Task List\n\n- task-a\n- task-b\n- task-c\n- task-d\n- task-e\n- task-f\n- task-g\n/s' "$BASE/wo-1/bf.md"
for id in task-a task-b task-c task-d task-e task-f; do
  sed -i.bak 's/^State: Ready/State: Tasking/' "$BASE/wo-1/$id/spec.md"
done
sed -i.bak 's/^State: Accepted/State: Implementing/' "$BASE/wo-1/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 7
assert_json_field "$STDOUT" .tasks.0.taskId "task-a"
assert_json_field "$STDOUT" .tasks.1.taskId "task-b"
assert_json_field "$STDOUT" .tasks.2.taskId "task-c"
assert_json_field "$STDOUT" .tasks.3.taskId "task-d"
assert_json_field "$STDOUT" .tasks.4.taskId "task-e"
assert_json_field "$STDOUT" .tasks.5.taskId "task-f"
assert_json_field "$STDOUT" .tasks.6.taskId "task-g"
grep -q "^State: Tasking" "$BASE/wo-1/task-g/spec.md" || fail "Ready task after Tasking resume set was not claimed"
cleanup

# Already Tasking tasks stay eligible, and their presence must not suppress
# independent Ready tasks from the same batch.
setup_accepted
sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/wo-1/bf.md"
sed -i.bak 's/^State: Ready/State: Tasking/' "$BASE/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Accepted/State: Implementing/' "$BASE/wo-1/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 2
assert_json_field "$STDOUT" .tasks.0.taskId "task-a"
assert_json_field "$STDOUT" .tasks.1.taskId "task-b"
grep -q "^State: Tasking" "$BASE/wo-1/task-b/spec.md" || fail "Tasking task suppressed Ready task-b"
cleanup

# If an independent Ready task cannot be claimed because its pipeline is invalid,
# existing Tasking tasks are still returned for coordinator resume.
setup_accepted
sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/wo-1/bf.md"
sed -i.bak 's/^State: Ready/State: Tasking/' "$BASE/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Accepted/State: Implementing/' "$BASE/wo-1/bf.md"
sed -i.bak 's/^Pipeline: feature/Pipeline: missing-pipeline/' "$BASE/wo-1/task-b/spec.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId "task-a"
grep -q "^State: Ready" "$BASE/wo-1/task-b/spec.md" || fail "invalid Ready pipeline task was claimed"
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

# Local pipeline path wins when task references a bf-wo local pipeline id.
setup_accepted
sed -i.bak 's/^Pipeline: feature/Pipeline: api-migration/' "$BASE/wo-1/task-a/spec.md"
write_local_pipeline "$BASE/wo-1/pipelines/api-migration.yml" "api-migration"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.0.pipeline "api-migration"
assert_match "$STDOUT" "$BASE/wo-1/pipelines/api-migration.yml" "local pipeline path returned"
assert_not_match "$STDOUT" "packs/engineering/pipelines/feature.yml" "pack pipeline path should not be used"
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
assert_not_match "$STDOUT" "\"ok\"" "next CLI output must remain text"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in next stdout"
unset BF_HOME BF_INSTALL_DIR
cleanup

# CLI-level batch output prints one block per returned task, separated by a line
# exactly `---`.
setup_accepted
sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/wo-1/bf.md"
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh next "wo-1"
assert_eq "$RC" "0" "batch next wo-1 exit 0"
task_count=$(printf "%s\n" "$STDOUT" | grep -c "^Task:")
assert_eq "$task_count" "2" "batch next stdout has two task blocks"
sep_count=$(printf "%s\n" "$STDOUT" | grep -cx -- "---" || true)
assert_eq "$sep_count" "1" "batch next stdout has one separator"
case "$STDOUT" in
  *"Task: task-a"*"---"*"Task: task-b"*) ;;
  *) fail "batch next stdout does not preserve task-list order: $STDOUT" ;;
esac
assert_not_match "$STDOUT" "\"tasks\"" "batch next CLI output must remain text"
unset BF_HOME BF_INSTALL_DIR
cleanup

# CLI-level mixed batch output includes already-Tasking tasks and independent
# Ready tasks, leaving the coordinator to resume or start drivers.
setup_accepted
sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/wo-1/bf.md"
sed -i.bak 's/^State: Ready/State: Tasking/' "$BASE/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Accepted/State: Implementing/' "$BASE/wo-1/bf.md"
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh next "wo-1"
assert_eq "$RC" "0" "mixed batch next wo-1 exit 0"
task_count=$(printf "%s\n" "$STDOUT" | grep -c "^Task:")
assert_eq "$task_count" "2" "mixed batch next stdout has two task blocks"
sep_count=$(printf "%s\n" "$STDOUT" | grep -cx -- "---" || true)
assert_eq "$sep_count" "1" "mixed batch next stdout has one separator"
case "$STDOUT" in
  *"Task: task-a"*"---"*"Task: task-b"*) ;;
  *) fail "mixed batch next stdout does not preserve task-list order: $STDOUT" ;;
esac
assert_not_match "$STDOUT" "\"tasks\"" "mixed batch next CLI output must remain text"
unset BF_HOME BF_INSTALL_DIR
cleanup

pass
