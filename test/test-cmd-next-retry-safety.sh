#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

make_git_repo_with_origin() {
  ROOT=$(make_temp_home)
  ORIGIN="$ROOT/origin.git"
  SEED="$ROOT/seed"
  PRIMARY="$ROOT/primary"

  git init --bare "$ORIGIN" >/dev/null 2>&1 || fail "git init --bare failed"
  git -C "$ORIGIN" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1 || fail "set bare HEAD failed"
  git init -b main "$SEED" >/dev/null 2>&1 || fail "git init seed failed"
  git -C "$SEED" config user.email "bf-test@example.com"
  git -C "$SEED" config user.name "BF Test"
  printf "root\n" > "$SEED/README.md"
  git -C "$SEED" add README.md >/dev/null 2>&1
  git -C "$SEED" commit -m init >/dev/null 2>&1 || fail "seed commit failed"
  git -C "$SEED" remote add origin "$ORIGIN" >/dev/null 2>&1
  git -C "$SEED" push -u origin main >/dev/null 2>&1 || fail "seed push failed"
  git clone "$ORIGIN" "$PRIMARY" >/dev/null 2>&1 || fail "git clone failed"
  git -C "$PRIMARY" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main >/dev/null 2>&1 || fail "set origin/HEAD failed"

  BASE="$PRIMARY/.bf"
  EXPECTED_BRANCH="bf/wo-1/task-a"
  EXPECTED_WORKTREE="$PRIMARY/.worktrees/wo-1/task-a"
}

prepare_ready_wo() {
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: true/' "$BASE/works/wo-1/task-a/spec.md"
}

write_task_metadata() {
  local branch="$1" worktree="$2"
  node -e "
    const fs=require('fs');
    const p=process.argv[1];
    let s=fs.readFileSync(p,'utf8');
    s=s.replace(/^Branch:.*$/m, 'Branch: ' + process.argv[2]);
    s=s.replace(/^Worktree:.*$/m, 'Worktree: ' + process.argv[3]);
    fs.writeFileSync(p, s);
  " "$BASE/works/wo-1/task-a/spec.md" "$branch" "$worktree"
}

cmd_next_json() {
  local cwd="$1"
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdNext({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO_ROOT', cwd: '$cwd',
      })));
    });
  "
}

cmd_next_to_file() {
  local cwd="$1" out="$2"
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdNext({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO_ROOT', cwd: '$cwd',
      })));
    });
  " > "$out"
}

precreate_expected_worktree() {
  git -C "$PRIMARY" fetch origin >/dev/null 2>&1 || fail "fetch origin failed"
  git -C "$PRIMARY" branch "$EXPECTED_BRANCH" refs/remotes/origin/HEAD >/dev/null 2>&1 || fail "create expected branch failed"
  mkdir -p "$(dirname "$EXPECTED_WORKTREE")"
  git -C "$PRIMARY" worktree add "$EXPECTED_WORKTREE" "$EXPECTED_BRANCH" >/dev/null 2>&1 || fail "create expected worktree failed"
}

assert_task_a_unmutated() {
  grep -q "^State: Ready" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: task-a state mutated"
  grep -q "^State: Accepted" "$BASE/works/wo-1/bf.md" || fail "$1: bf state mutated"
}

assert_expected_metadata() {
  grep -q "^Branch: $EXPECTED_BRANCH" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: Branch metadata mismatch"
  grep -q "^Worktree: $EXPECTED_WORKTREE" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: Worktree metadata mismatch"
}

# Matching existing branch/worktree plus matching task metadata is recoverable:
# next claims the task instead of failing on pre-existing setup.
make_git_repo_with_origin
prepare_ready_wo
precreate_expected_worktree
write_task_metadata "$EXPECTED_BRANCH" "$EXPECTED_WORKTREE"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .task.taskId task-a
assert_json_field "$STDOUT" .task.branch "$EXPECTED_BRANCH"
assert_json_field "$STDOUT" .task.worktree "$EXPECTED_WORKTREE"
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "recovery did not claim task"
assert_expected_metadata "recovery"
rm -rf "$ROOT"

# Existing branch without the expected matching worktree is a conflict and must
# fail before contract mutation.
make_git_repo_with_origin
prepare_ready_wo
git -C "$PRIMARY" fetch origin >/dev/null 2>&1 || fail "fetch origin failed"
git -C "$PRIMARY" branch "$EXPECTED_BRANCH" refs/remotes/origin/HEAD >/dev/null 2>&1 || fail "create conflicting branch failed"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "branch" "branch conflict message"
assert_task_a_unmutated "branch conflict"
rm -rf "$ROOT"

# Existing filesystem at the expected worktree path is a conflict.
make_git_repo_with_origin
prepare_ready_wo
mkdir -p "$EXPECTED_WORKTREE"
printf "not a git worktree\n" > "$EXPECTED_WORKTREE/README.txt"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "worktree" "filesystem worktree conflict message"
assert_task_a_unmutated "filesystem conflict"
rm -rf "$ROOT"

# Existing Git repository at the expected worktree path belongs to the wrong
# repository and must fail before contract mutation.
make_git_repo_with_origin
prepare_ready_wo
mkdir -p "$EXPECTED_WORKTREE"
git init -b other "$EXPECTED_WORKTREE" >/dev/null 2>&1 || fail "init wrong repository failed"
git -C "$EXPECTED_WORKTREE" config user.email "bf-test@example.com"
git -C "$EXPECTED_WORKTREE" config user.name "BF Test"
printf "other\n" > "$EXPECTED_WORKTREE/README.md"
git -C "$EXPECTED_WORKTREE" add README.md >/dev/null 2>&1
git -C "$EXPECTED_WORKTREE" commit -m other >/dev/null 2>&1 || fail "wrong repository commit failed"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "repository" "wrong repository conflict message"
assert_task_a_unmutated "wrong repository conflict"
rm -rf "$ROOT"

# Existing worktree path checked out on the wrong branch is a conflict.
make_git_repo_with_origin
prepare_ready_wo
git -C "$PRIMARY" fetch origin >/dev/null 2>&1 || fail "fetch origin failed"
git -C "$PRIMARY" worktree add -b wrong-branch "$EXPECTED_WORKTREE" refs/remotes/origin/HEAD >/dev/null 2>&1 || fail "create wrong branch worktree failed"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "checkout branch" "checkout branch conflict message"
assert_task_a_unmutated "checkout conflict"
rm -rf "$ROOT"

# Existing task metadata must not be overwritten when it points elsewhere.
make_git_repo_with_origin
prepare_ready_wo
write_task_metadata "bf/other/task" "$PRIMARY/.worktrees/other/task"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "metadata" "metadata conflict message"
assert_task_a_unmutated "metadata conflict"
grep -q "^Branch: bf/other/task" "$BASE/works/wo-1/task-a/spec.md" || fail "metadata conflict overwrote Branch"
rm -rf "$ROOT"

# A worktree-required Tasking task without matching metadata is not a valid
# retry state.
make_git_repo_with_origin
prepare_ready_wo
sed -i.bak 's/^State: Ready/State: Tasking/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Accepted/State: Implementing/' "$BASE/works/wo-1/bf.md"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "metadata" "Tasking without metadata failure message"
rm -rf "$ROOT"

# Repeated next calls return the same execution metadata and do not create a
# second branch or conflicting worktree.
make_git_repo_with_origin
prepare_ready_wo
FIRST=$(cmd_next_json "$PRIMARY")
assert_json_field "$FIRST" .ok true
SECOND=$(cmd_next_json "$PRIMARY")
assert_json_field "$SECOND" .ok true
assert_json_field "$SECOND" .task.branch "$EXPECTED_BRANCH"
assert_json_field "$SECOND" .task.worktree "$EXPECTED_WORKTREE"
assert_expected_metadata "repeated next"
COUNT=$(git -C "$PRIMARY" worktree list --porcelain | grep -c "^worktree $EXPECTED_WORKTREE$" || true)
assert_eq "$COUNT" "1" "repeated next worktree count"
rm -rf "$ROOT"

# Concurrent calls must not produce conflicting execution metadata.
make_git_repo_with_origin
prepare_ready_wo
OUT1="$ROOT/out1.json"
OUT2="$ROOT/out2.json"
cmd_next_to_file "$PRIMARY" "$OUT1" &
PID1=$!
cmd_next_to_file "$PRIMARY" "$OUT2" &
PID2=$!
wait "$PID1" || true
wait "$PID2" || true
assert_expected_metadata "concurrent next"
COUNT=$(git -C "$PRIMARY" worktree list --porcelain | grep -c "^worktree $EXPECTED_WORKTREE$" || true)
assert_eq "$COUNT" "1" "concurrent next worktree count"
rm -rf "$ROOT"

pass
