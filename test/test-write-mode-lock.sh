#!/usr/bin/env bash
# Mode B 5.5 accept-lock anchor writer: writeModeLock inserts/replaces the
# harness-owned Mode-Lock bf.md frontmatter field; rejects empty modes.
set -u
source "$(dirname "$0")/test-helpers.sh"

# no Mode-Lock yet => inserted into frontmatter
WITHOUT=$(printf -- '---\nId: x\nState: Draft\n---\n# body\n')
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    process.stdout.write(m.writeModeLock(process.argv[1], 'single-pr'));
  });
" -- "$WITHOUT")
assert_match "$STDOUT" "Mode-Lock: single-pr" "mode-lock inserted"
assert_match "$STDOUT" "# body" "body preserved"

# existing Mode-Lock => replaced (anchor is idempotent on re-accept)
WITH=$(printf -- '---\nId: x\nState: Accepted\nMode-Lock: per-task-pr\n---\n')
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    process.stdout.write(m.writeModeLock(process.argv[1], 'single-pr'));
  });
" -- "$WITH")
assert_match "$STDOUT" "Mode-Lock: single-pr" "mode-lock replaced"
assert_not_match "$STDOUT" "per-task-pr" "old anchor removed"

# empty mode rejected (fail-closed: harness must always stamp a concrete mode)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    try { m.writeModeLock('---\nId: x\n---\n', ''); process.stdout.write('NO_THROW'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
")
assert_match "$STDOUT" "ERR:" "empty mode rejected"

pass
