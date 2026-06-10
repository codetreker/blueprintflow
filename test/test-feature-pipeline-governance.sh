#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/feature.yml"
[ -f "$FILE" ] || fail "missing feature pipeline"

body=$(tr '[:upper:]' '[:lower:]' < "$FILE" | tr '\n\t' '  ' | tr -s ' ')

for term in \
  "id: feature" \
  "design-first" \
  "architecture-design" \
  "implementation-design" \
  "evidence plan" \
  "design-doc-sync" \
  "validation" \
  "not-applicable evidence" \
  "independent review" \
  "do not clean bf-owned task worktrees" \
  "bf-harness cleanup after final acceptance" \
  "does not require red-first tdd"; do
  case "$body" in
    *"$term"*) ;;
    *) fail "feature pipeline should mention '$term'" ;;
  esac
done

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")
MISSING_OUTPUTS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const ids = ['architecture-review', 'design-review', 'code-review', 'terminal-state-closure'];
  const missing = ids.filter(id => {
    const stage = p.stages.find(s => s.id === id);
    return !stage || !String(stage.output || '').trim();
  });
  process.stdout.write(missing.join(','));
" "$PIPELINE_JSON")
assert_eq "$MISSING_OUTPUTS" "" "feature review/closure stages must have durable outputs"

pass
