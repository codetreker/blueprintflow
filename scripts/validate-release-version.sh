#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
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

read_version_at() {
  local commit=$1
  shift
  local path version
  for path in "$@"; do
    version=$(git show "$commit:$path" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || true)
    if [[ -n "$version" ]]; then
      printf '%s\n' "$version"
      return 0
    fi
  done
  return 1
}

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

is_release_path() {
  local path=$1
  case "$path" in
    plugins/blueprintflow/*) return 0 ;;
    skills/*) return 0 ;;                         # legacy path, kept for migration checks
    .codex-plugin/*) return 0 ;;                  # legacy path, kept for migration checks
    .claude-plugin/plugin.json) return 0 ;;
    .agents/plugins/marketplace.json) return 0 ;;
    .claude-plugin/marketplace.json) return 0 ;;
    README.md) return 0 ;;
    *) return 1 ;;
  esac
}

base_commit=$(resolve_ref "$base_ref") || {
  echo "Could not resolve base ref: $base_ref" >&2
  exit 1
}
merge_base=$(git merge-base HEAD "$base_commit")

current_codex=$(jq -r '.version' plugins/blueprintflow/.codex-plugin/plugin.json)
current_claude=$(jq -r '.version' plugins/blueprintflow/.claude-plugin/plugin.json)
if [[ "$current_codex" != "$current_claude" ]]; then
  echo "Manifest version mismatch: Codex=$current_codex Claude=$current_claude" >&2
  exit 1
fi
current_version=$current_codex

release_changed=false
while IFS= read -r path; do
  if is_release_path "$path"; then
    release_changed=true
    break
  fi
done < <(git diff --name-only "$merge_base"...HEAD)

if [[ "$release_changed" != true ]]; then
  echo "No release-facing changes; version bump not required"
  exit 0
fi

base_codex=$(read_version_at "$merge_base" \
  plugins/blueprintflow/.codex-plugin/plugin.json \
  .codex-plugin/plugin.json)
base_claude=$(read_version_at "$merge_base" \
  plugins/blueprintflow/.claude-plugin/plugin.json \
  .claude-plugin/plugin.json)

if [[ "$base_codex" != "$base_claude" ]]; then
  echo "Base manifest version mismatch: Codex=$base_codex Claude=$base_claude" >&2
  exit 1
fi

if [[ "$current_version" == "$base_codex" ]]; then
  echo "Release-facing files changed but plugin version did not bump: $current_version" >&2
  exit 1
fi

if ! version_gt "$current_version" "$base_codex"; then
  echo "Plugin version must increase: base=$base_codex current=$current_version" >&2
  exit 1
fi

if ! grep -q "^## v$current_version " docs/CHANGELOG.md; then
  echo "docs/CHANGELOG.md must include an entry for v$current_version" >&2
  exit 1
fi

echo "Release version bump is valid: $base_codex -> $current_version"
