#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

run_validate() {
  STDOUT=$(node --input-type=module -e "
    Promise.all([
      import('$REPO_ROOT/bin/lib/harness/load-wo.mjs'),
      import('$REPO_ROOT/bin/lib/harness/validate-wo.mjs'),
    ]).then(async ([l, v]) => {
      const bundle = await l.loadWo({ baseHome: '$BASE', woId: process.argv[1], installDir: '$REPO' });
      process.stdout.write(JSON.stringify(v.validateWo(bundle)));
    });
  " "$1")
}

setup; copy_fixture clean-wo "$BASE/works/clean-wo"
run_validate clean-wo
assert_json_field "$STDOUT" .ok true
cleanup

setup; copy_fixture missing-capability-wo "$BASE/works/missing-cap-wo"
run_validate missing-cap-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "CAPABILITY_UNKNOWN" "missing cap"
cleanup

# task specs bind to an execution Pipeline, not a single doer Capability
setup; copy_fixture clean-wo "$BASE/works/forbidden-task-capability-wo"
sed -i.bak '/^Pipeline: feature$/a Capability: software-implementation' "$BASE/works/forbidden-task-capability-wo/task-a/spec.md"
run_validate forbidden-task-capability-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "TASK_CAPABILITY_FORBIDDEN" "task Capability rejected"
cleanup

# task Pipeline must exist in the task Pack's effective pipeline registry
setup; copy_fixture clean-wo "$BASE/works/unknown-pipeline-wo"
sed -i.bak 's/^Pipeline: feature/Pipeline: ghost/' "$BASE/works/unknown-pipeline-wo/task-a/spec.md"
run_validate unknown-pipeline-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_NOT_FOUND" "unknown pipeline rejected"
cleanup

# task Pipeline can resolve to a bf-wo local pipeline
setup; copy_fixture clean-wo "$BASE/works/local-pipeline-wo"
sed -i.bak 's/^Pipeline: feature/Pipeline: api-migration/' "$BASE/works/local-pipeline-wo/task-a/spec.md"
write_local_pipeline "$BASE/works/local-pipeline-wo/pipelines/api-migration.yml" "api-migration"
run_validate local-pipeline-wo
assert_json_field "$STDOUT" .ok true
cleanup

# local pipeline id must not collide with selected pack pipeline id
setup; copy_fixture clean-wo "$BASE/works/local-pipeline-collision-wo"
write_local_pipeline "$BASE/works/local-pipeline-collision-wo/pipelines/feature.yml" "feature"
run_validate local-pipeline-collision-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_LOCAL_COLLISION" "local/pack pipeline id collision rejected"
cleanup

# local pipelines must be referenced by at least one task
setup; copy_fixture clean-wo "$BASE/works/unreferenced-local-pipeline-wo"
write_local_pipeline "$BASE/works/unreferenced-local-pipeline-wo/pipelines/api-migration.yml" "api-migration"
run_validate unreferenced-local-pipeline-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_LOCAL_UNREFERENCED" "unreferenced local pipeline rejected"
cleanup

# local pipeline must have instruction and stages
setup; copy_fixture clean-wo "$BASE/works/bad-local-pipeline-wo"
sed -i.bak 's/^Pipeline: feature/Pipeline: api-migration/' "$BASE/works/bad-local-pipeline-wo/task-a/spec.md"
mkdir -p "$BASE/works/bad-local-pipeline-wo/pipelines"
cat > "$BASE/works/bad-local-pipeline-wo/pipelines/api-migration.yml" <<'EOF'
id: api-migration
desc: Missing required local pipeline fields
EOF
run_validate bad-local-pipeline-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_LOCAL_INSTRUCTION_MISSING" "missing local pipeline instruction rejected"
assert_match "$STDOUT" "PIPELINE_LOCAL_STAGES_EMPTY" "empty local pipeline stages rejected"
cleanup

# local pipeline stage capability must exist
setup; copy_fixture clean-wo "$BASE/works/bad-local-capability-wo"
sed -i.bak 's/^Pipeline: feature/Pipeline: api-migration/' "$BASE/works/bad-local-capability-wo/task-a/spec.md"
write_local_pipeline "$BASE/works/bad-local-capability-wo/pipelines/api-migration.yml" "api-migration"
sed -i.bak 's/capability: software-implementation/capability: ghost-capability/' "$BASE/works/bad-local-capability-wo/pipelines/api-migration.yml"
run_validate bad-local-capability-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_LOCAL_CAPABILITY_UNKNOWN" "unknown local stage capability rejected"
cleanup

# local pipeline filenames are linted even when the extension is wrong
setup; copy_fixture clean-wo "$BASE/works/bad-local-filename-wo"
mkdir -p "$BASE/works/bad-local-filename-wo/pipelines"
cat > "$BASE/works/bad-local-filename-wo/pipelines/Bad.yaml" <<'EOF'
id: Bad
desc: Invalid filename
EOF
run_validate bad-local-filename-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_LOCAL_FILENAME_INVALID" "invalid local pipeline filename rejected"
cleanup

# local pipeline stage ids must be unique
setup; copy_fixture clean-wo "$BASE/works/duplicate-stage-wo"
sed -i.bak 's/^Pipeline: feature/Pipeline: api-migration/' "$BASE/works/duplicate-stage-wo/task-a/spec.md"
write_local_pipeline "$BASE/works/duplicate-stage-wo/pipelines/api-migration.yml" "api-migration"
cat >> "$BASE/works/duplicate-stage-wo/pipelines/api-migration.yml" <<'EOF'
  - id: implementation
    capability: software-implementation
    instruction: |
      Duplicate stage id.
EOF
run_validate duplicate-stage-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_LOCAL_STAGE_ID_DUPLICATE" "duplicate local stage id rejected"
cleanup

# task id 'pipelines' is reserved
setup; copy_fixture clean-wo "$BASE/works/reserved-task-id-wo"
sed -i.bak 's/^- task-a$/- pipelines/' "$BASE/works/reserved-task-id-wo/bf.md"
mv "$BASE/works/reserved-task-id-wo/task-a" "$BASE/works/reserved-task-id-wo/pipelines"
run_validate reserved-task-id-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "TASK_ID_RESERVED" "reserved task id rejected"
cleanup

# dep cycle: 把 task-a 改成依赖 task-b（task-b 已经依赖 task-a）
setup; copy_fixture clean-wo "$BASE/works/cycle-wo"
sed -i.bak 's/^- task-a$/- task-a: task-b/' "$BASE/works/cycle-wo/bf.md"
run_validate cycle-wo
assert_match "$STDOUT" "DEP_CYCLE" "cycle detected"
cleanup

# task specs must carry an explicit Evidence section before lint can pass
setup; copy_fixture clean-wo "$BASE/works/missing-evidence-section-wo"
sed -i.bak '/^## Evidence$/,/^## Boundary$/d' "$BASE/works/missing-evidence-section-wo/task-a/spec.md"
run_validate missing-evidence-section-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_SECTION_MISSING" "missing Evidence section detected"
cleanup

# every task AC needs at least one Evidence entry in the explicit section
setup; copy_fixture clean-wo "$BASE/works/missing-evidence-entry-wo"
sed -i.bak '/^- EV-/d' "$BASE/works/missing-evidence-entry-wo/task-a/spec.md"
run_validate missing-evidence-entry-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_MISSING" "missing Evidence entry detected"
cleanup

# Evidence must reference an AC in the same task spec
setup; copy_fixture clean-wo "$BASE/works/bad-evidence-ref-wo"
sed -i.bak 's/^- EV-1|AC-1|review-note:/- EV-1|AC-99|review-note:/' "$BASE/works/bad-evidence-ref-wo/task-a/spec.md"
run_validate bad-evidence-ref-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_AC_UNKNOWN" "unknown evidence AC detected"
cleanup

# Evidence ids are stable handles and must be unique within one task spec
setup; copy_fixture clean-wo "$BASE/works/duplicate-evidence-id-wo"
sed -i.bak '/^## Boundary$/i - EV-1|AC-1|review-note: duplicate id should fail lint' "$BASE/works/duplicate-evidence-id-wo/task-a/spec.md"
run_validate duplicate-evidence-id-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_DUPLICATE_ID" "duplicate Evidence id detected"
cleanup

# Evidence kind is a linted vocabulary, not arbitrary prose
setup; copy_fixture clean-wo "$BASE/works/unknown-evidence-kind-wo"
sed -i.bak 's/^- EV-1|AC-1|review-note:/- EV-1|AC-1|memo:/' "$BASE/works/unknown-evidence-kind-wo/task-a/spec.md"
run_validate unknown-evidence-kind-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_KIND_UNKNOWN" "unknown Evidence kind detected"
cleanup

# Evidence text must state the required proof, not just reserve an id
setup; copy_fixture clean-wo "$BASE/works/empty-evidence-text-wo"
sed -i.bak 's#^- EV-1|AC-1|review-note:.*$#- EV-1|AC-1|command:   #' "$BASE/works/empty-evidence-text-wo/task-a/spec.md"
run_validate empty-evidence-text-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "EVIDENCE_TEXT_EMPTY" "empty Evidence text detected"
cleanup

pass
