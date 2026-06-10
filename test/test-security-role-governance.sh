#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

ROLES_JSON=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-roles.mjs').then(async (m) => {
    const r = await m.cmdListRoles({ cwd: '$REPO_ROOT', pack: 'engineering' });
    const role = r.roles.find((x) => x.id === 'security');
    process.stdout.write(JSON.stringify({
      ok: r.ok,
      roleId: role?.id || '',
      roleSource: role?.source || '',
      roleCapabilities: role?.capabilities || [],
    }));
  });
")
assert_json_field "$ROLES_JSON" .ok true
assert_json_field "$ROLES_JSON" .roleId "security"
assert_json_field "$ROLES_JSON" .roleSource "core"
assert_json_field "$ROLES_JSON" .roleCapabilities '["security-review"]'

REGISTRY_JSON=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then((m) => {
    const r = m.buildRoleRegistry({ coreRolesDir: '$REPO_ROOT/roles' });
    process.stdout.write(JSON.stringify({
      hasSecurity: r.roles.has('security'),
      securityReviewRoles: (r.byCapability.get('security-review') || []).map((x) => x.id),
    }));
  });
")
assert_json_field "$REGISTRY_JSON" .hasSecurity true
assert_json_field "$REGISTRY_JSON" .securityReviewRoles '["security"]'

SECURITY_STAGE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import path from 'node:path';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const dir = '$REPO_ROOT/packs/engineering/pipelines';
  const stages = fs.readdirSync(dir)
    .filter((name) => name.endsWith('.yml'))
    .flatMap((name) => {
      const pipeline = parsePipeline(fs.readFileSync(path.join(dir, name), 'utf8'));
      return pipeline.stages
        .filter((stage) => stage.capability === 'security-review')
        .map((stage) => pipeline.id + ':' + stage.id);
    })
    .sort();
  process.stdout.write(JSON.stringify({ stages }));
")
assert_match "$SECURITY_STAGE_JSON" "code-deep-audit:security-baseline" "audit pipeline security stage"
assert_match "$SECURITY_STAGE_JSON" "bugfix:security-review" "bugfix security stage"
assert_match "$SECURITY_STAGE_JSON" "feature:security-review" "feature security stage"

pass
