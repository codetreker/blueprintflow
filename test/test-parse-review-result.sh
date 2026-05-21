#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(cat <<'EOF'
# Desc

review task-build-api, round 1.

## Results

### Blocker

- src/api.mjs:23 没做密码哈希

### High

### Minor

- 注释里有个 typo

### Nit

## Accepted Criteria

- AC-1: 接口返回 200
- AC-2: 错误码符合 spec
EOF
)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/parse-review-result.mjs').then(m => {
    process.stdout.write(JSON.stringify(m.parseReviewResult(process.argv[1])));
  });
" -- "$INPUT")

assert_json_field "$STDOUT" .severities.blocker '["src/api.mjs:23 没做密码哈希"]'
assert_json_field "$STDOUT" .severities.high '[]'
assert_json_field "$STDOUT" .severities.minor '["注释里有个 typo"]'
assert_json_field "$STDOUT" .acceptedIds '["AC-1","AC-2"]'
assert_match "$STDOUT" "round 1" "desc captured"

# 空 review（无问题，无签到）
EMPTY=$(cat <<'EOF'
# Desc

empty review

## Results

### Blocker
### High
### Minor
### Nit

## Accepted Criteria
EOF
)
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/parse-review-result.mjs').then(m => {
    process.stdout.write(JSON.stringify(m.parseReviewResult(process.argv[1])));
  });
" -- "$EMPTY")
assert_json_field "$OUT" .severities.blocker '[]'
assert_json_field "$OUT" .acceptedIds '[]'

pass
