#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

# 已有 Updated 字段：替换
WITH=$(printf -- '---\nId: x\nState: Draft\nUpdated: 2020-01-01 00:00\n---\n')
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    process.stdout.write(m.writeUpdated(process.argv[1], '2026-05-19 12:34'));
  });
" -- "$WITH")
assert_match "$STDOUT" "Updated: 2026-05-19 12:34" "updated replaced"
assert_not_match "$STDOUT" "2020-01-01" "old value removed"

# 没 Updated 字段：插入
WITHOUT=$(printf -- '---\nId: x\nState: Draft\n---\n# body\n')
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    process.stdout.write(m.writeUpdated(process.argv[1], '2026-05-19 12:34'));
  });
" -- "$WITHOUT")
assert_match "$STDOUT" "Updated: 2026-05-19 12:34" "updated inserted"
assert_match "$STDOUT" "# body" "body preserved"

# formatTimestamp 格式
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    process.stdout.write(m.formatTimestamp(new Date(2026, 4, 19, 9, 5)));
  });
")
assert_eq "$STDOUT" "2026-05-19 09:05" "timestamp padded"

pass
