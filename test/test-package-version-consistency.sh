#!/usr/bin/env bash
# Assert package.json and package-lock.json carry the SAME, VALID semver — with no
# hardcoded literal. This replaces the three per-test `== 0.7.x` literal pins (which created
# a release-bump deadlock: any bump broke `npm test` until all three were hand-edited). The
# guard that matters is lock-sync + a valid semver shape, not a specific version string.
set -u
source "$(dirname "$0")/test-helpers.sh"

# Read all three version sources from the real package files.
PKG_VERSION=$(node --input-type=module -e "
  import { readFileSync } from 'node:fs';
  process.stdout.write(JSON.parse(readFileSync('$REPO_ROOT/package.json', 'utf8')).version);
")
LOCK_ROOT_VERSION=$(node --input-type=module -e "
  import { readFileSync } from 'node:fs';
  process.stdout.write(JSON.parse(readFileSync('$REPO_ROOT/package-lock.json', 'utf8')).version);
")
LOCK_PKG_VERSION=$(node --input-type=module -e "
  import { readFileSync } from 'node:fs';
  const p = JSON.parse(readFileSync('$REPO_ROOT/package-lock.json', 'utf8'));
  process.stdout.write(p.packages[''].version);
")

# Valid semver shape: MAJOR.MINOR.PATCH with an optional pre-release/build suffix. No literal.
case "$PKG_VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) fail "package.json version is not semver-shaped: '$PKG_VERSION'" ;;
esac
node --input-type=module -e "
  const v = process.argv[1];
  if (!/^[0-9]+\.[0-9]+\.[0-9]+([-+].*)?\$/.test(v)) {
    console.error('not a valid semver: ' + v);
    process.exit(1);
  }
" "$PKG_VERSION" || fail "package.json version is not a valid semver: '$PKG_VERSION'"

# Lock-sync: package.json == package-lock.json root == packages[''].
assert_eq "$LOCK_ROOT_VERSION" "$PKG_VERSION" "package-lock root version must match package.json"
assert_eq "$LOCK_PKG_VERSION" "$PKG_VERSION" "package-lock packages[''] version must match package.json"

pass
