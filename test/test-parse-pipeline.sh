#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

INPUT=$(cat <<'EOF'
id: feature
desc: Feature task pipeline
instruction: |
  Run the stages in order and stop on blocking review findings.
stages:
  - id: architecture-design
    capability: system-architecture
    instruction: |
      Produce the architecture artifact.
  - id: code-review
    capability: quality-assurance
    instruction: |
      Review code and evidence.
EOF
)

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs').then(m => {
    process.stdout.write(JSON.stringify(m.parsePipeline(process.argv[1])));
  });
" -- "$INPUT")

assert_json_field "$STDOUT" .id "feature"
assert_json_field "$STDOUT" .desc "Feature task pipeline"
assert_match "$STDOUT" "Run the stages in order" "pipeline-level instruction parsed"
assert_json_field "$STDOUT" .stages.0.id "architecture-design"
assert_json_field "$STDOUT" .stages.0.capability "system-architecture"
assert_match "$STDOUT" "Produce the architecture artifact" "stage instruction parsed"

BAD=$(printf 'desc: Missing id\n')
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs').then(m => {
    try { m.parsePipeline(process.argv[1]); process.stdout.write('ok'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
" -- "$BAD")
assert_match "$OUT" "pipeline missing: id" "missing id"

pass
