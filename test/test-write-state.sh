#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(printf -- '---\nId: x\nState: Draft\nPack: p\n---\n# body\nState: not me\n')

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-state.mjs').then(m => {
    process.stdout.write(m.writeState(process.argv[1], 'Accepted', { kind: 'bf' }));
  });
" -- "$INPUT")
assert_match "$STDOUT" "State: Accepted" "frontmatter State changed"
assert_match "$STDOUT" "State: not me" "body line untouched"

# invalid state
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-state.mjs').then(m => {
    try { m.writeState(process.argv[1], 'Bogus', { kind: 'bf' }); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$INPUT")
assert_match "$OUT" "invalid state" "invalid state rejected"

# no State field
BAD=$(printf -- '---\nId: x\n---\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-state.mjs').then(m => {
    try { m.writeState(process.argv[1], 'Draft', { kind: 'bf' }); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BAD")
assert_match "$OUT" "State field missing" "no state field rejected"

# 非法跳转：Draft -> Implementing（中间应该过 Accepted）
INPUT2=$(printf -- '---\nState: Draft\n---\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-state.mjs').then(m => {
    try { m.writeState(process.argv[1], 'Implementing', { kind: 'bf' }); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$INPUT2")
assert_match "$OUT" "illegal state transition" "skip-state rejected"

# 跨 kind 误用：Tasking 不合法 for bf.md
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-state.mjs').then(m => {
    try { m.writeState(process.argv[1], 'Tasking', { kind: 'bf' }); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$INPUT2")
assert_match "$OUT" "illegal state transition" "wrong-kind state rejected"

pass
