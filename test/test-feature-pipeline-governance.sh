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
  "bf-harness cleanup after bf-harness complete succeeds" \
  "does not require red-first tdd"; do
  case "$body" in
    *"$term"*) ;;
    *) fail "feature pipeline should mention '$term'" ;;
  esac
done

assert_match "$body" "coordinator" "feature pipeline should name coordinator final gate"
assert_match "$body" "reruns final verify" "feature pipeline should require final verify rerun"
assert_match "$body" "merge" "feature pipeline should keep merge before completion boundary"
assert_match "$body" "complete" "feature pipeline should keep complete boundary"
assert_match "$body" "cleanup" "feature pipeline should keep cleanup boundary"
assert_not_match "$body" "coordinator decides whether this evidence is sufficient" "feature pipeline should not keep old coordinator closure sufficiency wording"

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
