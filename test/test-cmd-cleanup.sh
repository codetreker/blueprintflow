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

prepare_completed_wo() {
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^- \[ \] AC-1/^- [x] AC-1/' "$BASE/works/wo-1/bf.md"
  for task in task-a task-b; do
    sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/$task/spec.md"
    sed -i.bak 's/^- \[ \] AC-1/^- [x] AC-1/' "$BASE/works/wo-1/$task/spec.md"
  done
  sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: true/' "$BASE/works/wo-1/task-a/spec.md"
  git -C "$PRIMARY" branch "$TASK_BRANCH" HEAD >/dev/null 2>&1 || fail "task branch failed"
  mkdir -p "$(dirname "$TASK_WORKTREE")"
  git -C "$PRIMARY" worktree add "$TASK_WORKTREE" "$TASK_BRANCH" >/dev/null 2>&1 || fail "task worktree failed"
  sed -i.bak "s#^Branch:.*#Branch: $TASK_BRANCH#" "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak "s#^Worktree:.*#Worktree: $TASK_WORKTREE#" "$BASE/works/wo-1/task-a/spec.md"
}

run_cleanup_json() {
  local cwd="$1"
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-cleanup.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdCleanup({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO_ROOT', cwd: '$cwd',
      })));
    });
  "
}

run_cleanup_cli() {
  STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" node "$BFH" cleanup wo-1)
  RC=$?
}

# Cleanup refuses active work before Final Acceptance completes.
make_git_repo
prepare_completed_wo
sed -i.bak 's/^State: Completed/State: Implementing/' "$BASE/works/wo-1/bf.md"
STDOUT=$(run_cleanup_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Completed" "non-completed cleanup rejection"
[ -d "$TASK_WORKTREE" ] || fail "cleanup removed worktree before Completed"
git -C "$PRIMARY" show-ref --verify "refs/heads/$TASK_BRANCH" >/dev/null 2>&1 || fail "cleanup removed branch before Completed"
rm -rf "$ROOT"

# Cleanup removes a completed task's harness-owned worktree and safely deletes
# the local task branch when Git considers it merged.
make_git_repo
prepare_completed_wo
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
prepare_completed_wo
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

pass
