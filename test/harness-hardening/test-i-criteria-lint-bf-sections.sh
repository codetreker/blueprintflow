#!/usr/bin/env bash
set -e
# Stage 6.1 finding #2: criteria-lint must accept BF Pack section names
# (Objective / Boundary / Acceptance criteria) as aliases for the
# OPC names (Outcomes / Verification / Quality / Scope).
DIR=$(mktemp -d -p /tmp bf-lint-XXXX)
trap 'rm -rf "$DIR"' EXIT

cat > "$DIR/wo.md" <<EOF
# add bf version verb

## Objective
Add a \`bf version\` verb that prints the package.json version
on stdout and exits 0.

## Boundary
- No \`--version\` flag on top-level bf.
- No shell-out to npm or git.
- No new dependencies.

## Acceptance criteria
- [ ] \`bin/lib/verbs/version.mjs\` exists and is an ES module
- [ ] \`KNOWN_VERBS\` set in \`arg-parser.mjs\` contains \`"version"\`
- [ ] Running \`node bin/bf.mjs version\` exits 0
- [ ] stdout exactly matches the version field in \`package.json\` (plus a trailing newline)
- [ ] \`bf help\` lists \`version\` in the verb table
- [ ] \`test/verbs/test-version.sh\` exists and is executable
EOF

OUT=$(node bin/bf-harness.mjs criteria-lint "$DIR/wo.md" 2>&1 || true)
# Extract the JSON pass:true assertion
if echo "$OUT" | grep -q '"pass": true'; then
  echo "PASS: criteria-lint accepts BF Pack section names"
  exit 0
fi
echo "FAIL: criteria-lint rejected BF Pack sections; finding #2 not fixed"
echo "$OUT"
exit 1
