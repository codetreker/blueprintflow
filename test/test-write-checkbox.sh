#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(cat <<'EOF'
## Acceptance Criteria

- [ ] AC-1|quality-assurance: 一
- [ ] AC-2|security: 二
- [x] AC-3|quality-assurance: 已签到
EOF
)

# flip AC-1
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-checkbox.mjs').then(m => {
    process.stdout.write(m.flipCheckbox(process.argv[1], 'AC-1'));
  });
" -- "$INPUT")
assert_match "$STDOUT" "- [x] AC-1|quality-assurance" "AC-1 flipped"
assert_match "$STDOUT" "- [ ] AC-2|security" "AC-2 untouched"

# flip AC-3（已 checked）→ 幂等
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-checkbox.mjs').then(m => {
    process.stdout.write(m.flipCheckbox(process.argv[1], 'AC-3'));
  });
" -- "$INPUT")
assert_match "$STDOUT" "- [x] AC-3|quality-assurance" "AC-3 idempotent"

# 不存在的 id → 抛错
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-checkbox.mjs').then(m => {
    try { m.flipCheckbox(process.argv[1], 'AC-99'); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$INPUT")
assert_match "$OUT" "AC id not found" "missing id throws"

pass
