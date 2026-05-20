#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(cat <<'EOF'
---
State: Draft
Capability: software-implementation
Pack: engineering
Desc: 实现登录 API
Creation: 2026-05-19 10:00
Updated: 2026-05-19 10:00
---

# Task

实现 POST /login。

## Requirements

- 接受 email + password
- 返回 session token

## Acceptance Criteria

- [ ] AC-1|quality-assurance: 正确凭证返回 200
- [ ] AC-2|security-review: 错误凭证不暴露用户存在性

## Boundary

不做 rate limit。
EOF
)

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/parse-task-spec.mjs').then(m => {
    const r = m.parseTaskSpec(process.argv[1]);
    process.stdout.write(JSON.stringify(r));
  });
" -- "$INPUT")

assert_json_field "$STDOUT" .frontmatter.Capability "software-implementation"
assert_json_field "$STDOUT" .frontmatter.State "Draft"
assert_json_field "$STDOUT" .acceptanceCriteria.0.capability "quality-assurance"
assert_json_field "$STDOUT" .acceptanceCriteria.1.capability "security-review"

# 缺 Capability
BAD=$(printf -- '---\nState: Draft\nPack: x\nDesc: y\n---\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/parse-task-spec.mjs').then(m => {
    try { m.parseTaskSpec(process.argv[1]); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BAD")
assert_match "$OUT" "missing: Capability" "missing Capability"

pass
