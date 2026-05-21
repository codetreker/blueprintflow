#!/usr/bin/env bash
# Enforce package.json version bump on PRs that touch @codetreker/bf
# release-facing paths (the same paths that ship in the npm tarball, plus
# scripts/ which runs at install time).
#
# Usage:
#   validate-bf-version.sh                 # uses $GITHUB_BASE_REF or origin/main
#   validate-bf-version.sh origin/main     # explicit base
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"

base_ref=${1:-${GITHUB_BASE_REF:-origin/main}}

resolve_ref() {
  local ref=$1
  if git rev-parse --verify -q "$ref^{commit}" >/dev/null; then
    printf '%s\n' "$ref"
  elif git rev-parse --verify -q "origin/$ref^{commit}" >/dev/null; then
    printf '%s\n' "origin/$ref"
  else
    return 1
  fi
}

# Strict semver comparison: returns 0 iff a > b. Supports plain MAJOR.MINOR.PATCH
# (with optional -pre / +build suffix that is ignored for ordering — pre-release
# semantics aren't needed for this repo's release cadence).
version_gt() {
  local a=$1 b=$2
  if [[ ! $a =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)([-+].*)?$ ]]; then
    echo "Invalid current semver: $a" >&2
    exit 1
  fi
  local a_major=${BASH_REMATCH[1]} a_minor=${BASH_REMATCH[2]} a_patch=${BASH_REMATCH[3]}
  if [[ ! $b =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)([-+].*)?$ ]]; then
    echo "Invalid base semver: $b" >&2
    exit 1
  fi
  local b_major=${BASH_REMATCH[1]} b_minor=${BASH_REMATCH[2]} b_patch=${BASH_REMATCH[3]}

  (( a_major > b_major )) && return 0
  (( a_major < b_major )) && return 1
  (( a_minor > b_minor )) && return 0
  (( a_minor < b_minor )) && return 1
  (( a_patch > b_patch )) && return 0
  return 1
}

# Paths whose changes warrant a version bump. Mirror of package.json `files`
# plus scripts/ (runs at install) plus package.json itself.
is_bf_release_path() {
  local path=$1
  case "$path" in
    bin/*) return 0 ;;
    scripts/*) return 0 ;;
    SKILL.md) return 0 ;;
    roles/*) return 0 ;;
    packs/*) return 0 ;;
    templates/*) return 0 ;;
    references/*) return 0 ;;
    package.json) return 0 ;;
    *) return 1 ;;
  esac
}

base_commit=$(resolve_ref "$base_ref") || {
  echo "Could not resolve base ref: $base_ref" >&2
  exit 1
}
merge_base=$(git merge-base HEAD "$base_commit")

current_version=$(jq -r '.version' package.json)

release_changed=false
changed_paths=()
while IFS= read -r path; do
  if is_bf_release_path "$path"; then
    release_changed=true
    changed_paths+=("$path")
  fi
done < <(git diff --name-only "$merge_base"...HEAD)

if [[ "$release_changed" != true ]]; then
  echo "✓ No @codetreker/bf release-facing changes; version bump not required."
  exit 0
fi

base_pkg=$(git show "$merge_base":package.json 2>/dev/null || echo '')
if [[ -z "$base_pkg" ]]; then
  echo "✓ package.json did not exist at $merge_base — treating as bootstrap, no bump required."
  exit 0
fi
base_version=$(printf '%s' "$base_pkg" | jq -r '.version // empty')
if [[ -z "$base_version" ]]; then
  echo "Could not parse base package.json version from $merge_base" >&2
  exit 1
fi

if [[ "$current_version" == "$base_version" ]]; then
  echo "✗ Release-facing files changed but package.json version did not bump (still $current_version)." >&2
  echo "" >&2
  echo "Changed release-relevant files:" >&2
  printf '  - %s\n' "${changed_paths[@]}" >&2
  exit 1
fi

if ! version_gt "$current_version" "$base_version"; then
  echo "✗ package.json version must increase: base=$base_version current=$current_version" >&2
  exit 1
fi

echo "✓ @codetreker/bf version bump valid: $base_version → $current_version"
