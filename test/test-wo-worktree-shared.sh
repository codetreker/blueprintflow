#!/usr/bin/env bash
# Mode B P2: shared WO worktree + serial claim for single-pr.
#
# 5.4 open-question contract (DECIDED, tested here):
#  (a) CLEAN-ON-CLAIM: a new task claim on the shared branch bf/<wo> MUST NOT
#      discard prior tasks' commits. We therefore REQUIRE a clean working tree
#      (git status --porcelain empty) on reuse and FAIL CLOSED if dirty — we do
#      NOT `git reset --hard` / `clean -fd` (which would destroy unpushed local
#      task commits accumulated on the shared branch).
#  (b) CRASH-IDEMPOTENT CREATE: if the worktree already exists, validate-and-
#      return (never re-create); recover a half-initialized path via the existing
#      validateExistingWorktree recovery pattern.
#  (c) FIRST-CLAIM LOCK: fs O_EXCL (.bf-create.lock) so two concurrent first
#      claims cannot both create; the loser fails fast (no retry).
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
  mkdir -p "$BASE"
}

prepare_wo_json() {
  # call prepareWoWorktree(...) for the shared WO worktree and print JSON
  local cwd="$1" woid="$2"
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/managed-git.mjs').then((m) => {
      const r = m.prepareWoWorktree({
        baseHome: '$BASE', cwd: '$cwd', woId: '$woid', metadata: {},
      });
      process.stdout.write(JSON.stringify(r));
    });
  "
}

validate_wo_json() {
  local cwd="$1" woid="$2" branch="$3" worktree="$4"
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/managed-git.mjs').then((m) => {
      const r = m.validateWoWorktree({
        baseHome: '$BASE', cwd: '$cwd', woId: '$woid',
        metadata: { branch: '$branch', worktree: '$worktree' },
      });
      process.stdout.write(JSON.stringify(r));
    });
  "
}

# --- create-once + idempotent reuse -----------------------------------------

# First prepareWoWorktree creates bf/<wo> + _shared off origin/HEAD.
make_git_repo_with_origin
OUT=$(prepare_wo_json "$PRIMARY" "wo-1")
assert_json_field "$OUT" .ok true
EXPECTED_BRANCH="bf/wo-1"
EXPECTED_WORKTREE="$PRIMARY/.worktrees/works/wo-1/_shared"
assert_json_field "$OUT" .branch "$EXPECTED_BRANCH"
assert_json_field "$OUT" .worktree "$EXPECTED_WORKTREE"
git -C "$PRIMARY" show-ref --verify "refs/heads/$EXPECTED_BRANCH" >/dev/null 2>&1 || fail "shared WO branch missing"
[ -e "$EXPECTED_WORKTREE/.git" ] || fail "shared WO worktree missing"
CURRENT_BRANCH=$(git -C "$EXPECTED_WORKTREE" branch --show-current)
assert_eq "$CURRENT_BRANCH" "$EXPECTED_BRANCH" "shared worktree checked out branch"
# the create lock is released (file removed) after a successful create
[ ! -e "$PRIMARY/.worktrees/works/wo-1/.bf-create.lock" ] || fail "create lock not released after create"

# Second prepareWoWorktree REUSES the same worktree (no re-create, no error),
# even after the first task adds a LOCAL commit to bf/<wo> — the prior commit
# must survive (5.4a: never reset --hard).
echo "task-a work" > "$EXPECTED_WORKTREE/task-a.txt"
git -C "$EXPECTED_WORKTREE" add task-a.txt >/dev/null 2>&1
git -C "$EXPECTED_WORKTREE" -c user.email=t@e.com -c user.name=t commit -m "task-a commit" >/dev/null 2>&1 || fail "task-a commit failed"
PRIOR_HEAD=$(git -C "$EXPECTED_WORKTREE" rev-parse HEAD)
OUT=$(prepare_wo_json "$PRIMARY" "wo-1")
assert_json_field "$OUT" .ok true
assert_json_field "$OUT" .worktree "$EXPECTED_WORKTREE"
REUSE_HEAD=$(git -C "$EXPECTED_WORKTREE" rev-parse HEAD)
assert_eq "$REUSE_HEAD" "$PRIOR_HEAD" "reuse must preserve prior task commit (no reset --hard)"
[ -f "$EXPECTED_WORKTREE/task-a.txt" ] || fail "prior task commit content was destroyed on reuse"
rm -rf "$ROOT"

# --- clean-on-claim contract (5.4a) -----------------------------------------

# A dirty shared worktree FAILS reuse (we do NOT clean it; we fail closed so the
# operator inspects rather than silently losing work).
make_git_repo_with_origin
OUT=$(prepare_wo_json "$PRIMARY" "wo-1")
assert_json_field "$OUT" .ok true
WT="$PRIMARY/.worktrees/works/wo-1/_shared"
echo "uncommitted scratch" > "$WT/dirty.txt"
OUT=$(prepare_wo_json "$PRIMARY" "wo-1")
assert_json_field "$OUT" .ok false
assert_match "$OUT" "clean" "dirty shared worktree must fail the clean-on-claim contract"
# the dirty file is still there — we did NOT clean/destroy it
[ -f "$WT/dirty.txt" ] || fail "clean-on-claim contract destroyed uncommitted content"
rm -rf "$ROOT"

# --- first-claim lock (5.4c) ------------------------------------------------

# A held .bf-create.lock makes a fresh first-claim fail fast (no retry).
make_git_repo_with_origin
mkdir -p "$PRIMARY/.worktrees/works/wo-1"
node -e "const fs=require('fs'); fs.closeSync(fs.openSync('$PRIMARY/.worktrees/works/wo-1/.bf-create.lock','ax'));"
OUT=$(prepare_wo_json "$PRIMARY" "wo-1")
assert_json_field "$OUT" .ok false
assert_match "$OUT" "claim" "held create lock fails fast"
[ ! -e "$PRIMARY/.worktrees/works/wo-1/_shared" ] || fail "lock loser created the worktree anyway"
rm -rf "$ROOT"

# Two CONCURRENT first-claims: exactly one wins the lock, the other fails fast.
make_git_repo_with_origin
# Use two child processes for true concurrency on the lock.
node --input-type=module -e "
  import('node:child_process').then(({ spawn }) => {
    const run = () => new Promise((resolve) => {
      const code = \"import('$REPO_ROOT/bin/lib/harness/managed-git.mjs').then((m)=>{const r=m.prepareWoWorktree({baseHome:'$BASE',cwd:'$PRIMARY',woId:'wo-2',metadata:{}});process.stdout.write(JSON.stringify(r));});\";
      const p = spawn(process.execPath, ['--input-type=module','-e', code], { encoding: 'utf8' });
      let out=''; p.stdout.on('data', d => out += d);
      p.on('close', () => resolve(out));
    });
    Promise.all([run(), run()]).then((results) => {
      process.stdout.write(JSON.stringify(results));
    });
  });
" > "$ROOT/conc2.json"
WINS=$(node -e "
  const arr = JSON.parse(require('fs').readFileSync('$ROOT/conc2.json','utf8'));
  let ok=0, fail=0;
  for (const s of arr) { const j=JSON.parse(s); if (j.ok) ok++; else fail++; }
  process.stdout.write(ok + ':' + fail);
")
assert_eq "$WINS" "1:1" "exactly one concurrent first-claim wins the lock"
# the winner left a valid worktree, and no stale lock remains
[ -e "$PRIMARY/.worktrees/works/wo-2/_shared/.git" ] || fail "concurrent winner did not create the worktree"
[ ! -e "$PRIMARY/.worktrees/works/wo-2/.bf-create.lock" ] || fail "stale create lock remains after concurrent claim"
rm -rf "$ROOT"

# --- validateWoWorktree (post-claim, no re-create) --------------------------

make_git_repo_with_origin
OUT=$(prepare_wo_json "$PRIMARY" "wo-1")
assert_json_field "$OUT" .ok true
WT="$PRIMARY/.worktrees/works/wo-1/_shared"
OUT=$(validate_wo_json "$PRIMARY" "wo-1" "bf/wo-1" "$WT")
assert_json_field "$OUT" .ok true
assert_json_field "$OUT" .branch "bf/wo-1"
# branch metadata conflict (hand-edited) is rejected
OUT=$(validate_wo_json "$PRIMARY" "wo-1" "bf/wrong" "$WT")
assert_json_field "$OUT" .ok false
assert_match "$OUT" "conflict" "validateWoWorktree rejects branch metadata conflict"
rm -rf "$ROOT"

pass
