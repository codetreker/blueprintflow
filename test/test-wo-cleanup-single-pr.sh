#!/usr/bin/env bash
# Mode B (single-pr) P4 — WO-SCOPE CLEANUP.
#
# WO-scope cleanup (cleanup <bf-wo>) removes the ONE shared worktree
# (<primary>/.worktrees/works/<wo>/_shared) + deletes the shared branch bf/<wo>,
# but ONLY after bf.md.State === "Completed" AND the WO PR is merged. Before
# either condition holds it refuses fail-closed and retains the shared resources
# (other tasks' commits live on the shared branch until the WO PR merges).
#
# Real git fixtures with a real (bare) origin so push / branch -d / PR lookup are
# genuine. The GitHub PR lookup is mocked the SAME way the github-pr-gate tests
# do: a fake `gh` on PATH driven by GH_FAKE_MODE.
set -u
source "$(dirname "$0")/test-helpers.sh"

INSTALL="$REPO_ROOT"

make_repo() {
  ROOT=$(make_temp_home)
  ORIGIN="$ROOT/origin.git"
  SEED="$ROOT/seed"
  PRIMARY="$ROOT/primary"
  git init -q --bare "$ORIGIN" || fail "bare init failed"
  git -C "$ORIGIN" symbolic-ref HEAD refs/heads/main
  git init -q -b main "$SEED" || fail "seed init failed"
  git -C "$SEED" config user.email t@e.com; git -C "$SEED" config user.name t
  printf "root\n" > "$SEED/README.md"
  git -C "$SEED" add README.md; git -C "$SEED" commit -qm init
  git -C "$SEED" remote add origin "$ORIGIN"
  git -C "$SEED" push -qu origin main || fail "seed push failed"
  git clone -q "$ORIGIN" "$PRIMARY" || fail "clone failed"
  git -C "$PRIMARY" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  git -C "$PRIMARY" config user.email t@e.com; git -C "$PRIMARY" config user.name t
  BASE="$PRIMARY/.bf"
  mkdir -p "$BASE/works"
  WT="$PRIMARY/.worktrees/works/wo-1/_shared"
  SHARED_BRANCH="bf/wo-1"
  WO_PR="https://github.com/example/repo/pull/9"
}

make_shared_worktree() {
  node --input-type=module -e "
    import('$INSTALL/bin/lib/harness/managed-git.mjs').then(m=>{
      const r=m.prepareWoWorktree({baseHome:'$BASE',cwd:'$PRIMARY',woId:'wo-1',metadata:{}});
      if(!r.ok){process.stderr.write(r.error);process.exit(1);}
    });
  " || fail "prepareWoWorktree failed"
}

commit_task() {
  local tid="$1" file="$2" content="$3"
  printf '%s\n' "$content" > "$WT/$file"
  git -C "$WT" add "$file"
  git -C "$WT" commit -qm "$tid impl

BF-Task: wo-1/$tid"
}

push_shared() { git -C "$WT" push -qu origin bf/wo-1 || fail "push bf/wo-1 failed"; }
to_github_origin() { git -C "$PRIMARY" remote set-url origin "https://github.com/example/repo.git"; }

make_fake_gh() {
  FAKE="$ROOT/fake-bin"; mkdir -p "$FAKE"
  cat > "$FAKE/gh" <<'EOF'
#!/usr/bin/env bash
case "${GH_FAKE_MODE:-merged}" in
  open)   printf '{"mergedAt":null,"state":"OPEN","headRefName":"bf/wo-1","url":"%s"}\n' "$3" ;;
  merged) printf '{"mergedAt":"2026-06-11T19:00:00Z","state":"MERGED","headRefName":"bf/wo-1","url":"%s"}\n' "$3" ;;
  *) echo "unknown GH_FAKE_MODE" >&2; exit 2 ;;
esac
EOF
  chmod +x "$FAKE/gh"
}

# Write a single-pr bf.md. $1 = State, $2 = Pull-Request value.
write_bf() {
  local state="$1" pr="${2:-}"
  mkdir -p "$BASE/works/wo-1"
  cat > "$BASE/works/wo-1/bf.md" <<EOF
---
Id: wo-1
Desc: t
Pack: engineering
State: $state
Integration: single-pr
Mode-Lock: single-pr
Pull-Request: $pr
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Goal

g

## Acceptance Criteria

- [x] AC-1|quality-assurance: x

## Task List

- task-a
EOF
}

# A single Completed worktree task whose Branch/Worktree match the shared tuple.
write_task() {
  mkdir -p "$BASE/works/wo-1/task-a"
  cat > "$BASE/works/wo-1/task-a/spec.md" <<EOF
---
State: Completed
Pipeline: feature
Pack: engineering
Desc: task A
Requires-Worktree: true
Branch: bf/wo-1
Worktree: $WT
Pull-Request:
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Task

A.

## Requirements

- do

## Acceptance Criteria

- [x] AC-1|quality-assurance: ok

## Evidence

- EV-1|AC-1|review-note: signed

## Boundary

none.
EOF
}

# Drive WO-scope cleanup via the real CLI from the primary worktree.
run_wo_cleanup_cli() {
  STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" PATH="$FAKE:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node "$BFH" cleanup "wo-1" 2>"$ROOT/c.err"); RC=$?
  STDERR=$(cat "$ROOT/c.err" 2>/dev/null || true)
}

shared_exists() { [ -e "$WT" ]; }
shared_branch_exists() { git -C "$PRIMARY" show-ref --verify "refs/heads/$SHARED_BRANCH" >/dev/null 2>&1; }

# --- Refuse before Completed: bf.md still Implementing => retain everything ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf Implementing "$WO_PR"
write_task
GH_FAKE_MODE=merged run_wo_cleanup_cli
assert_eq "$RC" "1" "WO cleanup refuses while Implementing"
assert_match "$STDOUT" "requires bf.md State: Completed" "WO cleanup not-Completed message"
shared_exists || fail "WO cleanup destroyed shared worktree before Completed"
shared_branch_exists || fail "WO cleanup deleted shared branch before Completed"
rm -rf "$ROOT"

# --- Refuse when the WO PR is not merged: Completed + open PR => retain ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf Completed "$WO_PR"
write_task
GH_FAKE_MODE=open run_wo_cleanup_cli
assert_eq "$RC" "1" "WO cleanup refuses while WO PR is unmerged"
assert_match "$STDOUT" "requires the WO PR to be merged" "WO cleanup unmerged-PR message"
shared_exists || fail "WO cleanup destroyed shared worktree before WO PR merged"
shared_branch_exists || fail "WO cleanup deleted shared branch before WO PR merged"
rm -rf "$ROOT"

# --- Refuse when bf.md has no WO PR at all (Completed, empty Pull-Request) ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf Completed ""
write_task
GH_FAKE_MODE=merged run_wo_cleanup_cli
assert_eq "$RC" "1" "WO cleanup refuses without a WO PR"
assert_match "$STDOUT" "missing the WO-level Pull-Request" "WO cleanup missing-PR message"
shared_exists || fail "WO cleanup destroyed shared worktree without a WO PR"
shared_branch_exists || fail "WO cleanup deleted shared branch without a WO PR"
rm -rf "$ROOT"

# --- Removes the shared worktree + branch when Completed AND WO PR merged ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared
# Simulate the merge into origin/main so `git branch -d bf/wo-1` is safe locally.
git -C "$PRIMARY" fetch -q origin
git -C "$PRIMARY" push -q origin "bf/wo-1:main" || fail "merge bf/wo-1 into origin main failed"
git -C "$PRIMARY" fetch -q origin
to_github_origin
write_bf Completed "$WO_PR"
write_task
GH_FAKE_MODE=merged run_wo_cleanup_cli
assert_eq "$RC" "0" "WO cleanup succeeds when Completed + WO PR merged"
assert_match "$STDOUT" "Removed worktree: $WT" "WO cleanup removed shared worktree"
assert_match "$STDOUT" "Deleted branch: $SHARED_BRANCH" "WO cleanup deleted shared branch"
shared_exists && fail "WO cleanup left the shared worktree" || true
shared_branch_exists && fail "WO cleanup left the shared branch" || true
rm -rf "$ROOT"

# --- Recompute-never-trust: hand-edited Branch metadata is rejected ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf Completed "$WO_PR"
write_task
sed -i.bak 's#^Branch: .*#Branch: attacker/branch#' "$BASE/works/wo-1/task-a/spec.md"
GH_FAKE_MODE=merged run_wo_cleanup_cli
assert_eq "$RC" "1" "WO cleanup rejects hand-edited Branch metadata"
assert_match "$STDOUT" "conflict" "WO cleanup recompute-rejected message"
shared_exists || fail "WO cleanup destroyed shared worktree on metadata conflict"
shared_branch_exists || fail "WO cleanup deleted shared branch on metadata conflict"
rm -rf "$ROOT"

# --- No worktree-required task => nothing to clean (success, no-op) ---
make_repo; make_fake_gh
write_bf Completed "$WO_PR"
mkdir -p "$BASE/works/wo-1/task-a"
cat > "$BASE/works/wo-1/task-a/spec.md" <<EOF
---
State: Completed
Pipeline: feature
Pack: engineering
Desc: task A
Requires-Worktree: false
Branch:
Worktree:
Pull-Request:
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Task

A.

## Requirements

- do

## Acceptance Criteria

- [x] AC-1|quality-assurance: ok

## Evidence

- EV-1|AC-1|review-note: signed

## Boundary

none.
EOF
GH_FAKE_MODE=merged run_wo_cleanup_cli
assert_eq "$RC" "0" "WO cleanup is a no-op when no task needs a worktree"
assert_match "$STDOUT" "No harness-owned task worktrees to clean" "WO cleanup no-op message"
rm -rf "$ROOT"

pass
