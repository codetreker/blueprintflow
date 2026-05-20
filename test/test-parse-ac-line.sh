#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

run_one() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/parse-ac-line.mjs').then(m => {
      const r = m.parseAcLine(process.argv[1]);
      process.stdout.write(JSON.stringify(r));
    });
  " -- "$1")
}

# unchecked
run_one '- [ ] AC-1|quality-assurance: 用户能成功登录'
assert_json_field "$STDOUT" .id "AC-1"
assert_json_field "$STDOUT" .capability "quality-assurance"
assert_json_field "$STDOUT" .checked false
assert_json_field "$STDOUT" .text "用户能成功登录"

# checked
run_one '- [x] AC-2|security-review: 没有 PII 泄漏'
assert_json_field "$STDOUT" .checked true
assert_json_field "$STDOUT" .id "AC-2"

# 不匹配 → null
run_one '- some random bullet'
assert_eq "$STDOUT" "null" "non-AC line returns null"

# 缺 capability 段 → null
run_one '- [ ] AC-3: 没有 capability marker'
assert_eq "$STDOUT" "null" "missing capability returns null"

pass
