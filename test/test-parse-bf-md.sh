#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(cat <<'EOF'
---
Id: build-login
Desc: 实现一个登录页
Pack: engineering
State: Draft
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Goal

让用户能用 email 登录。

## Requirement

- 用户能用 email + password 登录
- session 在刷新后保持

## Acceptance Criteria

- [ ] AC-1|verification: 登录流程端到端可用
- [ ] AC-2|security-review: 密码字段不在日志里

## Boundary

不做第三方 OAuth。

## Task List

- task-build-form
- task-build-api
- task-wire-session: task-build-form, task-build-api
EOF
)

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/parse-bf-md.mjs').then(m => {
    const r = m.parseBfMd(process.argv[1]);
    process.stdout.write(JSON.stringify(r));
  });
" -- "$INPUT")

assert_json_field "$STDOUT" .frontmatter.Id "build-login"
assert_json_field "$STDOUT" .frontmatter.State "Draft"
assert_json_field "$STDOUT" .acceptanceCriteria.0.id "AC-1"
assert_json_field "$STDOUT" .acceptanceCriteria.1.capability "security-review"
assert_json_field "$STDOUT" .taskList.0.id "task-build-form"
assert_json_field "$STDOUT" .taskList.2.id "task-wire-session"
assert_json_field "$STDOUT" .taskList.2.deps '["task-build-form","task-build-api"]'
assert_json_field "$STDOUT" .requirements '["用户能用 email + password 登录","session 在刷新后保持"]'

# 缺 frontmatter 字段
BAD=$(printf -- '---\nId: x\nDesc: y\nState: Draft\n---\n# Goal\n')
STDERR=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/parse-bf-md.mjs').then(m => {
    try { m.parseBfMd(process.argv[1]); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BAD")
assert_match "$STDERR" "missing: Pack" "missing Pack field"

pass
