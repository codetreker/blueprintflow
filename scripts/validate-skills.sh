#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skills_root="$repo_root/plugins/blueprintflow/skills"

count=0
for skill_dir in "$skills_root"/*; do
  [[ -d "$skill_dir" ]] || continue
  skill_file="$skill_dir/SKILL.md"
  skill_name=$(basename "$skill_dir")

  if [[ ! -f "$skill_file" ]]; then
    echo "Missing SKILL.md in $skill_dir" >&2
    exit 1
  fi

  if [[ $(sed -n '1p' "$skill_file") != "---" ]]; then
    echo "$skill_file must start with YAML frontmatter" >&2
    exit 1
  fi

  declared_name=$(awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^name:[[:space:]]*/ { sub(/^name:[[:space:]]*/, ""); print; exit }
  ' "$skill_file")
  description=$(awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^description:[[:space:]]*/ { sub(/^description:[[:space:]]*/, ""); print; exit }
  ' "$skill_file")

  if [[ -z "$declared_name" ]]; then
    echo "$skill_file is missing frontmatter name" >&2
    exit 1
  fi
  if [[ "$declared_name" != "$skill_name" ]]; then
    echo "$skill_file name mismatch: directory=$skill_name frontmatter=$declared_name" >&2
    exit 1
  fi
  if [[ -z "$description" ]]; then
    echo "$skill_file is missing frontmatter description" >&2
    exit 1
  fi

  while IFS= read -r ref; do
    [[ -e "$skill_dir/$ref" ]] || {
      echo "$skill_file references missing file: $ref" >&2
      exit 1
    }
  done < <(grep -Eo '\]\(references/[A-Za-z0-9._/-]+\.md\)' "$skill_file" | sed -E 's/^\]\((.*)\)$/\1/' | sort -u || true)

  count=$((count + 1))
done

if (( count == 0 )); then
  echo "No skills found under $skills_root" >&2
  exit 1
fi

echo "Validated $count skills"
