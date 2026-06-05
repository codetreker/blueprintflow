#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/bugfix.yml"
[ -f "$FILE" ] || fail "missing bugfix pipeline"

body=$(tr '[:upper:]' '[:lower:]' < "$FILE" | tr '\n\t' '  ' | tr -s ' ')

for term in \
  "id: bugfix" \
  "focused failing regression test" \
  "expected failure" \
  "smallest fix" \
  "focused passing test" \
  "design drift" \
  "behavior contract" \
  "design-doc-sync" \
  "validation" \
  "independent review" \
  "terminal-state closure" \
  "terminal state" \
  "handoff owner" \
  "stop condition"; do
  case "$body" in
    *"$term"*) ;;
    *) fail "bugfix pipeline should mention '$term'" ;;
  esac
done

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")
STAGE_COUNT=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(String(p.stages.length));" "$PIPELINE_JSON")
LAST_INDEX=$((STAGE_COUNT - 1))
PREV_INDEX=$((STAGE_COUNT - 2))
LAST_ID=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(p.stages[$LAST_INDEX]?.id || '');" "$PIPELINE_JSON")
PREV_ID=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(p.stages[$PREV_INDEX]?.id || '');" "$PIPELINE_JSON")
assert_eq "$PREV_ID" "code-review" "code-review should remain immediately before terminal-state closure"
assert_eq "$LAST_ID" "terminal-state-closure" "bugfix pipeline final stage"

PIPELINES=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$REPO_ROOT', pack: 'engineering' })));
  });
")
assert_json_field "$PIPELINES" .ok true
assert_match "$PIPELINES" '"id":"bugfix"' "bugfix pipeline should be discoverable"
assert_match "$PIPELINES" '"id":"feature"' "feature pipeline should remain discoverable"

pass
