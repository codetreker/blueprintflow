#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}

if [[ ! -f "$repo_root/package.json" ]]; then
  echo "package.json missing" >&2
  exit 1
fi
if ! jq -e '.files | index("packs/") != null' "$repo_root/package.json" >/dev/null; then
  echo "package.json files must include packs/" >&2
  exit 1
fi

packs_dir="$repo_root/packs"
if [[ ! -d "$packs_dir" ]]; then
  echo "packs/ directory missing" >&2
  exit 1
fi

shopt -s nullglob
for pack_dir in "$packs_dir"/*; do
  [[ -d "$pack_dir" ]] || continue
  pack_id=$(basename "$pack_dir")
  if [[ ! -f "$pack_dir/pack.md" ]]; then
    echo "pack $pack_id missing pack.md" >&2
    exit 1
  fi
  pipelines_dir="$pack_dir/pipelines"
  if [[ ! -e "$pipelines_dir" ]]; then
    continue
  fi
  if [[ ! -d "$pipelines_dir" ]]; then
    echo "pack $pack_id pipelines path must be a directory" >&2
    exit 1
  fi
  entries=("$pipelines_dir"/* "$pipelines_dir"/.*)
  valid_entries=()
  for entry in "${entries[@]}"; do
    name=$(basename "$entry")
    [[ "$name" == "." || "$name" == ".." ]] && continue
    [[ -e "$entry" ]] || continue
    valid_entries+=("$entry")
  done
  if [[ ${#valid_entries[@]} -eq 0 ]]; then
    echo "pack $pack_id pipelines directory is empty" >&2
    exit 1
  fi
  for entry in "${valid_entries[@]}"; do
    name=$(basename "$entry")
    if [[ "$name" == .* ]]; then
      echo "pack $pack_id invalid pipeline filename: $name" >&2
      exit 1
    fi
    if [[ ! -f "$entry" ]]; then
      echo "pack $pack_id pipeline entry must be a file: $name" >&2
      exit 1
    fi
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*\.yml$ ]]; then
      echo "pack $pack_id invalid pipeline filename: $name" >&2
      exit 1
    fi
  done
done
shopt -u nullglob

echo "BF package layout is valid"
