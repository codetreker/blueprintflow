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
}

prepare_wo() {
  local requires="$1"
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
  sed -i.bak "s/^Requires-Worktree: .*/Requires-Worktree: $requires/" "$BASE/works/wo-1/task-a/spec.md"
}

prepare_draft_wo_with_spec_review() {
  local requires="$1"
  mkdir -p "$BASE/works"
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
  sed -i.bak "s/^Requires-Worktree: .*/Requires-Worktree: $requires/" "$BASE/works/wo-1/task-a/spec.md"
  mkdir -p "$BASE/works/wo-1/runs/reviews/round_1"
  cat > "$BASE/works/wo-1/runs/reviews/round_1/verify-result.md" <<EOF
---
Result: SUCCESS
Mode: Spec Review
Scope: wo-1
Round: 1
Timestamp: 2026-06-08 10:00
---
EOF
}

cmd_accept_json() {
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdAccept({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO_ROOT',
      })));
    });
  "
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

assert_task_a_unmutated() {
  grep -q "^State: Ready" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: task-a state mutated"
  grep -q "^State: Accepted" "$BASE/works/wo-1/bf.md" || fail "$1: bf state mutated"
  grep -q "^Branch:$" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: Branch mutated"
  grep -q "^Worktree:$" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: Worktree mutated"
  grep -q "^Pull-Request:$" "$BASE/works/wo-1/task-a/spec.md" || fail "$1: Pull-Request mutated"
}

# accept locks contracts only; it must not create execution branches/worktrees
# or write execution metadata.
make_git_repo_with_origin
prepare_draft_wo_with_spec_review true
STDOUT=$(cmd_accept_json)
assert_json_field "$STDOUT" .ok true
[ ! -e "$PRIMARY/.worktrees" ] || fail "accept created .worktrees"
grep -q "^Branch:$" "$BASE/works/wo-1/task-a/spec.md" || fail "accept wrote Branch"
grep -q "^Worktree:$" "$BASE/works/wo-1/task-a/spec.md" || fail "accept wrote Worktree"
grep -q "^Pull-Request:$" "$BASE/works/wo-1/task-a/spec.md" || fail "accept wrote Pull-Request"
rm -rf "$ROOT"

# Requires-Worktree:false is claimed without Git setup or execution metadata.
make_git_repo_with_origin
prepare_wo false
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId task-a
[ ! -e "$PRIMARY/.worktrees" ] || fail "Requires-Worktree:false created .worktrees"
grep -q "^State: Tasking" "$BASE/works/wo-1/task-a/spec.md" || fail "Requires-Worktree:false task not claimed"
grep -q "^Branch:$" "$BASE/works/wo-1/task-a/spec.md" || fail "Requires-Worktree:false wrote Branch"
grep -q "^Worktree:$" "$BASE/works/wo-1/task-a/spec.md" || fail "Requires-Worktree:false wrote Worktree"
printf "%s" "$STDOUT" | grep -q '"branch"' && fail "Requires-Worktree:false returned branch metadata"
rm -rf "$ROOT"

# Requires-Worktree:true in managed Git mode creates the expected branch and
# worktree from origin/HEAD, records metadata, and returns it.
make_git_repo_with_origin
prepare_wo true
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 1
assert_json_field "$STDOUT" .tasks.0.taskId task-a
EXPECTED_BRANCH="bf/wo-1/task-a"
EXPECTED_WORKTREE="$PRIMARY/.worktrees/works/wo-1/task-a"
TASK_BRANCH=$(node -e "const j=JSON.parse(process.argv[1]); process.stdout.write(j.tasks?.[0]?.branch || '');" "$STDOUT")
TASK_WORKTREE=$(node -e "const j=JSON.parse(process.argv[1]); process.stdout.write(j.tasks?.[0]?.worktree || '');" "$STDOUT")
assert_eq "$TASK_BRANCH" "$EXPECTED_BRANCH" "returned Branch metadata"
assert_eq "$TASK_WORKTREE" "$EXPECTED_WORKTREE" "returned Worktree metadata"
grep -q "^Branch: $EXPECTED_BRANCH" "$BASE/works/wo-1/task-a/spec.md" || fail "Branch metadata not recorded"
grep -q "^Worktree: $EXPECTED_WORKTREE" "$BASE/works/wo-1/task-a/spec.md" || fail "Worktree metadata not recorded"
grep -q "^Pull-Request:$" "$BASE/works/wo-1/task-a/spec.md" || fail "Pull-Request should remain empty"
git -C "$PRIMARY" show-ref --verify "refs/heads/$EXPECTED_BRANCH" >/dev/null 2>&1 || fail "expected task branch missing"
[ -d "$EXPECTED_WORKTREE/.git" ] || [ -f "$EXPECTED_WORKTREE/.git" ] || fail "expected task worktree missing"
CURRENT_BRANCH=$(git -C "$EXPECTED_WORKTREE" branch --show-current)
assert_eq "$CURRENT_BRANCH" "$EXPECTED_BRANCH" "task worktree branch"
rm -rf "$ROOT"

# Batch next prepares every Ready worktree-required task and returns the
# corresponding metadata in bf.md task-list order.
make_git_repo_with_origin
prepare_wo true
sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: true/' "$BASE/works/wo-1/task-b/spec.md"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .tasks.length 2
assert_json_field "$STDOUT" .tasks.0.taskId task-a
assert_json_field "$STDOUT" .tasks.1.taskId task-b
EXPECTED_BRANCH_A="bf/wo-1/task-a"
EXPECTED_WORKTREE_A="$PRIMARY/.worktrees/works/wo-1/task-a"
EXPECTED_BRANCH_B="bf/wo-1/task-b"
EXPECTED_WORKTREE_B="$PRIMARY/.worktrees/works/wo-1/task-b"
assert_json_field "$STDOUT" .tasks.0.branch "$EXPECTED_BRANCH_A"
assert_json_field "$STDOUT" .tasks.0.worktree "$EXPECTED_WORKTREE_A"
assert_json_field "$STDOUT" .tasks.1.branch "$EXPECTED_BRANCH_B"
assert_json_field "$STDOUT" .tasks.1.worktree "$EXPECTED_WORKTREE_B"
grep -q "^Branch: $EXPECTED_BRANCH_A" "$BASE/works/wo-1/task-a/spec.md" || fail "task-a Branch metadata not recorded"
grep -q "^Worktree: $EXPECTED_WORKTREE_A" "$BASE/works/wo-1/task-a/spec.md" || fail "task-a Worktree metadata not recorded"
grep -q "^Branch: $EXPECTED_BRANCH_B" "$BASE/works/wo-1/task-b/spec.md" || fail "task-b Branch metadata not recorded"
grep -q "^Worktree: $EXPECTED_WORKTREE_B" "$BASE/works/wo-1/task-b/spec.md" || fail "task-b Worktree metadata not recorded"
git -C "$PRIMARY" show-ref --verify "refs/heads/$EXPECTED_BRANCH_A" >/dev/null 2>&1 || fail "expected task-a branch missing"
git -C "$PRIMARY" show-ref --verify "refs/heads/$EXPECTED_BRANCH_B" >/dev/null 2>&1 || fail "expected task-b branch missing"
[ -d "$EXPECTED_WORKTREE_A/.git" ] || [ -f "$EXPECTED_WORKTREE_A/.git" ] || fail "expected task-a worktree missing"
[ -d "$EXPECTED_WORKTREE_B/.git" ] || [ -f "$EXPECTED_WORKTREE_B/.git" ] || fail "expected task-b worktree missing"
rm -rf "$ROOT"

# A bf-wo may itself run from a linked worktree under .worktrees/<bf-wo>.
# Task worktrees must use a non-nesting namespace so they do not appear as
# untracked directories inside that active worktree.
make_git_repo_with_origin
prepare_wo true
LINKED="$PRIMARY/.worktrees/wo-1"
git -C "$PRIMARY" fetch origin >/dev/null 2>&1 || fail "fetch origin failed"
git -C "$PRIMARY" worktree add -b active-wo "$LINKED" refs/remotes/origin/HEAD >/dev/null 2>&1 || fail "create active linked worktree failed"
STDOUT=$(cmd_next_json "$LINKED")
assert_json_field "$STDOUT" .ok true
EXPECTED_WORKTREE="$PRIMARY/.worktrees/works/wo-1/task-a"
TASK_WORKTREE=$(node -e "const j=JSON.parse(process.argv[1]); process.stdout.write(j.tasks?.[0]?.worktree || '');" "$STDOUT")
assert_eq "$TASK_WORKTREE" "$EXPECTED_WORKTREE" "task worktree must not nest under active linked worktree"
LINKED_STATUS=$(git -C "$LINKED" status --porcelain --untracked-files=normal)
[ -z "$LINKED_STATUS" ] || fail "task worktree appeared as untracked content in active linked worktree: $LINKED_STATUS"
rm -rf "$ROOT"

# Outside managed Git mode, next must fail before any contract mutation.
BASE=$(make_temp_home)
copy_fixture clean-wo "$BASE/works/wo-1"
sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: true/' "$BASE/works/wo-1/task-a/spec.md"
STDOUT=$(cmd_next_json "$BASE")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "managed Git" "non-managed failure message"
assert_task_a_unmutated "non-managed"
rm -rf "$BASE"

# If a later task in the batch fails setup, earlier Ready tasks must not be
# claimed before the batch returns the failure.
BASE=$(make_temp_home)
copy_fixture clean-wo "$BASE/works/wo-1"
sed -i.bak 's/^Id: clean-wo/Id: wo-1/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-b/spec.md"
sed -i.bak 's/^- task-b: task-a/- task-b/' "$BASE/works/wo-1/bf.md"
sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: false/' "$BASE/works/wo-1/task-a/spec.md"
sed -i.bak 's/^Requires-Worktree: .*/Requires-Worktree: true/' "$BASE/works/wo-1/task-b/spec.md"
STDOUT=$(cmd_next_json "$BASE")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "managed Git" "batch non-managed failure message"
grep -q "^State: Ready" "$BASE/works/wo-1/task-a/spec.md" || fail "batch setup failure mutated task-a"
grep -q "^State: Ready" "$BASE/works/wo-1/task-b/spec.md" || fail "batch setup failure mutated task-b"
grep -q "^State: Accepted" "$BASE/works/wo-1/bf.md" || fail "batch setup failure mutated bf"
rm -rf "$BASE"

# Missing origin, missing origin/HEAD, and fetch/unreachable remote all fail
# before contract mutation.
make_git_repo_with_origin
prepare_wo true
git -C "$PRIMARY" remote remove origin >/dev/null 2>&1 || fail "remove origin failed"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "origin" "missing origin failure message"
assert_task_a_unmutated "missing origin"
rm -rf "$ROOT"

make_git_repo_with_origin
prepare_wo true
git -C "$ORIGIN" symbolic-ref HEAD refs/heads/missing >/dev/null 2>&1 || fail "break origin HEAD failed"
git -C "$PRIMARY" symbolic-ref --delete refs/remotes/origin/HEAD >/dev/null 2>&1 || true
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "origin/HEAD" "missing origin/HEAD failure message"
assert_task_a_unmutated "missing origin/HEAD"
rm -rf "$ROOT"

make_git_repo_with_origin
prepare_wo true
git -C "$PRIMARY" remote set-url origin "$ROOT/missing-origin.git" >/dev/null 2>&1 || fail "break origin failed"
STDOUT=$(cmd_next_json "$PRIMARY")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "fetch" "fetch failure message"
assert_task_a_unmutated "fetch failure"
rm -rf "$ROOT"

pass
