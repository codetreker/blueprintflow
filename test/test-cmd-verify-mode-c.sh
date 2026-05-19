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
  # 进入 Implementing，所有 task Completed
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/projects/p/wo-1/bf.md"
  for t in task-a task-b; do
    sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/projects/p/wo-1/$t/spec.md"
    # 给 task 一个相对早的 Updated 时间戳，方便 mode C 判 round 新鲜
    sed -i.bak 's/^Updated: .*/Updated: 2026-05-19 10:00/' "$BASE/projects/p/wo-1/$t/spec.md"
  done
  rm -f "$BASE/projects/p/wo-1"/*.bak "$BASE/projects/p/wo-1"/*/*.bak
}
cleanup() { rm -rf "$REPO" "$BASE"; }

write_signed_review() {
  local dir="$1" role="$2" idx="$3" ac_ids="$4"
  mkdir -p "$dir"
  {
    echo "# Desc"; echo
    echo "## Results"; echo
    echo "### Blocker"; echo "### High"; echo "### Minor"; echo "### Nit"; echo
    echo "## Accepted Criteria"; echo
    for id in $ac_ids; do echo "- $id: signed by $role"; done
  } > "$dir/result_${role}_${idx}.md"
}

run_verify_c() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', projectSlug: 'p', woId: 'wo-1', repoRoot: '$REPO',
      })));
    });
  ")
}

# SUCCESS: round 文件 mtime 晚于 task Updated → 通过 freshness gate
setup
ROUND_DIR="$BASE/projects/p/wo-1/runs/reviews/round_1"
write_signed_review "$ROUND_DIR" tester 1 "AC-1"
# 把 result 文件 mtime 设到 task Updated 之后（足够余量）
touch -d "2026-05-19 11:00" "$ROUND_DIR/result_tester_1.md"
run_verify_c
assert_json_field "$STDOUT" .status "SUCCESS"
assert_json_field "$STDOUT" .mode "C"
grep -qE "^- \[x\] AC-1\|" "$BASE/projects/p/wo-1/bf.md" || fail "bf.md AC-1 not flipped"
grep -q "^State: Completed" "$BASE/projects/p/wo-1/bf.md" || fail "bf.md not Completed"
cleanup

# FAIL: 没人签到 → missing
setup
ROUND_DIR="$BASE/projects/p/wo-1/runs/reviews/round_1"
write_signed_review "$ROUND_DIR" tester 1 ""
touch -d "2026-05-19 11:00" "$ROUND_DIR/result_tester_1.md"
run_verify_c
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$ROUND_DIR/verify-result.md"
grep -q "AC-1: missing" "$RESULT_FILE" || fail "AC-1 missing"
grep -q "^State: Implementing" "$BASE/projects/p/wo-1/bf.md" || fail "bf.md state changed on FAIL"
cleanup

# stale round（skeptic Blocker #1）：result 文件 mtime 早于 task Updated → FAIL
setup
ROUND_DIR="$BASE/projects/p/wo-1/runs/reviews/round_1"
write_signed_review "$ROUND_DIR" tester 1 "AC-1"
# mtime 设到 task Updated 之前（模拟"这一轮是 spec review 时留的"）
touch -d "2026-05-19 09:00" "$ROUND_DIR/result_tester_1.md"
# task 的 Updated 是 10:00（之前 setup 设的）
run_verify_c
assert_json_field "$STDOUT" .status "FAIL"
RESULT_FILE="$ROUND_DIR/verify-result.md"
grep -q "stale round" "$RESULT_FILE" || fail "stale round not detected"
grep -q "^State: Implementing" "$BASE/projects/p/wo-1/bf.md" || fail "bf.md state changed on stale FAIL"
cleanup

# 部分 task 未 Completed → 整套被 dispatcher 拒（phase mismatch, mode 决策不到 C）
setup
sed -i.bak 's/^State: Completed/State: Tasking/' "$BASE/projects/p/wo-1/task-b/spec.md"
rm -f "$BASE/projects/p/wo-1/task-b/spec.md.bak"
ROUND_DIR="$BASE/projects/p/wo-1/runs/reviews/round_1"
write_signed_review "$ROUND_DIR" tester 1 "AC-1"
touch -d "2026-05-19 11:00" "$ROUND_DIR/result_tester_1.md"
run_verify_c
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "phase mismatch" "task not all completed"
cleanup

pass
