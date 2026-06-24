#!/usr/bin/env bash
# Mode B P1: Integration selector validation (INTEGRATION_INVALID) + accept-lock
# immutability (INTEGRATION_LOCKED). Both are surfaced through validateWo so
# `bf-harness lint` and the cmd-accept/cmd-next/cmd-complete loadWo+validateWo
# chain catch them fail-closed — not just a thrown runtime exception.
#
# 5.5 accept-lock mechanism (DECIDED): a harness-written `Mode-Lock:` frontmatter
# anchor captured at accept (alongside the State flip). Once State != Draft, the
# effective Integration mode MUST equal Mode-Lock or validation FAILs closed.
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

seed_mode_a_success() {
  local wo="$1"
  local dir="$wo/runs/reviews/round_1"
  mkdir -p "$dir"
  cat > "$dir/verify-result.md" <<'EOF'
---
Result: SUCCESS
Mode: Spec Review
Scope: clean-wo
Round: 1
Timestamp: 2026-05-19 10:00
---
EOF
}

run_validate() {
  STDOUT=$(node --input-type=module -e "
    Promise.all([
      import('$REPO_ROOT/bin/lib/harness/load-wo.mjs'),
      import('$REPO_ROOT/bin/lib/harness/validate-wo.mjs'),
    ]).then(async ([l, v]) => {
      const bundle = await l.loadWo({ baseHome: '$BASE', woId: process.argv[1], installDir: '$REPO' });
      process.stdout.write(JSON.stringify(v.validateWo(bundle)));
    });
  " "$1")
}

# --- INTEGRATION_INVALID (selector validation) -------------------------------

# absent Integration is valid (Mode A) — existing fixtures stay green
setup; copy_fixture clean-wo "$BASE/works/absent-integration-wo"
run_validate absent-integration-wo
assert_json_field "$STDOUT" .ok true
assert_not_match "$STDOUT" "INTEGRATION_INVALID" "absent Integration must not trip selector lint"
cleanup

# explicit per-task-pr is valid
setup; copy_fixture clean-wo "$BASE/works/per-task-pr-wo"
sed -i.bak '/^State: Draft$/a Integration: per-task-pr' "$BASE/works/per-task-pr-wo/bf.md"
run_validate per-task-pr-wo
assert_json_field "$STDOUT" .ok true
cleanup

# explicit single-pr is valid
setup; copy_fixture clean-wo "$BASE/works/single-pr-wo"
sed -i.bak '/^State: Draft$/a Integration: single-pr' "$BASE/works/single-pr-wo/bf.md"
run_validate single-pr-wo
assert_json_field "$STDOUT" .ok true
cleanup

# unknown Integration value FAILs lint (fail-closed, caught by bf-harness lint)
setup; copy_fixture clean-wo "$BASE/works/bad-integration-wo"
sed -i.bak '/^State: Draft$/a Integration: merge-train' "$BASE/works/bad-integration-wo/bf.md"
run_validate bad-integration-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_INVALID" "unknown Integration value rejected by lint"
assert_match "$STDOUT" "merge-train" "lint names the offending value"
cleanup

# --- INTEGRATION_LOCKED (accept-lock immutability) ---------------------------

# accept on a single-pr WO writes the Mode-Lock anchor
setup; copy_fixture clean-wo "$BASE/works/lock-write-wo"
sed -i.bak '/^State: Draft$/a Integration: single-pr' "$BASE/works/lock-write-wo/bf.md"
seed_mode_a_success "$BASE/works/lock-write-wo"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'lock-write-wo', installDir: '$REPO',
      now: new Date(2026, 4, 19, 12, 34),
    })));
  });
")
assert_json_field "$STDOUT" .ok true
grep -q "^Mode-Lock: single-pr" "$BASE/works/lock-write-wo/bf.md" || fail "accept did not write Mode-Lock anchor"
# the accepted (still-matching) WO validates clean
run_validate lock-write-wo
assert_json_field "$STDOUT" .ok true
cleanup

# accept on a Mode A (absent Integration) WO writes Mode-Lock: per-task-pr
setup; copy_fixture clean-wo "$BASE/works/lock-mode-a-wo"
seed_mode_a_success "$BASE/works/lock-mode-a-wo"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'lock-mode-a-wo', installDir: '$REPO',
      now: new Date(2026, 4, 19, 12, 34),
    })));
  });
")
assert_json_field "$STDOUT" .ok true
grep -q "^Mode-Lock: per-task-pr" "$BASE/works/lock-mode-a-wo/bf.md" || fail "Mode A accept did not anchor per-task-pr"
run_validate lock-mode-a-wo
assert_json_field "$STDOUT" .ok true
cleanup

# post-accept flip: Integration hand-edited away from the Mode-Lock anchor => REJECTED
setup; copy_fixture clean-wo "$BASE/works/flip-wo"
sed -i.bak '/^State: Draft$/a Integration: single-pr' "$BASE/works/flip-wo/bf.md"
seed_mode_a_success "$BASE/works/flip-wo"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then((m) =>
    m.cmdAccept({ baseHome: '$BASE', woId: 'flip-wo', installDir: '$REPO', now: new Date(2026, 4, 19, 12, 34) }));
" >/dev/null
# the LLM hand-edits Integration after accept (Mode-Lock stays single-pr)
sed -i.bak 's/^Integration: single-pr/Integration: per-task-pr/' "$BASE/works/flip-wo/bf.md"
run_validate flip-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_LOCKED" "post-accept Integration flip rejected"
cleanup

# post-accept flip detected even when the new value is itself a VALID mode
# (so INTEGRATION_LOCKED — not INTEGRATION_INVALID — is what fires)
setup; copy_fixture clean-wo "$BASE/works/flip-valid-wo"
seed_mode_a_success "$BASE/works/flip-valid-wo"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then((m) =>
    m.cmdAccept({ baseHome: '$BASE', woId: 'flip-valid-wo', installDir: '$REPO', now: new Date(2026, 4, 19, 12, 34) }));
" >/dev/null
# was anchored per-task-pr (Mode A); hand-edit to single-pr after accept
sed -i.bak '/^State: Accepted$/a Integration: single-pr' "$BASE/works/flip-valid-wo/bf.md"
run_validate flip-valid-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_LOCKED" "post-accept add of a valid mode flip rejected"
assert_not_match "$STDOUT" "INTEGRATION_INVALID" "flip to a valid mode is a lock violation, not invalid-value"
cleanup

# cmd-next (a mode-reading command) inherits the lock fail-closed via validateWo:
# a flipped accepted WO cannot be claimed.
setup; copy_fixture clean-wo "$BASE/works/flip-next-wo"
sed -i.bak '/^State: Draft$/a Integration: single-pr' "$BASE/works/flip-next-wo/bf.md"
seed_mode_a_success "$BASE/works/flip-next-wo"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then((m) =>
    m.cmdAccept({ baseHome: '$BASE', woId: 'flip-next-wo', installDir: '$REPO', now: new Date(2026, 4, 19, 12, 34) }));
" >/dev/null
sed -i.bak 's/^Integration: single-pr/Integration: per-task-pr/' "$BASE/works/flip-next-wo/bf.md"
run_validate flip-next-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_LOCKED" "mode-reading path sees the lock violation"
cleanup

# HARDENED (was legacy back-compat): a pre-feature accepted Mode A WO with no
# Integration AND no Mode-Lock anchor is now a LOCK VIOLATION. The missing
# harness-owned anchor was the silent single-pr->Mode-A downgrade bypass, so a
# non-Draft WO without it must FAIL closed rather than resolve to per-task-pr.
setup; copy_fixture clean-wo "$BASE/works/legacy-accepted-wo"
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/legacy-accepted-wo/bf.md"
run_validate legacy-accepted-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_LOCKED" "non-Draft WO missing Mode-Lock anchor is a lock violation"
cleanup

# migration: the same pre-feature WO validates clean once the one-time
# `Mode-Lock: per-task-pr` anchor line is added to bf.md frontmatter (this is how
# a WO accepted before Mode B v0.8.0 migrates forward).
setup; copy_fixture clean-wo "$BASE/works/legacy-migrated-wo"
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/legacy-migrated-wo/bf.md"
sed -i.bak '/^State: Accepted$/a Mode-Lock: per-task-pr' "$BASE/works/legacy-migrated-wo/bf.md"
run_validate legacy-migrated-wo
assert_json_field "$STDOUT" .ok true
assert_not_match "$STDOUT" "INTEGRATION_LOCKED" "migrated WO with per-task-pr anchor validates clean"
cleanup

# regression (anchor-deletion bypass): a single-pr WO is accepted (harness writes
# Mode-Lock: single-pr), then BOTH Integration AND Mode-Lock are hand-deleted to
# masquerade as a plain Mode A WO. This silently downgraded single-pr -> Mode A
# before the hardening; it must now FAIL closed with INTEGRATION_LOCKED.
setup; copy_fixture clean-wo "$BASE/works/anchor-deleted-wo"
sed -i.bak '/^State: Draft$/a Integration: single-pr' "$BASE/works/anchor-deleted-wo/bf.md"
seed_mode_a_success "$BASE/works/anchor-deleted-wo"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then((m) =>
    m.cmdAccept({ baseHome: '$BASE', woId: 'anchor-deleted-wo', installDir: '$REPO', now: new Date(2026, 4, 19, 12, 34) }));
" >/dev/null
grep -q "^Mode-Lock: single-pr" "$BASE/works/anchor-deleted-wo/bf.md" || fail "accept did not write Mode-Lock anchor"
# hand-delete BOTH the Integration selector and the Mode-Lock anchor
sed -i.bak '/^Integration: single-pr$/d' "$BASE/works/anchor-deleted-wo/bf.md"
sed -i.bak '/^Mode-Lock: single-pr$/d' "$BASE/works/anchor-deleted-wo/bf.md"
run_validate anchor-deleted-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_LOCKED" "deleting both Integration and Mode-Lock no longer silently downgrades to Mode A"
cleanup

# cmd-next END-TO-END: a flipped accepted WO cannot be claimed. cmd-next calls
# loadWo only (NOT validateWo), so it must enforce the lock directly via
# integrationError — otherwise the lock is fail-OPEN at runtime.
setup; copy_fixture clean-wo "$BASE/works/flip-next-cmd-wo"
sed -i.bak '/^State: Draft$/a Integration: single-pr' "$BASE/works/flip-next-cmd-wo/bf.md"
seed_mode_a_success "$BASE/works/flip-next-cmd-wo"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then((m) =>
    m.cmdAccept({ baseHome: '$BASE', woId: 'flip-next-cmd-wo', installDir: '$REPO', now: new Date(2026, 4, 19, 12, 34) }));
" >/dev/null
sed -i.bak 's/^Integration: single-pr/Integration: per-task-pr/' "$BASE/works/flip-next-cmd-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdNext({
      baseHome: '$BASE', woId: 'flip-next-cmd-wo', installDir: '$REPO',
      now: new Date(2026, 4, 19, 12, 34), cwd: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_LOCKED" "cmd-next itself rejects a flipped accepted WO (runtime lock, not just lint)"
cleanup

# cmd-complete END-TO-END: a flipped accepted WO cannot complete. Same reason —
# cmd-complete calls loadWo only and must enforce the lock directly.
setup; copy_fixture clean-wo "$BASE/works/flip-complete-cmd-wo"
sed -i.bak '/^State: Draft$/a Integration: single-pr' "$BASE/works/flip-complete-cmd-wo/bf.md"
seed_mode_a_success "$BASE/works/flip-complete-cmd-wo"
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then((m) =>
    m.cmdAccept({ baseHome: '$BASE', woId: 'flip-complete-cmd-wo', installDir: '$REPO', now: new Date(2026, 4, 19, 12, 34) }));
" >/dev/null
sed -i.bak 's/^Integration: single-pr/Integration: per-task-pr/' "$BASE/works/flip-complete-cmd-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-complete.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdComplete({
      baseHome: '$BASE', woId: 'flip-complete-cmd-wo', installDir: '$REPO',
      now: new Date(2026, 4, 19, 12, 34), cwd: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "INTEGRATION_LOCKED" "cmd-complete itself rejects a flipped accepted WO (runtime lock, not just lint)"
cleanup

pass
