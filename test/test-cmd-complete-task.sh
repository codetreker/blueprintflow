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
  sed -i.bak '/^State: Implementing$/a Mode-Lock: per-task-pr' "$BASE/works/wo-1/bf.md"
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
  sed -i.bak "s#^Pull-Request:.*#Pull-Request: $1#" "$BASE/works/wo-1/task-a/spec.md"
}

write_verify_result() {
  local mode="$1" scope="$2" result="${3:-SUCCESS}"
  local dir="$BASE/works/wo-1/task-a/runs/reviews/round_1"
  mkdir -p "$dir"
  cat > "$dir/verify-result.md" <<EOF
---
Result: $result
Mode: $mode
Scope: $scope
Round: 1
Timestamp: 2026-06-11 10:00
---

## AC Sign-off
- AC-1: signed (by tester)

## Flipped
- AC-1
EOF
  touch -d "2026-06-11 10:00:00" "$BASE/works/wo-1/task-a/spec.md"
  touch -d "2026-06-11 10:00:30" "$dir/verify-result.md"
}

write_success_verify() {
  write_verify_result "Task Verification" "wo-1/task-a" "SUCCESS"
}

check_ac() {
  sed -i.bak 's/^- \[ \] AC-1/- [x] AC-1/' "$BASE/works/wo-1/task-a/spec.md"
  # Guard against a future literal-caret reintroduction: the spec must now contain a
  # genuinely-checked AC line (not a no-op that leaves an empty parsed AC list).
  grep -q '^- \[x\] AC-1|' "$BASE/works/wo-1/task-a/spec.md" \
    || fail "check_ac did not produce a checked '- [x] AC-1|' line (caret typo?)"
}

mark_task_spec_after_verify() {
  touch -d "2026-06-11 10:01:00" "$BASE/works/wo-1/task-a/spec.md"
}

make_fake_gh() {
  FAKE_BIN="$ROOT/fake-bin"
  mkdir -p "$FAKE_BIN"
  cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
case "${GH_FAKE_MODE:-merged}" in
  merged)
    printf '{"mergedAt":"2026-06-09T19:00:00Z","state":"MERGED","headRefName":"bf/wo-1/task-a","url":"%s"}\n' "$3"
    ;;
  unmerged)
    printf '{"mergedAt":null,"state":"OPEN","headRefName":"bf/wo-1/task-a","url":"%s"}\n' "$3"
    ;;
  error)
    echo "gh auth failed" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$FAKE_BIN/gh"
}

run_complete_json() {
  STDOUT=$(PATH="${FAKE_BIN:-}:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-complete.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdComplete({
        baseHome: '$BASE', woId: 'wo-1', taskId: 'task-a', installDir: '$REPO_ROOT', now: new Date('2026-06-11T10:30:00Z'),
      })));
    });
  ")
}

run_complete_cli() {
  STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" PATH="${FAKE_BIN:-}:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node "$BFH" complete "wo-1/task-a" 2>"$ROOT/complete.err")
  RC=$?
  STDERR=$(cat "$ROOT/complete.err")
}

run_complete_cli_target() {
  local target="$1"
  STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" PATH="${FAKE_BIN:-}:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node "$BFH" complete "$target" 2>"$ROOT/complete.err")
  RC=$?
  STDERR=$(cat "$ROOT/complete.err")
}

# unchecked AC blocks complete
make_git_repo
prepare_tasking_wo false
write_success_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "unchecked AC" "unchecked AC rejected"
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "unchecked AC changed state"
rm -rf "$ROOT"

# missing verify blocks complete
make_git_repo
prepare_tasking_wo false
check_ac
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Task Verification SUCCESS" "missing verify rejected"
rm -rf "$ROOT"

# complete rejects tasks that are not Tasking
make_git_repo
prepare_tasking_wo false
check_ac
write_success_verify
sed -i.bak 's/^State: Tasking/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "State: Tasking" "non-Tasking task rejected"
rm -rf "$ROOT"

# wrong verify mode blocks complete
make_git_repo
prepare_tasking_wo false
check_ac
write_verify_result "Spec Review" "wo-1/task-a" "SUCCESS"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Task Verification SUCCESS" "wrong verify mode rejected"
rm -rf "$ROOT"

# wrong verify scope blocks complete
make_git_repo
prepare_tasking_wo false
check_ac
write_verify_result "Task Verification" "wo-1/task-b" "SUCCESS"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Task Verification SUCCESS" "wrong verify scope rejected"
rm -rf "$ROOT"

# latest failed verify blocks complete
make_git_repo
prepare_tasking_wo false
check_ac
write_verify_result "Task Verification" "wo-1/task-a" "FAIL"
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Task Verification SUCCESS" "failed verify rejected"
rm -rf "$ROOT"

# stale verify blocks complete
make_git_repo
prepare_tasking_wo false
check_ac
write_success_verify
mark_task_spec_after_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "changed after latest Task Verification SUCCESS" "stale verify rejected"
rm -rf "$ROOT"

# Pull-Request metadata written after verify makes the verify result stale
make_git_repo
prepare_tasking_wo true
make_fake_gh
check_ac
write_success_verify
write_pr "$PR_URL"
mark_task_spec_after_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "changed after latest Task Verification SUCCESS" "post-verify PR metadata rejected"
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "post-verify metadata changed state"
rm -rf "$ROOT"

# GitHub worktree task rejects missing PR metadata
make_git_repo
prepare_tasking_wo true
make_fake_gh
check_ac
write_success_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Pull-Request" "missing PR rejected"
rm -rf "$ROOT"

# GitHub worktree task rejects wrong-repository PR
make_git_repo
prepare_tasking_wo true
make_fake_gh
check_ac
write_pr "https://github.com/example/other/pull/7"
write_success_verify
run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "same GitHub repository" "wrong repo PR rejected"
rm -rf "$ROOT"

# GitHub worktree task needs merged PR
make_git_repo
prepare_tasking_wo true
make_fake_gh
check_ac
write_pr "$PR_URL"
write_success_verify
GH_FAKE_MODE=unmerged run_complete_json
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "not merged" "unmerged PR rejected"
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "unmerged PR changed state"
GH_FAKE_MODE=merged run_complete_json
assert_json_field "$STDOUT" .ok true
grep -q "^State: Completed" "$BASE/works/wo-1/task-a/spec.md" || fail "merged PR did not complete task"
rm -rf "$ROOT"

# complete accepts a bare work-object target, then rejects incomplete work objects
make_git_repo
prepare_tasking_wo false
run_complete_cli_target "wo-1"
assert_eq "$RC" "1" "complete bare wo exit"
assert_match "$STDOUT" "not all tasks completed" "incomplete bare wo rejected"
rm -rf "$ROOT"

# complete rejects extra CLI arguments before mutating state
make_git_repo
prepare_tasking_wo false
check_ac
write_success_verify
STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" node "$BFH" complete "wo-1/task-a" "extra" 2>"$ROOT/complete-extra.err")
RC=$?
STDERR=$(cat "$ROOT/complete-extra.err")
assert_eq "$RC" "2" "complete extra arg exit"
assert_match "$STDERR" "complete takes no extra arguments" "complete extra arg rejection"
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "extra arg complete mutated task"
rm -rf "$ROOT"

# Requires-Worktree:false task completes without PR gate
make_git_repo
prepare_tasking_wo false
check_ac
write_success_verify
run_complete_cli
assert_eq "$RC" "0" "complete CLI exit"
assert_match "$STDOUT" "SUCCESS" "complete CLI success"
assert_match "$STDOUT" "task-a: Tasking -> Completed" "complete CLI transition"
grep -q "^State: Completed" "$BASE/works/wo-1/task-a/spec.md" || fail "no-worktree task did not complete"
rm -rf "$ROOT"

pass
