#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
plugin_root="$repo_root/plugins/blueprintflow"
codex_marketplace="$repo_root/.agents/plugins/marketplace.json"
claude_marketplace="$repo_root/.claude-plugin/marketplace.json"

test -f "$codex_marketplace"
test -f "$claude_marketplace"
test -f "$plugin_root/.codex-plugin/plugin.json"
test -f "$plugin_root/.claude-plugin/plugin.json"
test -d "$plugin_root/skills"

if test -e "$repo_root/.codex-plugin" || test -e "$repo_root/skills" || test -e "$repo_root/.claude-plugin/plugin.json"; then
  echo "Root skills/, .codex-plugin/, and .claude-plugin/plugin.json must not exist; use plugins/blueprintflow/." >&2
  exit 1
fi

jq -e '.plugins[] | select(.name == "blueprintflow") | .source.path == "./plugins/blueprintflow"' \
  "$codex_marketplace" >/dev/null
jq -e '.plugins[] | select(.name == "blueprintflow") | .source == "./plugins/blueprintflow"' \
  "$claude_marketplace" >/dev/null

claude_version=$(jq -r '.version' "$plugin_root/.claude-plugin/plugin.json")
codex_version=$(jq -r '.version' "$plugin_root/.codex-plugin/plugin.json")
if [[ "$claude_version" != "$codex_version" ]]; then
  echo "Manifest version mismatch: Claude=$claude_version Codex=$codex_version" >&2
  exit 1
fi

echo "Plugin layout is valid"
