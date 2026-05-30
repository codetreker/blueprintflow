#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

ROOT=$(make_temp_home)
WO=$(make_temp_home)
mkdir -p "$ROOT/packs"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"
mkdir -p "$WO/pipelines"
write_local_pipeline "$WO/pipelines/api-migration.yml" "api-migration"
write_local_pipeline "$WO/pipelines/feature.yml" "feature"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(async (packs) => {
    const pipelines = await import('$REPO_ROOT/bin/lib/shared/pipeline-registry.mjs');
    const packReg = packs.buildPackRegistry({ packsDir: '$ROOT/packs' });
    const reg = pipelines.buildPipelineRegistry({
      packReg,
      pack: 'engineering',
      localPipelinesDir: '$WO/pipelines',
    });
    const local = pipelines.findPipeline(reg, 'engineering', 'api-migration');
    process.stdout.write(JSON.stringify({
      ok: !reg.error,
      localFile: local?.file,
      localSource: local?.source,
      collisionWarnings: reg.warnings.filter(w => w.includes('feature')),
      packFeatureFile: pipelines.findPipeline(reg, 'engineering', 'feature')?.file,
    }));
  });
")
assert_json_field "$STDOUT" .ok true
assert_match "$STDOUT" "$WO/pipelines/api-migration.yml" "local pipeline file"
assert_json_field "$STDOUT" .localSource "local"
assert_match "$STDOUT" "local pipeline id collides with selected pack pipeline: feature" "collision warning"
assert_not_match "$STDOUT" "$WO/pipelines/feature.yml" "collision must not override pack pipeline"

rm -rf "$ROOT" "$WO"
pass
