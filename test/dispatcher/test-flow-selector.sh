#!/usr/bin/env bash
set -e

OUT=$(node -e "
  import('./bin/lib/dispatcher/flow-selector.mjs').then(m => {
    const manifest = {
      routing: {'task,new': 'brainstorm-task', 'task,doing': 'close-leaf-task'},
      state_aliases: {'reviewed_task_ready': 'shaped'}
    };
    console.log(JSON.stringify({
      a: m.selectFlow(manifest, {schema:'task', current_state:'new'}),
      b: m.selectFlow(manifest, {schema:'task', current_state:'doing'}),
      c: m.selectFlow(manifest, {schema:'task', current_state:'reviewed_task_ready'}),
      d: m.selectFlow(manifest, {schema:'task', current_state:'done'}),
    }));
  });
")
echo "$OUT" | grep -q '"a":"brainstorm-task"' || { echo "FAIL a"; exit 1; }
echo "$OUT" | grep -q '"b":"close-leaf-task"' || { echo "FAIL b"; exit 1; }
# state_aliases: reviewed_task_ready → shaped, but routing has no task,shaped → null
echo "$OUT" | grep -q '"c":null' || { echo "FAIL c (alias-then-miss)"; exit 1; }
echo "$OUT" | grep -q '"d":null' || { echo "FAIL d (no rule)"; exit 1; }

echo "PASS: flow-selector handles routing + state_aliases + miss"
