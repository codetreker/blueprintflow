#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skills_root="$repo_root/plugins/blueprintflow/skills"

stale_refs=$(grep -RInE 'bf-milestone-fourpiece|milestone-fourpiece' "$repo_root/README.md" "$skills_root" || true)
if [[ -n "$stale_refs" ]]; then
  printf '%s\n' "$stale_refs" >&2
  echo "Active docs must not reference retired bf-milestone-fourpiece; use bf-task-fourpiece." >&2
  exit 1
fi

fixed_cadence=$(grep -RInE '7,22,37,52 \* \* \* \*|17 \*/2 \* \* \*|openclaw cron add \.\.\.' "$skills_root" || true)
if [[ -n "$fixed_cadence" ]]; then
  printf '%s\n' "$fixed_cadence" >&2
  echo "Active skills must use complete project-defined cron commands, not fixed cron literals or ellipses." >&2
  exit 1
fi

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

  openai_yaml="$skill_dir/agents/openai.yaml"
  if [[ ! -f "$openai_yaml" ]]; then
    echo "$skill_dir is missing agents/openai.yaml" >&2
    exit 1
  fi
  if [[ $(sed -n '1p' "$openai_yaml") != "interface:" ]]; then
    echo "$openai_yaml must start with interface:" >&2
    exit 1
  fi

  display_name=$(awk -F'"' '/^[[:space:]]+display_name:[[:space:]]*"/ { print $2; found = 1 } END { if (!found) exit 1 }' "$openai_yaml") || {
    echo "$openai_yaml is missing quoted interface.display_name" >&2
    exit 1
  }
  short_description=$(awk -F'"' '/^[[:space:]]+short_description:[[:space:]]*"/ { print $2; found = 1 } END { if (!found) exit 1 }' "$openai_yaml") || {
    echo "$openai_yaml is missing quoted interface.short_description" >&2
    exit 1
  }
  default_prompt=$(awk -F'"' '/^[[:space:]]+default_prompt:[[:space:]]*"/ { print $2; found = 1 } END { if (!found) exit 1 }' "$openai_yaml") || {
    echo "$openai_yaml is missing quoted interface.default_prompt" >&2
    exit 1
  }
  if [[ -z "$display_name" ]]; then
    echo "$openai_yaml interface.display_name must not be empty" >&2
    exit 1
  fi
  if [[ "$display_name" != "$skill_name" ]]; then
    echo "$openai_yaml interface.display_name must match skill name: $skill_name" >&2
    exit 1
  fi
  short_len=${#short_description}
  if (( short_len < 25 || short_len > 64 )); then
    echo "$openai_yaml interface.short_description must be 25-64 characters: $short_len" >&2
    exit 1
  fi
  if [[ "$default_prompt" != *"\$$skill_name"* ]]; then
    echo "$openai_yaml interface.default_prompt must mention \$$skill_name" >&2
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
