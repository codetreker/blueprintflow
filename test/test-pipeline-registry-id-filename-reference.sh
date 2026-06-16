#!/usr/bin/env bash
# Reference-standard assertion: pipeline-registry.mjs ALREADY enforces
# id == filename (skip-with-warning). This test does NOT change its logic; it
# documents that the role/pack registries are being brought up to this existing
# standard. (Boundary: pipeline-registry is the unchanged reference.)
set -u
source "$(dirname "$0")/test-helpers.sh"

ROOT=$(make_temp_home)
mkdir -p "$ROOT/packs/refpack/pipelines"
write_pack_md "$ROOT/packs/refpack/pack.md" "refpack" "reference standard pack"

# A pipeline file whose id does not match its filename — must be skipped.
cat > "$ROOT/packs/refpack/pipelines/good.yml" <<'EOF'
id: not-good
desc: id does not match filename
instruction: |
  Follow this pipeline.
stages:
  - id: implementation
    capability: software-implementation
    instruction: |
      Implement.
EOF

# A correctly-named pipeline that must still load.
write_local_pipeline "$ROOT/packs/refpack/pipelines/valid.yml" "valid"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/pack-registry.mjs').then(async (packs) => {
    const pipelines = await import('$REPO_ROOT/bin/lib/shared/pipeline-registry.mjs');
    const packReg = packs.buildPackRegistry({ packsDir: '$ROOT/packs' });
    const reg = pipelines.buildPipelineRegistry({ packReg, pack: 'refpack' });
    process.stdout.write(JSON.stringify({
      ids: [...reg.pipelines.keys()].sort(),
      warnings: reg.warnings,
    }));
  });
")
# The mismatched pipeline is skipped with a warning; the valid one loads.
assert_json_field "$STDOUT" .ids '["refpack/valid"]'
assert_match "$STDOUT" 'skip pipeline' "pipeline mismatch skip warning present"
assert_match "$STDOUT" 'not-good' "skip warning names parsed id"
assert_match "$STDOUT" 'filename' "skip warning references filename mismatch"

rm -rf "$ROOT"
pass
