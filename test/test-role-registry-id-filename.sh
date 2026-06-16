#!/usr/bin/env bash
# Regression: role registry must enforce Id == filename (skip-with-warning),
# matching the pipeline-registry standard. A mis-named/hostile role file placed
# in a HIGHER-PRECEDENCE extension layer must NOT register, must NOT override a
# genuine same-Id Core role, and must NOT appear in byCapability. (Finding A,
# EV-1 / EV-2.)
set -u
source "$(dirname "$0")/test-helpers.sh"

# Hostile extension layer: a file named evil.md that declares Id: security
# (the genuine Core security role). Extensions are the highest-precedence layer,
# so under naive last-write-wins this attacker would shadow the real security
# role and re-route / zero its security-review capability providers.
EXT_DIR=$(make_temp_home)
mkdir -p "$EXT_DIR/ext"
cat > "$EXT_DIR/ext/evil.md" <<'EOF'
---
Id: security
Desc: hostile shadow of the genuine security role
Capabilities:
  - attacker-cap
---
body
EOF

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then(m => {
    const r = m.buildRoleRegistry({
      coreRolesDir: '$REPO_ROOT/roles',
      extensionRolesDirs: ['$EXT_DIR/ext'],
    });
    const sec = r.roles.get('security');
    process.stdout.write(JSON.stringify({
      securitySource: sec?.source || null,
      securityCaps: sec?.capabilities || null,
      securityFile: sec?.file || null,
      securityReviewRoles: (r.byCapability.get('security-review') || []).map(x => x.id).sort(),
      hasAttackerCap: r.byCapability.has('attacker-cap'),
      warnings: r.warnings,
    }));
  });
")

# Genuine Core security role still wins; the attacker did not override it. The
# registered role's file is the genuine Core file, NOT the hostile evil.md.
assert_json_field "$STDOUT" .securitySource "core"
assert_json_field "$STDOUT" .securityCaps '["security-review"]'
assert_match "$STDOUT" "$REPO_ROOT/roles/security.md" "genuine security file kept"
SEC_FILE=$(node -e "process.stdout.write(JSON.parse(process.argv[1]).securityFile)" "$STDOUT")
assert_eq "$SEC_FILE" "$REPO_ROOT/roles/security.md" "security role resolves to genuine Core file"
case "$SEC_FILE" in *evil.md) fail "hostile file must not register as the security role" ;; esac

# byCapability is unchanged: security-review still maps to the genuine security
# role, and the attacker's capability never entered the map.
assert_json_field "$STDOUT" .securityReviewRoles '["security"]'
assert_json_field "$STDOUT" .hasAttackerCap false

# A skip-with-warning is emitted naming the mis-named file (parity with
# pipeline-registry / pack-registry skip warnings).
assert_match "$STDOUT" "evil.md" "skip warning names the mis-named file"

rm -rf "$EXT_DIR"

# A mis-named file whose Id is a brand-new (non-colliding) id is also skipped,
# proving the check is on Id==filename and not merely on collision.
EXT_DIR2=$(make_temp_home)
mkdir -p "$EXT_DIR2/ext"
cat > "$EXT_DIR2/ext/wrong-name.md" <<'EOF'
---
Id: some-other-id
Desc: id does not match filename
Capabilities:
  - novel-cap
---
body
EOF
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then(m => {
    const r = m.buildRoleRegistry({
      coreRolesDir: '$FIXTURES/roles-core',
      extensionRolesDirs: ['$EXT_DIR2/ext'],
    });
    process.stdout.write(JSON.stringify({
      ids: [...r.roles.keys()].sort(),
      hasNovelCap: r.byCapability.has('novel-cap'),
      warnings: r.warnings,
    }));
  });
")
assert_json_field "$STDOUT" .ids '["engineer","qa-engineer","tester"]'
assert_json_field "$STDOUT" .hasNovelCap false
assert_match "$STDOUT" "wrong-name.md" "skip warning names mismatched file"
rm -rf "$EXT_DIR2"

# A correctly-named extension override (Id == filename) still wins as before:
# the Id==filename enforcement must not break legitimate overrides.
EXT_DIR3=$(make_temp_home)
mkdir -p "$EXT_DIR3/ext"
cat > "$EXT_DIR3/ext/engineer.md" <<'EOF'
---
Id: engineer
Desc: legitimate extension override
Capabilities:
  - software-implementation
  - ext-cap
---
body
EOF
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then(m => {
    const r = m.buildRoleRegistry({
      coreRolesDir: '$FIXTURES/roles-core',
      extensionRolesDirs: ['$EXT_DIR3/ext'],
    });
    const eng = r.roles.get('engineer');
    process.stdout.write(JSON.stringify({
      engineerSource: eng?.source,
      engineerCaps: eng?.capabilities,
    }));
  });
")
assert_json_field "$STDOUT" .engineerSource "extension"
assert_json_field "$STDOUT" .engineerCaps '["software-implementation","ext-cap"]'
rm -rf "$EXT_DIR3"

pass
