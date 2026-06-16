#!/usr/bin/env bash
# Regression for audit #2: the PR-merge completion gate and attach-pr must pin
# Worktree/Branch to the recomputed harness-owned values, require Branch, and
# assert the merged PR head branch equals Branch unconditionally. They must:
#   - reject a mismatched (hand-edited, non-harness-owned) Worktree/Branch,
#   - reject a missing Branch,
#   - reject a merged PR whose head branch differs from Branch,
#   - pass for the genuine harness-owned merged PR.
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
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Tasking/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: true/' "$BASE/works/wo-1/task-a/spec.md"
  git -C "$PRIMARY" branch "$TASK_BRANCH" HEAD >/dev/null 2>&1 || fail "task branch failed"
  mkdir -p "$(dirname "$TASK_WORKTREE")"
  git -C "$PRIMARY" worktree add "$TASK_WORKTREE" "$TASK_BRANCH" >/dev/null 2>&1 || fail "task worktree failed"
  sed -i.bak "s#^Branch:.*#Branch: $TASK_BRANCH#" "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak "s#^Worktree:.*#Worktree: $TASK_WORKTREE#" "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak "s#^Pull-Request:.*#Pull-Request: $PR_URL#" "$BASE/works/wo-1/task-a/spec.md"
}

make_fake_gh() {
  FAKE_BIN="$ROOT/fake-bin"
  mkdir -p "$FAKE_BIN"
  cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
case "${GH_FAKE_MODE:-merged}" in
  merged)
    printf '{"mergedAt":"2026-06-09T19:00:00Z","state":"MERGED","headRefName":"bf/wo-1/task-a","url":"%s"}\n' "$3" ;;
  merged-other-branch)
    printf '{"mergedAt":"2026-06-09T19:00:00Z","state":"MERGED","headRefName":"some-other-branch","url":"%s"}\n' "$3" ;;
  *) echo "unknown GH_FAKE_MODE" >&2; exit 2 ;;
esac
EOF
  chmod +x "$FAKE_BIN/gh"
}

# Drives the merge gate (used by `complete`) against task-a.
run_gate() {
  STDOUT=$(PATH="$FAKE_BIN:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (lw) => {
      const g = await import('$REPO_ROOT/bin/lib/harness/github-pr-gate.mjs');
      const bundle = await lw.loadWo({ baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO_ROOT' });
      const task = bundle.tasks.find(t => t.id === 'task-a');
      const r = g.checkGitHubPrMergedGate(task, { baseHome: '$BASE', cwd: '$PRIMARY', woId: 'wo-1', taskId: 'task-a' });
      process.stdout.write(JSON.stringify(r));
    });
  ")
}

run_attach() {
  local url="$1"
  STDOUT=$(BF_HOME="$BASE" PATH="$FAKE_BIN:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node "$BFH" attach-pr "wo-1/task-a" "$url" 2>"$ROOT/attach.err")
  RC=$?
  STDERR=$(cat "$ROOT/attach.err")
}

# --- Case A: genuine harness-owned merged PR -> gate passes. ---
make_git_repo; prepare_tasking_wo; make_fake_gh
run_gate
assert_json_field "$STDOUT" .ok true "genuine harness-owned merged PR must pass the gate"
rm -rf "$ROOT"

# --- Case B: hand-edited non-harness-owned Branch/Worktree -> gate rejects. ---
make_git_repo; prepare_tasking_wo; make_fake_gh
sed -i.bak "s#^Branch:.*#Branch: attacker/branch#" "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak "s#^Worktree:.*#Worktree: /tmp/attacker-clone#" "$BASE/works/wo-1/task-a/spec.md"
run_gate
assert_json_field "$STDOUT" .ok false "mismatched (non-harness-owned) Worktree/Branch must be rejected"
rm -rf "$ROOT"

# --- Case C: missing Branch -> gate rejects (no short-circuit skip). ---
make_git_repo; prepare_tasking_wo; make_fake_gh
sed -i.bak "s#^Branch:.*#Branch:#" "$BASE/works/wo-1/task-a/spec.md"
run_gate
assert_json_field "$STDOUT" .ok false "missing Branch must be rejected"
rm -rf "$ROOT"

# --- Case D: merged but unrelated PR (headRefName != Branch) -> gate rejects. ---
make_git_repo; prepare_tasking_wo; make_fake_gh
GH_FAKE_MODE=merged-other-branch run_gate
assert_json_field "$STDOUT" .ok false "merged PR with a foreign head branch must be rejected"
rm -rf "$ROOT"

# --- attach-pr mirror: missing Branch is rejected. ---
make_git_repo; prepare_tasking_wo; make_fake_gh
sed -i.bak "s#^Pull-Request:.*#Pull-Request:#" "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak "s#^Branch:.*#Branch:#" "$BASE/works/wo-1/task-a/spec.md"
run_attach "$PR_URL"
assert_eq "$RC" "1" "attach-pr must reject a missing Branch"
rm -rf "$ROOT"

# --- attach-pr mirror: merged-but-unrelated PR head branch is rejected. ---
make_git_repo; prepare_tasking_wo; make_fake_gh
sed -i.bak "s#^Pull-Request:.*#Pull-Request:#" "$BASE/works/wo-1/task-a/spec.md"
GH_FAKE_MODE=merged-other-branch run_attach "$PR_URL"
assert_eq "$RC" "1" "attach-pr must reject a foreign PR head branch"
rm -rf "$ROOT"

pass
