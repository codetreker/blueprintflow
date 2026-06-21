#!/usr/bin/env bash
# Mode B P2: cmd-next single-pr serial claim + shared worktree wiring.
#
# - single-pr + Requires-Worktree:true => effective claim batch capped at 1
#   (serial execution behind the first-claim lock; §1.2).
# - single-pr + Requires-Worktree:false => keeps MAX_NEXT_TASKS parallelism.
# - each claimed worktree task in single-pr gets the SHARED bf/<wo> + _shared
#   metadata written into its spec (not a per-task branch).
# - the shared worktree is created once and REUSED by a second serial claim.
# - Mode A (per-task-pr) batching + per-task worktree creation UNCHANGED.
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
}

# Create a single-pr WO whose bf.md is Accepted + Mode-Lock: single-pr (so the
# accept-lock passes), with two independent Ready tasks.
prepare_single_pr_wo() {
  local requires="$1"
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak '/^State: Draft$/a Integration: single-pr\
Mode-Lock: single-pr' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/wo-1/bf.md"
  # task-b independent of task-a so both can be eligible in one round
  sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  sed -i.bak "s/^Requires-Worktree: .*/Requires-Worktree: $requires/" "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak "s/^Requires-Worktree: .*/Requires-Worktree: $requires/" "$BASE/works/wo-1/task-b/spec.md"
}

# Mode A control WO (no Integration field => per-task-pr).
prepare_mode_a_wo() {
  local requires="$1"
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  sed -i.bak "s/^Requires-Worktree: .*/Requires-Worktree: $requires/" "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak "s/^Requires-Worktree: .*/Requires-Worktree: $requires/" "$BASE/works/wo-1/task-b/spec.md"
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

# --- single-pr serial claim: two worktree tasks => batch capped at 1 ---------
make_git_repo_with_origin
prepare_single_pr_wo true
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId task-a
# the claimed task carries the SHARED WO branch/worktree, not a per-task branch
assert_json_field "$STDOUT" .tasks.0.branch "bf/wo-1"
assert_json_field "$STDOUT" .tasks.0.worktree "$PRIMARY/.worktrees/works/wo-1/_shared"
grep -q "^Branch: bf/wo-1$" "$BASE/works/wo-1/task-a/spec.md" || fail "shared Branch not written to task-a spec"
grep -q "^Worktree: $PRIMARY/.worktrees/works/wo-1/_shared$" "$BASE/works/wo-1/task-a/spec.md" || fail "shared Worktree not written"
# task-b NOT claimed (batch=1); still Ready
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "task-a not claimed"
grep -q "^State: Ready" "$BASE/works/wo-1/task-b/spec.md" || fail "task-b should remain Ready (serial cap)"
# the shared branch/worktree exist exactly once; no per-task branch created
git -C "$PRIMARY" show-ref --verify "refs/heads/bf/wo-1" >/dev/null 2>&1 || fail "shared branch missing"
git -C "$PRIMARY" show-ref --verify "refs/heads/bf/wo-1/task-a" >/dev/null 2>&1 && fail "per-task branch wrongly created in single-pr"
[ -e "$PRIMARY/.worktrees/works/wo-1/_shared/.git" ] || fail "shared worktree missing"
[ ! -e "$PRIMARY/.worktrees/works/wo-1/task-a" ] || fail "per-task worktree wrongly created in single-pr"

# Second claim round: task-a moves to Completed (simulate) so task-b becomes the
# single eligible task; it must REUSE the shared worktree, not create a new one.
sed -i.bak 's/^State: Tasking/State: Completed/' "$BASE/works/wo-1/task-a/spec.md"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId task-b
assert_json_field "$STDOUT" .tasks.0.branch "bf/wo-1"
assert_json_field "$STDOUT" .tasks.0.worktree "$PRIMARY/.worktrees/works/wo-1/_shared"
grep -q "^Branch: bf/wo-1$" "$BASE/works/wo-1/task-b/spec.md" || fail "shared Branch not written to task-b spec"
rm -rf "$ROOT"

# --- single-pr + Requires-Worktree:false keeps parallelism -------------------
make_git_repo_with_origin
prepare_single_pr_wo false
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 2
assert_json_field "$STDOUT" .tasks.0.taskId task-a
assert_json_field "$STDOUT" .tasks.1.taskId task-b
[ ! -e "$PRIMARY/.worktrees" ] || fail "Requires-Worktree:false single-pr created worktrees"
rm -rf "$ROOT"

# --- Mode A UNCHANGED: two worktree tasks claimed in parallel, per-task ------
make_git_repo_with_origin
prepare_mode_a_wo true
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 2
assert_json_field "$STDOUT" .tasks.0.branch "bf/wo-1/task-a"
assert_json_field "$STDOUT" .tasks.1.branch "bf/wo-1/task-b"
git -C "$PRIMARY" show-ref --verify "refs/heads/bf/wo-1/task-a" >/dev/null 2>&1 || fail "Mode A per-task-a branch missing"
git -C "$PRIMARY" show-ref --verify "refs/heads/bf/wo-1/task-b" >/dev/null 2>&1 || fail "Mode A per-task-b branch missing"
[ -e "$PRIMARY/.worktrees/works/wo-1/task-a/.git" ] || fail "Mode A per-task-a worktree missing"
[ -e "$PRIMARY/.worktrees/works/wo-1/task-b/.git" ] || fail "Mode A per-task-b worktree missing"
[ ! -e "$PRIMARY/.worktrees/works/wo-1/_shared" ] || fail "Mode A wrongly created a shared worktree"
rm -rf "$ROOT"

pass
