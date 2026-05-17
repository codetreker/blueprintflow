#!/usr/bin/env bash
set -e

RUN_DIR=$(mktemp -d -p /tmp bf-stage4-XXXX)
trap 'rm -rf "$RUN_DIR"' EXIT

node bin/bf-harness.mjs init \
  --flow-file packs/product-engineering/flows/close-leaf-task.json \
  --entry implement --dir "$RUN_DIR" >/dev/null

OUT=$(node -e "
  import('./bin/lib/dispatcher/node-runner.mjs').then(m => {
    m.runNode({
      packPath: 'packs/product-engineering',
      flowFile: 'packs/product-engineering/flows/close-leaf-task.json',
      runDir: '$RUN_DIR',
      nodeId: 'implement',
      transitionToNext: true,
    }).then(r => console.log(JSON.stringify(r)));
  });
")

echo "$OUT" | grep -q '"sealed":true' || { echo "FAIL: node-runner did not seal"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q '"nextNode":"code-review"' || { echo "FAIL: did not advance to code-review"; echo "$OUT"; exit 1; }
[ -d "$RUN_DIR/nodes/implement/run_1" ] || { echo "FAIL: run_1 not created"; exit 1; }

echo "PASS: node-runner ticked implement → code-review"
