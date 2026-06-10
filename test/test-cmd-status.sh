#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

snapshot_files() {
  find "$BASE/works/wo-1" -type f | sort | xargs sha256sum
}

prepare_wo() {
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  find "$BASE/works/wo-1" -name '*.bak' -delete
}

BASE=$(make_temp_home)
prepare_wo
sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
find "$BASE/works/wo-1" -name '*.bak' -delete
BEFORE=$(snapshot_files)
export BF_HOME="$BASE"
run_bfh status wo-1
assert_eq "$RC" "0" "status mixed task states exit"
assert_match "$STDOUT" "BF: wo-1" "status prints bf id"
assert_match "$STDOUT" "State: Implementing" "status prints bf state"
assert_match "$STDOUT" "Tasks: total=2 Draft=0 Ready=1 Tasking=0 Completed=1" "status prints task counts"
assert_match "$STDOUT" "Task: task-a State: Completed" "status prints completed task"
assert_match "$STDOUT" "Task: task-b State: Ready" "status prints ready task"
assert_not_match "$STDOUT" "Next:" "status does not give scheduling advice"
assert_not_match "$STDOUT" "Final-Acceptance:" "status does not give final acceptance advice"
AFTER=$(snapshot_files)
assert_eq "$AFTER" "$BEFORE" "status is read-only"
unset BF_HOME
rm -rf "$BASE"

BASE=$(make_temp_home)
prepare_wo
sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/task-b/spec.md"
find "$BASE/works/wo-1" -name '*.bak' -delete
export BF_HOME="$BASE"
run_bfh status wo-1
assert_eq "$RC" "0" "status all completed exit"
assert_match "$STDOUT" "Tasks: total=2 Draft=0 Ready=0 Tasking=0 Completed=2" "status prints all completed counts"
assert_match "$STDOUT" "Task: task-a State: Completed" "status prints task-a completed"
assert_match "$STDOUT" "Task: task-b State: Completed" "status prints task-b completed"
unset BF_HOME
rm -rf "$BASE"

BASE=$(make_temp_home)
export BF_HOME="$BASE"
run_bfh status missing-wo
assert_eq "$RC" "1" "status missing wo exits 1"
assert_match "$STDOUT" "load failed" "status missing wo reports load failure"
unset BF_HOME
rm -rf "$BASE"

pass
