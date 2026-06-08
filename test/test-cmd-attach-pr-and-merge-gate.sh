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
  PR_URL="https://github.com/example/repo/pull/7"
}

prepare_tasking_wo() {
  local requires="${1:-true}"
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Tasking/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  sed -i.bak "s/^Requires-Worktree: .*/Requires-Worktree: $requires/" "$BASE/works/wo-1/task-a/spec.md"
  if [ "$requires" = "true" ]; then
    git -C "$PRIMARY" branch "$TASK_BRANCH" HEAD >/dev/null 2>&1 || fail "task branch failed"
    mkdir -p "$(dirname "$TASK_WORKTREE")"
    git -C "$PRIMARY" worktree add "$TASK_WORKTREE" "$TASK_BRANCH" >/dev/null 2>&1 || fail "task worktree failed"
    sed -i.bak "s#^Branch:.*#Branch: $TASK_BRANCH#" "$BASE/works/wo-1/task-a/spec.md"
    sed -i.bak "s#^Worktree:.*#Worktree: $TASK_WORKTREE#" "$BASE/works/wo-1/task-a/spec.md"
  fi
}

write_pr() {
  local url="$1"
  sed -i.bak "s#^Pull-Request:.*#Pull-Request: $url#" "$BASE/works/wo-1/task-a/spec.md"
}

write_signed_review() {
  local dir="$1"
  mkdir -p "$dir"
  cat > "$dir/result_tester_1.md" <<EOF
# Desc

## Results

### Blocker
### High
### Minor
### Nit

## Accepted Criteria

- AC-1: signed by tester
EOF
}

make_fake_gh() {
  FAKE_BIN="$ROOT/fake-bin"
  mkdir -p "$FAKE_BIN"
  cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" != "pr" ] || [ "$2" != "view" ]; then
  echo "unexpected gh invocation" >&2
  exit 2
fi
case "${GH_FAKE_MODE:-merged}" in
  merged)
    printf '{"merged":true,"headRefName":"bf/wo-1/task-a","url":"%s"}\n' "$3"
    ;;
  unmerged)
    printf '{"merged":false,"headRefName":"bf/wo-1/task-a","url":"%s"}\n' "$3"
    ;;
  branch-mismatch)
    printf '{"merged":true,"headRefName":"other-branch","url":"%s"}\n' "$3"
    ;;
  error)
    echo "gh auth failed" >&2
    exit 1
    ;;
  *)
    echo "unknown GH_FAKE_MODE" >&2
    exit 2
    ;;
esac
EOF
  chmod +x "$FAKE_BIN/gh"
}

run_attach_cli() {
  local url="$1"
  STDOUT=$(BF_HOME="$BASE" PATH="$FAKE_BIN:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node "$BFH" attach-pr "wo-1/task-a" "$url" 2>"$ROOT/attach.err")
  RC=$?
  STDERR=$(cat "$ROOT/attach.err")
}

run_verify_b() {
  STDOUT=$(PATH="$FAKE_BIN:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', woId: 'wo-1', taskId: 'task-a', installDir: '$REPO_ROOT',
      })));
    });
  ")
}

assert_tasking_unmutated() {
  grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: task state changed"
  grep -qE "^- \[ \] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: AC flipped"
}

# attach-pr records a same-repository GitHub PR URL for a claimed
# worktree-required task.
make_git_repo
prepare_tasking_wo true
make_fake_gh
run_attach_cli "$PR_URL"
assert_eq "$RC" "0" "attach-pr happy exit"
assert_match "$STDOUT" "Pull-Request: $PR_URL" "attach-pr stdout"
grep -q "^Pull-Request: $PR_URL" "$BASE/works/wo-1/task-a/spec.md" || fail "Pull-Request not recorded"
rm -rf "$ROOT"

# attach-pr rejects unsupported task states, non-worktree tasks, malformed URLs,
# wrong-repository PRs, and branch mismatches when the GitHub head branch is
# available.
make_git_repo
prepare_tasking_wo true
make_fake_gh
sed -i.bak 's/^State: Tasking/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
run_attach_cli "$PR_URL"
assert_eq "$RC" "1" "attach-pr rejects Ready task"
assert_match "$STDOUT" "Tasking" "Ready rejection message"
rm -rf "$ROOT"

make_git_repo
prepare_tasking_wo false
make_fake_gh
run_attach_cli "$PR_URL"
assert_eq "$RC" "1" "attach-pr rejects non-worktree task"
assert_match "$STDOUT" "Requires-Worktree" "non-worktree rejection message"
rm -rf "$ROOT"

make_git_repo
prepare_tasking_wo true
make_fake_gh
run_attach_cli "not-a-url"
assert_eq "$RC" "1" "attach-pr rejects malformed URL"
assert_match "$STDOUT" "GitHub PR URL" "malformed rejection message"
rm -rf "$ROOT"

make_git_repo
prepare_tasking_wo true
make_fake_gh
run_attach_cli "https://github.com/example/other/pull/7"
assert_eq "$RC" "1" "attach-pr rejects wrong repository"
assert_match "$STDOUT" "same repository" "wrong repo rejection message"
rm -rf "$ROOT"

make_git_repo
prepare_tasking_wo true
make_fake_gh
GH_FAKE_MODE=branch-mismatch run_attach_cli "$PR_URL"
assert_eq "$RC" "1" "attach-pr rejects branch mismatch when available"
assert_match "$STDOUT" "branch" "branch mismatch rejection message"
rm -rf "$ROOT"

# GitHub worktree task verification fails until the recorded PR is merged, then
# succeeds after reviewer sign-off plus merged PR status.
make_git_repo
prepare_tasking_wo true
make_fake_gh
write_pr "$PR_URL"
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1"
GH_FAKE_MODE=unmerged run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
assert_tasking_unmutated "unmerged PR"
GH_FAKE_MODE=merged run_verify_b
assert_json_field "$STDOUT" .status "SUCCESS"
grep -q "^State: Completed" "$BASE/works/wo-1/task-a/spec.md" || fail "merged PR did not complete task"
rm -rf "$ROOT"

# Missing PR metadata and GitHub lookup failures prevent completion without
# corrupting task state.
make_git_repo
prepare_tasking_wo true
make_fake_gh
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1"
run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE=$(node -e "const j=JSON.parse(process.argv[1]); process.stdout.write(j.path || '');" "$STDOUT")
grep -q "Pull-Request" "$RESULT_FILE" || fail "missing PR failure not recorded"
assert_tasking_unmutated "missing PR"
rm -rf "$ROOT"

make_git_repo
prepare_tasking_wo true
make_fake_gh
write_pr "$PR_URL"
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1"
GH_FAKE_MODE=error run_verify_b
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE=$(node -e "const j=JSON.parse(process.argv[1]); process.stdout.write(j.path || '');" "$STDOUT")
grep -q "GitHub" "$RESULT_FILE" || fail "gh failure not recorded"
assert_tasking_unmutated "gh failure"
rm -rf "$ROOT"

# Non-GitHub providers and Requires-Worktree:false tasks do not receive the
# mechanical PR-merged gate.
make_git_repo
git -C "$PRIMARY" remote set-url origin "$ROOT/origin.git" >/dev/null 2>&1
prepare_tasking_wo true
make_fake_gh
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1"
run_verify_b
assert_json_field "$STDOUT" .status "SUCCESS"
grep -q "^State: Completed" "$BASE/works/wo-1/task-a/spec.md" || fail "non-GitHub provider should complete"
rm -rf "$ROOT"

make_git_repo
prepare_tasking_wo false
make_fake_gh
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1"
run_verify_b
assert_json_field "$STDOUT" .status "SUCCESS"
grep -q "^State: Completed" "$BASE/works/wo-1/task-a/spec.md" || fail "no-worktree task should complete"
rm -rf "$ROOT"

pass
