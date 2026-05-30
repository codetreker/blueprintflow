#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
  cp -R "$FIXTURES/clean-wo" "$BASE/wo-1"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

write_clean_review() {
  local dir="$1" role="$2" idx="$3"
  mkdir -p "$dir"
  cat > "$dir/result_${role}_${idx}.md" <<'EOF'
# Desc

clean review

## Results

### Blocker
### High
### Minor
### Nit

## Accepted Criteria

- AC-1: bf-level criterion clean
EOF
}

write_blocker_review() {
  local dir="$1" role="$2" idx="$3"
  mkdir -p "$dir"
  cat > "$dir/result_${role}_${idx}.md" <<'EOF'
# Desc

## Results

### Blocker

- bf.md:20 范围越界

### High
### Minor
### Nit

## Accepted Criteria
EOF
}

run_verify() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
      })));
    });
  ")
}

# Spec Review SUCCESS（state=Draft + clean review）
setup
write_clean_review "$BASE/wo-1/runs/reviews/round_1" tester 1
run_verify
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .status "SUCCESS"
assert_json_field "$STDOUT" .mode "Spec Review"
RESULT_FILE="$BASE/wo-1/runs/reviews/round_1/verify-result.md"
[ -f "$RESULT_FILE" ] || fail "verify-result.md missing"
grep -q "^Result: SUCCESS" "$RESULT_FILE" || fail "Result field"
grep -q "^Mode: Spec Review" "$RESULT_FILE" || fail "Mode field"
if grep -q "## Issues" "$RESULT_FILE"; then fail "SUCCESS should NOT have Issues section"; fi
grep -q "^State: Draft" "$BASE/wo-1/bf.md" || fail "bf.md State changed (should not)"
cleanup

# Spec Review FAIL（Blocker）
setup
write_blocker_review "$BASE/wo-1/runs/reviews/round_1" tester 1
run_verify
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$BASE/wo-1/runs/reviews/round_1/verify-result.md"
grep -q "^Result: FAIL" "$RESULT_FILE" || fail "FAIL not recorded"
grep -q "范围越界" "$RESULT_FILE" || fail "blocker not propagated"
cleanup

# Spec Review with an empty round must FAIL and produce a verify-result.
setup
mkdir -p "$BASE/wo-1/runs/reviews/round_1"
run_verify
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .status "FAIL"
assert_json_field "$STDOUT" .mode "Spec Review"
RESULT_FILE="$BASE/wo-1/runs/reviews/round_1/verify-result.md"
[ -f "$RESULT_FILE" ] || fail "empty-round verify-result.md missing"
grep -q "no result files in round" "$RESULT_FILE" || fail "empty round issue not recorded"
cleanup

# Spec Review 没 round → ok:false + error 含 "no review round"，**不创建 round_1 目录**
setup
run_verify
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "no review round" "no-round error message"
if [ -d "$BASE/wo-1/runs/reviews/round_1" ]; then
  fail "phantom round_1 was created"
fi
cleanup

# CLI-level: bf-harness verify SUCCESS path emits `SUCCESS <abs-path>` on
# stdout line 1 with exit 0. Format-verify regression coverage — round 2
# extracted the SUCCESS/FAIL prefix into the formatter; this assertion
# catches a mutation that strips it.
setup
write_clean_review "$BASE/wo-1/runs/reviews/round_1" tester 1
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh verify "wo-1"
assert_eq "$RC" "0" "verify SUCCESS exit 0"
assert_eq "$STDERR" "" "verify SUCCESS stderr empty"
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
case "$FIRST_LINE" in
  "SUCCESS "*) ;;
  *) fail "verify stdout line 1 does not start with 'SUCCESS ': got '$FIRST_LINE'" ;;
esac
case "$FIRST_LINE" in
  *"/runs/reviews/round_1/verify-result.md") ;;
  *) fail "verify stdout does not end with verify-result.md path: got '$FIRST_LINE'" ;;
esac
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in verify stdout"
unset BF_HOME BF_INSTALL_DIR
cleanup

# CLI-level: bf-harness verify FAIL path emits `FAIL <abs-path>` on stdout
# line 1 with exit 1.
setup
write_blocker_review "$BASE/wo-1/runs/reviews/round_1" tester 1
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh verify "wo-1"
assert_eq "$RC" "1" "verify FAIL exit 1"
assert_eq "$STDERR" "" "verify FAIL stderr empty"
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
case "$FIRST_LINE" in
  "FAIL "*) ;;
  *) fail "verify stdout line 1 does not start with 'FAIL ': got '$FIRST_LINE'" ;;
esac
unset BF_HOME BF_INSTALL_DIR
cleanup

pass
