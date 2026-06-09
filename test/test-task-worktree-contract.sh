#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

task_spec() {
  local extra="$1"
  cat <<EOF
---
State: Draft
Pipeline: feature
Pack: engineering
Desc: worktree contract fixture
$extra
---

# Task

Fixture task.

## Acceptance Criteria

- [ ] AC-1|quality-assurance: ok

## Evidence

- EV-1|AC-1|command: bash test/run-all.sh
EOF
}

parse_spec_json() {
  local input="$1"
  node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/parse-task-spec.mjs').then(m => {
      const r = m.parseTaskSpec(process.argv[1]);
      process.stdout.write(JSON.stringify({
        requiresWorktree: r.requiresWorktree,
        branch: r.executionMetadata.branch,
        worktree: r.executionMetadata.worktree,
        pullRequest: r.executionMetadata.pullRequest,
      }));
    });
  " -- "$input"
}

for value in true false; do
  INPUT=$(task_spec "Requires-Worktree: $value
Branch:
Worktree:
Pull-Request:")
  STDOUT=$(parse_spec_json "$INPUT")
  assert_json_field "$STDOUT" .requiresWorktree "$value"
  assert_json_field "$STDOUT" .branch null
  assert_json_field "$STDOUT" .worktree null
  assert_json_field "$STDOUT" .pullRequest null
done

for extra in "" "Requires-Worktree:" "Requires-Worktree: yes" "Requires-Worktree: TRUE" "Requires-Worktree: 1"; do
  INPUT=$(task_spec "$extra")
  OUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/parse-task-spec.mjs').then(m => {
      try { m.parseTaskSpec(process.argv[1]); process.stdout.write('ok'); }
      catch (e) { process.stdout.write('ERR:' + e.message); }
    });
  " -- "$INPUT")
  assert_match "$OUT" "Requires-Worktree" "invalid Requires-Worktree rejected: $extra"
done

INPUT=$(task_spec "Requires-Worktree: true
Branch: bf/wo/task
Worktree: /tmp/worktree
Pull-Request: https://github.com/example/repo/pull/1")
STDOUT=$(parse_spec_json "$INPUT")
assert_json_field "$STDOUT" .branch "bf/wo/task"
assert_json_field "$STDOUT" .worktree "/tmp/worktree"
assert_json_field "$STDOUT" .pullRequest "https://github.com/example/repo/pull/1"

INPUT=$(task_spec "Requires-Worktree: true
Branch:
Worktree:
Pull-Request:")
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    let s = process.argv[1];
    s = m.writeTaskExecutionMetadata(s, {
      branch: 'bf/wo/task-a',
      worktree: '/tmp/wo/task-a',
      pullRequest: 'https://github.com/example/repo/pull/2',
    });
    process.stdout.write(s);
  });
" -- "$INPUT")
assert_match "$STDOUT" "Branch: bf/wo/task-a" "Branch updated"
assert_match "$STDOUT" "Worktree: /tmp/wo/task-a" "Worktree updated"
assert_match "$STDOUT" "Pull-Request: https://github.com/example/repo/pull/2" "Pull-Request updated"

BF_INPUT=$(printf -- '---\nId: x\nState: Draft\nPack: engineering\nBranch:\n---\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    try { m.writeTaskExecutionMetadata(process.argv[1], { branch: 'bf/x/task' }); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BF_INPUT")
assert_match "$OUT" "task spec" "bf-level execution metadata mutation rejected"

BF_INPUT=$(printf -- '---\nId: x\nState: Draft\nPack: engineering\nPipeline: feature\nBranch:\n---\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    try { m.writeTaskExecutionMetadata(process.argv[1], { branch: 'bf/x/task' }); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BF_INPUT")
assert_match "$OUT" "task spec" "bf-level execution metadata mutation rejected even with Pipeline"

BF_INPUT=$(printf -- '---\nId: x\nDesc: forged bf shape\nState: Draft\nPack: engineering\nPipeline: feature\nRequires-Worktree: true\nBranch:\n---\n\n# Goal\n\nFixture.\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-mutations.mjs').then(m => {
    try { m.writeTaskExecutionMetadata(process.argv[1], { branch: 'bf/x/task' }); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BF_INPUT")
assert_match "$OUT" "task spec" "bf-shaped execution metadata mutation rejected with forged task fields"

BASE=$(make_temp_home)
copy_fixture clean-wo "$BASE/works/clean-wo"

# Missing Requires-Worktree in fixture should fail lint after the contract is enforced.
for t in task-a task-b; do
  node -e "
    const fs=require('fs');
    const p='$BASE/works/clean-wo/$t/spec.md';
    let s=fs.readFileSync(p,'utf8');
    s=s.replace(/^Requires-Worktree:.*\n/m, '');
    s=s.replace(/^Branch:.*\n/m, '');
    s=s.replace(/^Worktree:.*\n/m, '');
    s=s.replace(/^Pull-Request:.*\n/m, '');
    fs.writeFileSync(p, s);
  "
done
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-lint.mjs').then(async (m) => {
    const r = await m.cmdLint({ baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO_ROOT' });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "Requires-Worktree" "lint reports missing Requires-Worktree"

for value in yes TRUE 1; do
  copy_fixture clean-wo "$BASE/works/lint-$value"
  for t in task-a task-b; do
    node -e "
      const fs=require('fs');
      const p='$BASE/works/lint-$value/$t/spec.md';
      let s=fs.readFileSync(p,'utf8');
      s=s.replace(/^Requires-Worktree:.*$/m, 'Requires-Worktree: $value');
      fs.writeFileSync(p, s);
    "
  done
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-lint.mjs').then(async (m) => {
      const r = await m.cmdLint({ baseHome: '$BASE', woId: 'lint-$value', installDir: '$REPO_ROOT' });
      process.stdout.write(JSON.stringify(r));
    });
  ")
  assert_json_field "$STDOUT" .ok false
  assert_match "$STDOUT" "Requires-Worktree" "lint rejects non-boolean Requires-Worktree: $value"
done

for t in task-a task-b; do
  node -e "
    const fs=require('fs');
    const p='$BASE/works/clean-wo/$t/spec.md';
    let s=fs.readFileSync(p,'utf8');
    s=s.replace(/^Desc:/m, 'Requires-Worktree: true\\nBranch:\\nWorktree:\\nPull-Request:\\nDesc:');
    fs.writeFileSync(p, s);
  "
done
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-lint.mjs').then(async (m) => {
    const r = await m.cmdLint({ baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO_ROOT' });
    process.stdout.write(JSON.stringify(r));
  });
")
assert_json_field "$STDOUT" .ok true
rm -rf "$BASE"

pass
