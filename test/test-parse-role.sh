#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(cat <<'EOF'
---
Id: tester
Desc: QA reviewer
Capabilities:
  - quality-assurance
  - test-design
---

# Tester

## Identity
...
EOF
)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/parse-role.mjs').then(m => {
    process.stdout.write(JSON.stringify(m.parseRole(process.argv[1])));
  });
" -- "$INPUT")
assert_json_field "$STDOUT" .id "tester"
assert_json_field "$STDOUT" .capabilities '["quality-assurance","test-design"]'

# 缺 Capabilities
BAD=$(printf -- '---\nId: x\nDesc: y\n---\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/parse-role.mjs').then(m => {
    try { m.parseRole(process.argv[1]); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BAD")
assert_match "$OUT" "missing: Capabilities" "missing Capabilities"

pass
