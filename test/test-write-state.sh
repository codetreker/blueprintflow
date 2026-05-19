#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(printf -- '---\nId: x\nState: Draft\nPack: p\n---\n# body\nState: not me\n')

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/write-state.mjs').then(m => {
    process.stdout.write(m.writeState(process.argv[1], 'Accepted'));
  });
" -- "$INPUT")
assert_match "$STDOUT" "State: Accepted" "frontmatter State changed"
assert_match "$STDOUT" "State: not me" "body line untouched"

# invalid state
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/write-state.mjs').then(m => {
    try { m.writeState(process.argv[1], 'Bogus'); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$INPUT")
assert_match "$OUT" "invalid state" "invalid state rejected"

# no State field
BAD=$(printf -- '---\nId: x\n---\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/write-state.mjs').then(m => {
    try { m.writeState(process.argv[1], 'Draft'); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BAD")
assert_match "$OUT" "State field missing" "no state field rejected"

pass
