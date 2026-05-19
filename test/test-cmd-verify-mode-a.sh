#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE/projects/p"
  cp -R "$FIXTURES/clean-wo" "$BASE/projects/p/wo-1"
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
    import('$REPO_ROOT/bin/lib/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', projectSlug: 'p', woId: 'wo-1', repoRoot: '$REPO',
      })));
    });
  ")
}

# Mode A SUCCESS（state=Draft + clean review）
setup
write_clean_review "$BASE/projects/p/wo-1/runs/reviews/round_1" tester 1
run_verify
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .status "SUCCESS"
assert_json_field "$STDOUT" .mode "A"
RESULT_FILE="$BASE/projects/p/wo-1/runs/reviews/round_1/verify-result.md"
[ -f "$RESULT_FILE" ] || fail "verify-result.md missing"
grep -q "^Result: SUCCESS" "$RESULT_FILE" || fail "Result field"
grep -q "^Mode: A" "$RESULT_FILE" || fail "Mode field"
if grep -q "## Issues" "$RESULT_FILE"; then fail "SUCCESS should NOT have Issues section"; fi
grep -q "^State: Draft" "$BASE/projects/p/wo-1/bf.md" || fail "bf.md State changed (should not)"
cleanup

# Mode A FAIL（Blocker）
setup
write_blocker_review "$BASE/projects/p/wo-1/runs/reviews/round_1" tester 1
run_verify
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$BASE/projects/p/wo-1/runs/reviews/round_1/verify-result.md"
grep -q "^Result: FAIL" "$RESULT_FILE" || fail "FAIL not recorded"
grep -q "范围越界" "$RESULT_FILE" || fail "blocker not propagated"
cleanup

# Mode A 没 round → ok:false + error 含 "no review round"，**不创建 round_1 目录**
setup
run_verify
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "no review round" "no-round error message"
if [ -d "$BASE/projects/p/wo-1/runs/reviews/round_1" ]; then
  fail "phantom round_1 was created"
fi
cleanup

pass
