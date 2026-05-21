#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(cat <<'EOF'
---
Id: engineering
Desc: 软件工程类工作
---

## When to Use

写代码、改 bug、加 feature 都走这个 pack。

## Brainstorm Guidance

问清楚用户/性能/安全约束。
EOF
)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/parse-pack.mjs').then(m => {
    process.stdout.write(JSON.stringify(m.parsePack(process.argv[1])));
  });
" -- "$INPUT")
assert_json_field "$STDOUT" .id "engineering"
assert_match "$STDOUT" "写代码" "whenToUse content present"
assert_match "$STDOUT" "brainstormGuidance" "optional section included"

# 缺 When to Use
BAD=$(cat <<'EOF'
---
Id: bad
Desc: 没 When to Use
---

## Brainstorm Guidance
oops
EOF
)
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/parse-pack.mjs').then(m => {
    try { m.parsePack(process.argv[1]); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BAD")
assert_match "$OUT" "When to Use" "missing whenToUse"

pass
