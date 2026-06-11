#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

make_git_repo() {
  ROOT=$(make_temp_home)
  PRIMARY="$ROOT/primary"
  git init -b main "$PRIMARY" >/dev/null 2>&1 || fail "git init failed"
  git -C "$PRIMARY" config user.email "bf-test@example.com"
  git -C "$PRIMARY" config user.name "BF Test"
  printf "root\n" > "$PRIMARY/README.md"
  git -C "$PRIMARY" add README.md >/dev/null 2>&1
  git -C "$PRIMARY" commit -m init >/dev/null 2>&1 || fail "git commit failed"
  git -C "$PRIMARY" remote add origin "https://github.com/example/repo.git" >/dev/null 2>&1
  BASE="$PRIMARY/.bf"
  TASK_BRANCH="bf/wo-1/task-a"
  TASK_WORKTREE="$PRIMARY/.worktrees/works/wo-1/task-a"
}

prepare_implementing_wo() {
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^- \[ \] AC-1/^- [x] AC-1/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: true/' "$BASE/works/wo-1/task-a/spec.md"
  git -C "$PRIMARY" branch "$TASK_BRANCH" HEAD >/dev/null 2>&1 || fail "task branch failed"
  mkdir -p "$(dirname "$TASK_WORKTREE")"
  git -C "$PRIMARY" worktree add "$TASK_WORKTREE" "$TASK_BRANCH" >/dev/null 2>&1 || fail "task worktree failed"
  sed -i.bak "s#^Branch:.*#Branch: $TASK_BRANCH#" "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak "s#^Worktree:.*#Worktree: $TASK_WORKTREE#" "$BASE/works/wo-1/task-a/spec.md"
}

run_cleanup_json() {
  local cwd="$1"
  local task="${2:-task-a}"
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-cleanup.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdCleanup({
        baseHome: '$BASE', woId: 'wo-1', taskId: '$task', installDir: '$REPO_ROOT', cwd: '$cwd',
      })));
    });
  "
}

run_cleanup_cli() {
  local target="${1:-wo-1/task-a}"
  STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" node "$BFH" cleanup "$target" 2>/tmp/bf-cleanup-stderr.$$)
  RC=$?
  STDERR=$(cat /tmp/bf-cleanup-stderr.$$ 2>/dev/null || true)
  rm -f /tmp/bf-cleanup-stderr.$$
}

# Cleanup is task-scoped; work-object scope is not a cleanup target.
make_git_repo
prepare_implementing_wo
run_cleanup_cli wo-1
assert_eq "$RC" "2" "cleanup wo-scope CLI exit"
assert_match "$STDERR" "cleanup requires <bf-wo>/<task>" "cleanup requires task target"
[ -d "$TASK_WORKTREE" ] || fail "wo-scope cleanup removed worktree"
git -C "$PRIMARY" show-ref --verify "refs/heads/$TASK_BRANCH" >/dev/null 2>&1 || fail "wo-scope cleanup removed branch"
rm -rf "$ROOT"

# Cleanup refuses a task before Task Verification completes.
make_git_repo
prepare_implementing_wo
sed -i.bak 's/^State: Completed/State: Tasking/' "$BASE/works/wo-1/task-a/spec.md"
STDOUT=$(run_cleanup_json "$PRIMARY" task-a)
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "task State: Completed" "non-completed task cleanup rejection"
[ -d "$TASK_WORKTREE" ] || fail "cleanup removed worktree before task Completed"
git -C "$PRIMARY" show-ref --verify "refs/heads/$TASK_BRANCH" >/dev/null 2>&1 || fail "cleanup removed branch before task Completed"
rm -rf "$ROOT"

# Cleanup removes the completed task's harness-owned worktree and safely
# deletes the local task branch when Git considers it merged, even while bf.md
# remains Implementing.
make_git_repo
prepare_implementing_wo
run_cleanup_cli
assert_eq "$RC" "0" "cleanup CLI exit"
assert_match "$STDOUT" "Removed worktree: $TASK_WORKTREE" "cleanup worktree stdout"
assert_match "$STDOUT" "Deleted branch: $TASK_BRANCH" "cleanup branch stdout"
[ ! -e "$TASK_WORKTREE" ] || fail "cleanup left task worktree"
git -C "$PRIMARY" show-ref --verify "refs/heads/$TASK_BRANCH" >/dev/null 2>&1 && fail "cleanup left merged task branch"
rm -rf "$ROOT"

# Cleanup removes the worktree but keeps an unmerged local branch instead of
# forcing deletion.
make_git_repo
prepare_implementing_wo
printf "local\n" > "$TASK_WORKTREE/local.txt"
git -C "$TASK_WORKTREE" add local.txt >/dev/null 2>&1
git -C "$TASK_WORKTREE" commit -m local-change >/dev/null 2>&1 || fail "task local commit failed"
run_cleanup_cli
assert_eq "$RC" "0" "cleanup unmerged CLI exit"
assert_match "$STDOUT" "Removed worktree: $TASK_WORKTREE" "cleanup removed unmerged worktree"
assert_match "$STDOUT" "Retained branch: $TASK_BRANCH" "cleanup retained unmerged branch"
[ ! -e "$TASK_WORKTREE" ] || fail "cleanup left unmerged task worktree"
git -C "$PRIMARY" show-ref --verify "refs/heads/$TASK_BRANCH" >/dev/null 2>&1 || fail "cleanup deleted unmerged branch"
rm -rf "$ROOT"

# Requires-Worktree:false cleanup is a safe no-op.
make_git_repo
prepare_implementing_wo
git -C "$PRIMARY" worktree remove "$TASK_WORKTREE" >/dev/null 2>&1 || fail "remove prepared task worktree failed"
git -C "$PRIMARY" branch -d "$TASK_BRANCH" >/dev/null 2>&1 || fail "delete prepared task branch failed"
sed -i.bak 's/^Requires-Worktree: true/Requires-Worktree: false/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's#^Branch:.*#Branch:#' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's#^Worktree:.*#Worktree:#' "$BASE/works/wo-1/task-a/spec.md"
STDOUT=$(run_cleanup_json "$PRIMARY" task-a)
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .removedWorktrees.length 0
assert_json_field "$STDOUT" .deletedBranches.length 0
assert_json_field "$STDOUT" .skipped.length 0
rm -rf "$ROOT"

# Cleanup skips tasks whose execution metadata does not match the harness-owned
# branch/worktree for that task.
make_git_repo
prepare_implementing_wo
sed -i.bak 's#^Branch:.*#Branch: bf/other/task#' "$BASE/works/wo-1/task-a/spec.md"
STDOUT=$(run_cleanup_json "$PRIMARY" task-a)
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .skipped.length 1
assert_match "$STDOUT" "Branch metadata is not harness-owned" "metadata mismatch skipped"
[ -d "$TASK_WORKTREE" ] || fail "metadata mismatch removed worktree"
git -C "$PRIMARY" show-ref --verify "refs/heads/$TASK_BRANCH" >/dev/null 2>&1 || fail "metadata mismatch removed branch"
rm -rf "$ROOT"

# Dirty task worktrees are retained and reported instead of force-removed.
make_git_repo
prepare_implementing_wo
printf "dirty\n" > "$TASK_WORKTREE/dirty.txt"
STDOUT=$(run_cleanup_json "$PRIMARY" task-a)
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .retainedWorktrees.length 1
[ -e "$TASK_WORKTREE/dirty.txt" ] || fail "dirty worktree was removed"
rm -rf "$ROOT"

# A filesystem path at the expected worktree location is retained when Git does
# not register it as a worktree.
make_git_repo
prepare_implementing_wo
git -C "$PRIMARY" worktree remove "$TASK_WORKTREE" >/dev/null 2>&1 || fail "remove registered worktree failed"
mkdir -p "$TASK_WORKTREE"
printf "not registered\n" > "$TASK_WORKTREE/README.txt"
STDOUT=$(run_cleanup_json "$PRIMARY" task-a)
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .retainedWorktrees.length 1
assert_match "$STDOUT" "not a registered Git worktree" "unregistered path retained"
[ -e "$TASK_WORKTREE/README.txt" ] || fail "unregistered path was removed"
rm -rf "$ROOT"

# A registered worktree at the expected path is retained when it is checked out
# on a different branch.
make_git_repo
prepare_implementing_wo
git -C "$PRIMARY" worktree remove "$TASK_WORKTREE" >/dev/null 2>&1 || fail "remove registered worktree failed"
git -C "$PRIMARY" worktree add -b wrong-cleanup-branch "$TASK_WORKTREE" HEAD >/dev/null 2>&1 || fail "create wrong-branch worktree failed"
STDOUT=$(run_cleanup_json "$PRIMARY" task-a)
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .retainedWorktrees.length 1
assert_match "$STDOUT" "registered branch is wrong-cleanup-branch" "wrong branch worktree retained"
git -C "$TASK_WORKTREE" branch --show-current | grep -q "^wrong-cleanup-branch$" || fail "wrong branch worktree was removed"
rm -rf "$ROOT"

pass
