#!/usr/bin/env bash
# Mode B (single-pr) P3 — ADVERSARIAL FAIL-CLOSED MATRIX.
#
# Covers EVERY forge/bypass vector in the Mode B research report:
#   §2.1 (task-done commit-presence gate, vectors 1-10)
#   §2.2 (WO-final merged-PR gate, vectors W1-W6)
# Plus the resolved 5.2 anti-revert clause and a regression that FAILS if the
# WO-final gate is not invoked in completeWorkObject.
#
# Real git fixtures with a real origin (bare) so origin-ancestry / push / merge-base
# are genuine. The GitHub PR lookup is mocked the SAME way the existing
# github-pr-gate tests do: a fake `gh` on PATH driven by GH_FAKE_MODE.
#
# Fixture order is load-bearing: we push task commits to the LOCAL BARE while
# origin URL is the bare path, THEN swap origin URL to a github.com URL (the
# remote-tracking ref survives the swap) so the repo-slug + gh PR clauses engage
# while clause (2)'s origin ancestry reads the already-mirrored ref.
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

# commit_task <taskId> <file> <content>  — commit with a BF-Task trailer on bf/wo-1.
commit_task() {
  local tid="$1" file="$2" content="$3"
  printf '%s\n' "$content" > "$WT/$file"
  git -C "$WT" add "$file"
  git -C "$WT" commit -qm "$tid impl

BF-Task: wo-1/$tid"
}

commit_empty_task() {
  local tid="$1"
  git -C "$WT" commit -q --allow-empty -m "$tid empty

BF-Task: wo-1/$tid"
}

push_shared() { git -C "$WT" push -q origin bf/wo-1 || fail "push bf/wo-1 failed"; }

# After commits are pushed to the bare, swap origin URL to github so the repo-slug
# + gh PR clauses engage. The remote-tracking ref survives the URL swap.
to_github_origin() { git -C "$PRIMARY" remote set-url origin "https://github.com/example/repo.git"; }
to_bare_origin()   { git -C "$PRIMARY" remote set-url origin "$ORIGIN"; }

write_bf() {
  # $1 = Pull-Request value (may be empty)
  local pr="${1:-}"
  mkdir -p "$BASE/works/wo-1"
  cat > "$BASE/works/wo-1/bf.md" <<EOF
---
Id: wo-1
Desc: t
Pack: engineering
State: Implementing
Integration: single-pr
Mode-Lock: single-pr
Pull-Request: $pr
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Goal

g

## Acceptance Criteria

- [ ] AC-1|quality-assurance: x

## Task List

- task-a
EOF
}

make_fake_gh() {
  FAKE="$ROOT/fake-bin"; mkdir -p "$FAKE"
  cat > "$FAKE/gh" <<'EOF'
#!/usr/bin/env bash
case "${GH_FAKE_MODE:-open}" in
  open)          printf '{"mergedAt":null,"state":"OPEN","headRefName":"bf/wo-1","url":"%s"}\n' "$3" ;;
  merged)        printf '{"mergedAt":"2026-06-09T19:00:00Z","state":"MERGED","headRefName":"bf/wo-1","url":"%s"}\n' "$3" ;;
  merged-other)  printf '{"mergedAt":"2026-06-09T19:00:00Z","state":"MERGED","headRefName":"some-other-branch","url":"%s"}\n' "$3" ;;
  open-other)    printf '{"mergedAt":null,"state":"OPEN","headRefName":"bf/other","url":"%s"}\n' "$3" ;;
  error)         echo "gh auth failed" >&2; exit 1 ;;
  *) echo "unknown GH_FAKE_MODE" >&2; exit 2 ;;
esac
EOF
  chmod +x "$FAKE/gh"
}

# Drive the commit-presence gate for a given task id.
presence_gate() {
  local tid="$1"
  STDOUT=$(PATH="$FAKE:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-open}" node --input-type=module -e "
    const g=await import('$INSTALL/bin/lib/harness/commit-presence-gate.mjs');
    const lw=await import('$INSTALL/bin/lib/harness/load-wo.mjs');
    const b=await lw.loadWo({baseHome:'$BASE',woId:'wo-1',installDir:'$INSTALL'});
    const task={ spec:{ requiresWorktree:true, executionMetadata:{ branch:'bf/wo-1', worktree:'$WT' } }, __bf:b.bf };
    const r=g.checkTaskCommitPresenceGate(task,{ baseHome:'$BASE', cwd:'$PRIMARY', woId:'wo-1', taskId:'$tid' });
    process.stdout.write(JSON.stringify(r));
  ")
}

# Drive the WO-final merged-PR gate (parameterized github-pr-gate, branchMode:wo).
wo_gate() {
  STDOUT=$(PATH="$FAKE:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node --input-type=module -e "
    const g=await import('$INSTALL/bin/lib/harness/github-pr-gate.mjs');
    const lw=await import('$INSTALL/bin/lib/harness/load-wo.mjs');
    const b=await lw.loadWo({baseHome:'$BASE',woId:'wo-1',installDir:'$INSTALL'});
    const task={ spec:{ requiresWorktree:true, executionMetadata:{ branch:'bf/wo-1', worktree:'$WT' } } };
    const r=g.checkGitHubPrMergedGate(task,{ baseHome:'$BASE', cwd:'$PRIMARY', woId:'wo-1', taskId:'task-a', branchMode:'wo', bf:b.bf });
    process.stdout.write(JSON.stringify(r));
  ")
}

echo "running adversarial matrix..." >&2

# =====================================================================
# §2.1 — Task-Done commit-presence gate (vectors 1-10)
# =====================================================================

# --- Happy path baseline: pushed, real diff, open WO PR => PASS ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-a
assert_json_field "$STDOUT" .ok true "baseline: genuine pushed task commit with open WO PR passes"
rm -rf "$ROOT"

# --- Vector 1: missing commit (no BF-Task trailer exists for this task) ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-b   # task-b has no commit/trailer
assert_json_field "$STDOUT" .ok false "V1 missing trailer fails closed"
assert_match "$STDOUT" "no commit carrying trailer" "V1 message"
rm -rf "$ROOT"

# --- Vector 2: forged local-only commit (new SHA, never pushed) ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared
commit_task task-c c.txt "forged local-only"   # NOT pushed
to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-c
assert_json_field "$STDOUT" .ok false "V2 local-only forged commit fails origin ancestry"
assert_match "$STDOUT" "not pushed" "V2 message"
rm -rf "$ROOT"

# --- Vector 3: empty/placeholder commit with a valid trailer ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
commit_empty_task task-d
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-d
assert_json_field "$STDOUT" .ok false "V3 empty-diff commit fails closed"
assert_match "$STDOUT" "empty diff" "V3 message"
rm -rf "$ROOT"

# --- Vector 4: reverted commit (anti-revert clause 5, resolved 5.2) ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
TASKA=$(git -C "$WT" rev-parse HEAD)
# A LEGITIMATELY-STACKED later task whose SUBJECT merely mentions "revert" must
# NOT trip the anti-revert clause (stacking-compatible).
printf 'b\n' > "$WT/b.txt"; git -C "$WT" add b.txt
git -C "$WT" commit -qm "task-b: revert the temporary stub naming

BF-Task: wo-1/task-b"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-a
assert_json_field "$STDOUT" .ok true "V4 stacking-compat: a later commit mentioning 'revert' does NOT trip clause 5"
# Now an HONEST git revert of task-a must FAIL closed.
to_bare_origin
git -C "$WT" revert --no-edit "$TASKA" >/dev/null 2>&1 || fail "git revert task-a failed"
push_shared; to_github_origin
GH_FAKE_MODE=open presence_gate task-a
assert_json_field "$STDOUT" .ok false "V4 anti-revert: an honest git revert of the task commit fails closed"
assert_match "$STDOUT" "was reverted" "V4 message"
rm -rf "$ROOT"

# --- Vector 5: trailer for the wrong wo/task (mis-scoped) ---
make_repo; make_shared_worktree; make_fake_gh
# commit carries BF-Task: wo-1/task-z (wrong task), asked to complete task-a
printf 'z\n' > "$WT/z.txt"; git -C "$WT" add z.txt
git -C "$WT" commit -qm "mis-scoped

BF-Task: wo-1/task-z"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-a
assert_json_field "$STDOUT" .ok false "V5 mis-scoped (wrong task) trailer cannot satisfy task-a"
rm -rf "$ROOT"
# wrong-wo trailer likewise cannot satisfy
make_repo; make_shared_worktree; make_fake_gh
printf 'w\n' > "$WT/w.txt"; git -C "$WT" add w.txt
git -C "$WT" commit -qm "wrong wo

BF-Task: wo-OTHER/task-a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-a
assert_json_field "$STDOUT" .ok false "V5 mis-scoped (wrong wo) trailer cannot satisfy task-a"
rm -rf "$ROOT"

# --- Vector 6: cherry-pick/rebase mishap — trailer on an unreachable commit ---
# A commit on a detached side branch (never merged into bf/wo-1) is not in range.
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared
# create a side commit carrying task-e off origin/HEAD, never merged into bf/wo-1
git -C "$PRIMARY" worktree add -q "$ROOT/side" -b side origin/main
printf 'e\n' > "$ROOT/side/e.txt"; git -C "$ROOT/side" add e.txt
git -C "$ROOT/side" commit -qm "stray

BF-Task: wo-1/task-e"
to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-e
assert_json_field "$STDOUT" .ok false "V6 trailer on an unreachable (non-bf/wo-1) commit fails closed"
rm -rf "$ROOT"

# --- Vector 7: premature WO-PR merge at task-done (merged===true => FAIL) ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=merged presence_gate task-a
assert_json_field "$STDOUT" .ok false "V7 premature WO-PR merge at task-done fails closed"
assert_match "$STDOUT" "already merged" "V7 message"
rm -rf "$ROOT"

# --- Vector 8: force-push removes the commit from origin ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared
# force-push origin/bf/wo-1 back to a state WITHOUT the task-a commit
git -C "$WT" push -qf origin "origin/main:bf/wo-1" 2>/dev/null || git -C "$PRIMARY" push -qf origin "refs/remotes/origin/main:refs/heads/bf/wo-1"
git -C "$PRIMARY" fetch -q origin
to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open presence_gate task-a
assert_json_field "$STDOUT" .ok false "V8 force-push removing the commit from origin fails closed"
rm -rf "$ROOT"

# --- Vector 9: WO PR points at a different branch (headRefName mismatch) ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open-other presence_gate task-a
assert_json_field "$STDOUT" .ok false "V9 WO PR head-branch mismatch fails closed"
assert_match "$STDOUT" "branch mismatch" "V9 message"
rm -rf "$ROOT"

# --- Vector 10: spec/bf hand-edited to a fake trailer field ---
# The gate recomputes trailers from `git log`, never from bf.md/spec text. A
# hand-added "BF-Task: wo-1/task-a" LINE in bf.md is irrelevant; with no real
# commit, the gate still fails closed.
make_repo; make_shared_worktree; make_fake_gh
# no task-a commit at all; forge a trailer-looking field into bf.md
write_bf "$WO_PR"
printf '\nBF-Task: wo-1/task-a\n' >> "$BASE/works/wo-1/bf.md"
# nothing pushed to bf/wo-1 beyond origin/main; create the branch ref empty-ish
to_github_origin
GH_FAKE_MODE=open presence_gate task-a
assert_json_field "$STDOUT" .ok false "V10 hand-edited spec/bf trailer is ignored; gate recomputes from git"
rm -rf "$ROOT"

# =====================================================================
# §2.2 — WO-Final merged-PR gate (vectors W1-W6), parameterized github-pr-gate
# =====================================================================

# --- W-baseline: merged WO PR on bf/wo-1, same repo => PASS ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=merged wo_gate
assert_json_field "$STDOUT" .ok true "W-baseline: merged WO PR on bf/wo-1 passes the WO-final gate"
rm -rf "$ROOT"

# --- W1: PR not actually merged => FAIL ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=open wo_gate
assert_json_field "$STDOUT" .ok false "W1 unmerged WO PR fails closed"
assert_match "$STDOUT" "not merged" "W1 message"
rm -rf "$ROOT"

# --- W2: PR on a forked/wrong repo (repo-slug mismatch) => FAIL ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "https://github.com/example/other/pull/9"
GH_FAKE_MODE=merged wo_gate
assert_json_field "$STDOUT" .ok false "W2 wrong-repo WO PR fails closed"
assert_match "$STDOUT" "same GitHub repository" "W2 message"
rm -rf "$ROOT"

# --- W3: PR head-branch mismatch (headRefName != bf/wo-1) => FAIL ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
GH_FAKE_MODE=merged-other wo_gate
assert_json_field "$STDOUT" .ok false "W3 WO PR head-branch mismatch fails closed"
assert_match "$STDOUT" "branch mismatch" "W3 message"
rm -rf "$ROOT"

# --- W4: hand-edited branch/worktree metadata => FAIL (recompute, not trust) ---
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
STDOUT=$(PATH="$FAKE:$PATH" GH_FAKE_MODE=merged node --input-type=module -e "
  const g=await import('$INSTALL/bin/lib/harness/github-pr-gate.mjs');
  const lw=await import('$INSTALL/bin/lib/harness/load-wo.mjs');
  const b=await lw.loadWo({baseHome:'$BASE',woId:'wo-1',installDir:'$INSTALL'});
  const task={ spec:{ requiresWorktree:true, executionMetadata:{ branch:'attacker/branch', worktree:'/tmp/attacker' } } };
  const r=g.checkGitHubPrMergedGate(task,{ baseHome:'$BASE', cwd:'$PRIMARY', woId:'wo-1', taskId:'task-a', branchMode:'wo', bf:b.bf });
  process.stdout.write(JSON.stringify(r));
")
assert_json_field "$STDOUT" .ok false "W4 hand-edited branch/worktree metadata fails closed"
assert_match "$STDOUT" "conflict" "W4 message recompute-rejected"
rm -rf "$ROOT"

# --- W5/R2: regression — completeWorkObject MUST invoke the WO-final gate ---
# Drive the REAL completeWorkObject for a single-pr WO whose WO PR is UNMERGED.
# If the gate is wired, completion is REJECTED. If a future edit drops the gate,
# completion would succeed and THIS test fails — pinning vector W5 (Risk R2).
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
# Build a complete single-pr WO: one Completed worktree task + WO Final Acceptance.
mkdir -p "$BASE/works/wo-1/task-a/runs/reviews/round_1"
write_bf "$WO_PR"
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
# bf.md AC must be checked for completeWorkObject
sed -i.bak 's/^- \[ \] AC-1/- [x] AC-1/' "$BASE/works/wo-1/bf.md"
# Final Acceptance SUCCESS at WO scope
mkdir -p "$BASE/works/wo-1/runs/reviews/round_1"
cat > "$BASE/works/wo-1/runs/reviews/round_1/verify-result.md" <<EOF
---
Result: SUCCESS
Mode: Final Acceptance
Scope: wo-1
Round: 1
Timestamp: 2026-06-11 10:00
---

## AC Sign-off
- AC-1: signed (by tester)
EOF
touch -d "2026-06-11 10:00:00" "$BASE/works/wo-1/bf.md" "$BASE/works/wo-1/task-a/spec.md"
touch -d "2026-06-11 10:00:30" "$BASE/works/wo-1/runs/reviews/round_1/verify-result.md"
run_wo_complete() {
  STDOUT=$(cd "$PRIMARY" && PATH="$FAKE:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-merged}" node --input-type=module -e "
    const m=await import('$INSTALL/bin/lib/harness/cmd-complete.mjs');
    process.stdout.write(JSON.stringify(await m.cmdComplete({ baseHome:'$BASE', woId:'wo-1', installDir:'$INSTALL', now:new Date('2026-06-11T10:30:00Z') })));
  ")
}
GH_FAKE_MODE=open run_wo_complete
assert_json_field "$STDOUT" .ok false "W5 completeWorkObject rejects an unmerged WO PR (gate IS invoked)"
assert_match "$STDOUT" "not merged" "W5 unmerged rejection message"
grep -q "^State: Implementing" "$BASE/works/wo-1/bf.md" || fail "W5 unmerged WO must remain Implementing"
# --- W6: with a merged WO PR, completeWorkObject succeeds -> Completed ---
GH_FAKE_MODE=merged run_wo_complete
assert_json_field "$STDOUT" .ok true "W6 merged WO PR completes the work object"
grep -q "^State: Completed" "$BASE/works/wo-1/bf.md" || fail "W6 merged WO PR did not complete"
rm -rf "$ROOT"

# =====================================================================
# Mode B completeTask integration: single-pr dispatches to commit-presence gate.
# =====================================================================
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf "$WO_PR"
mkdir -p "$BASE/works/wo-1/task-a"
cat > "$BASE/works/wo-1/task-a/spec.md" <<EOF
---
State: Tasking
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
mkdir -p "$BASE/works/wo-1/task-a/runs/reviews/round_1"
cat > "$BASE/works/wo-1/task-a/runs/reviews/round_1/verify-result.md" <<EOF
---
Result: SUCCESS
Mode: Task Verification
Scope: wo-1/task-a
Round: 1
Timestamp: 2026-06-11 10:00
---

## AC Sign-off
- AC-1: signed (by tester)
EOF
touch -d "2026-06-11 10:00:00" "$BASE/works/wo-1/task-a/spec.md"
touch -d "2026-06-11 10:00:30" "$BASE/works/wo-1/task-a/runs/reviews/round_1/verify-result.md"
run_task_complete() {
  STDOUT=$(cd "$PRIMARY" && PATH="$FAKE:$PATH" GH_FAKE_MODE="${GH_FAKE_MODE:-open}" node --input-type=module -e "
    const m=await import('$INSTALL/bin/lib/harness/cmd-complete.mjs');
    process.stdout.write(JSON.stringify(await m.cmdComplete({ baseHome:'$BASE', woId:'wo-1', taskId:'task-a', installDir:'$INSTALL', now:new Date('2026-06-11T10:30:00Z') })));
  ")
}
# task-done while WO PR is OPEN => SUCCESS (premature merge would FAIL — V7)
GH_FAKE_MODE=open run_task_complete
assert_json_field "$STDOUT" .ok true "single-pr completeTask passes the commit-presence gate (open WO PR)"
grep -q "^State: Completed" "$BASE/works/wo-1/task-a/spec.md" || fail "single-pr task did not complete"
rm -rf "$ROOT"

# =====================================================================
# Mode B attach-pr: single-pr writes the WO PR to bf.md (not the per-task spec),
# is idempotent on the same URL, and FAILS CLOSED on a different URL.
# =====================================================================
make_repo; make_shared_worktree; make_fake_gh
commit_task task-a a.txt "impl a"
push_shared; to_github_origin
write_bf ""
mkdir -p "$BASE/works/wo-1/task-a"
cat > "$BASE/works/wo-1/task-a/spec.md" <<EOF
---
State: Tasking
Pipeline: feature
Pack: engineering
Desc: A
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

- [ ] AC-1|quality-assurance: ok

## Evidence

- EV-1|AC-1|review-note: signed

## Boundary

none.
EOF
STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" PATH="$FAKE:$PATH" GH_FAKE_MODE=open node "$BFH" attach-pr "wo-1/task-a" "$WO_PR" 2>"$ROOT/a.err"); RC=$?
assert_eq "$RC" "0" "single-pr attach-pr writes the WO PR"
grep -q "^Pull-Request: $WO_PR" "$BASE/works/wo-1/bf.md" || fail "single-pr attach-pr must write bf.md WO PR"
grep -qE "^Pull-Request: .+" "$BASE/works/wo-1/task-a/spec.md" && fail "single-pr attach-pr must NOT write the per-task spec PR" || true
# idempotent on the same URL
STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" PATH="$FAKE:$PATH" GH_FAKE_MODE=open node "$BFH" attach-pr "wo-1/task-a" "$WO_PR" 2>"$ROOT/a.err"); RC=$?
assert_eq "$RC" "0" "single-pr attach-pr is idempotent on the same URL"
# fail-closed on a different URL
STDOUT=$(cd "$PRIMARY" && BF_HOME="$BASE" PATH="$FAKE:$PATH" GH_FAKE_MODE=open node "$BFH" attach-pr "wo-1/task-a" "https://github.com/example/repo/pull/10" 2>"$ROOT/a.err"); RC=$?
assert_eq "$RC" "1" "single-pr attach-pr fails closed on a different URL"
assert_match "$STDOUT" "different URL" "single-pr attach-pr re-point rejection message"
rm -rf "$ROOT"

# =====================================================================
# Mode A UNCHANGED: per-task-pr completeTask still uses the per-task merged-PR
# gate; attach-pr still writes the per-task spec. (Byte-identical behavior.)
# =====================================================================
make_repo
# Mode A fixture: per-task branch + worktree, no Integration field.
git -C "$PRIMARY" branch bf/wo-1/task-a HEAD
mkdir -p "$PRIMARY/.worktrees/works/wo-1"
git -C "$PRIMARY" worktree add -q "$PRIMARY/.worktrees/works/wo-1/task-a" bf/wo-1/task-a
make_fake_gh
TASKWT="$PRIMARY/.worktrees/works/wo-1/task-a"
mkdir -p "$BASE/works/wo-1/task-a"
cat > "$BASE/works/wo-1/bf.md" <<EOF
---
Id: wo-1
Desc: t
Pack: engineering
State: Implementing
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Goal

g

## Acceptance Criteria

- [ ] AC-1|quality-assurance: x

## Task List

- task-a
EOF
cat > "$BASE/works/wo-1/task-a/spec.md" <<EOF
---
State: Tasking
Pipeline: feature
Pack: engineering
Desc: task A
Requires-Worktree: true
Branch: bf/wo-1/task-a
Worktree: $TASKWT
Pull-Request:
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Task

A.

## Requirements

- do

## Acceptance Criteria

- [ ] AC-1|quality-assurance: ok

## Evidence

- EV-1|AC-1|review-note: signed

## Boundary

none.
EOF
mkdir -p "$BASE/works/wo-1/task-a"
# Mode A attach-pr writes Pull-Request to the per-task SPEC (not bf.md).
git -C "$PRIMARY" remote set-url origin "https://github.com/example/repo.git"
PR7="https://github.com/example/repo/pull/7"
# fake gh for per-task head bf/wo-1/task-a
cat > "$FAKE/gh" <<'EOF'
#!/usr/bin/env bash
printf '{"mergedAt":null,"state":"OPEN","headRefName":"bf/wo-1/task-a","url":"%s"}\n' "$3"
EOF
chmod +x "$FAKE/gh"
STDOUT=$(BF_HOME="$BASE" PATH="$FAKE:$PATH" node "$BFH" attach-pr "wo-1/task-a" "$PR7" 2>"$ROOT/a.err"); RC=$?
assert_eq "$RC" "0" "Mode A attach-pr unchanged: writes per-task PR"
grep -q "^Pull-Request: $PR7" "$BASE/works/wo-1/task-a/spec.md" || fail "Mode A attach-pr must write the per-task spec"
grep -q "^Pull-Request:" "$BASE/works/wo-1/bf.md" && { grep -qE "^Pull-Request: .+" "$BASE/works/wo-1/bf.md" && fail "Mode A must NOT write bf.md Pull-Request"; } || true
rm -rf "$ROOT"

pass
