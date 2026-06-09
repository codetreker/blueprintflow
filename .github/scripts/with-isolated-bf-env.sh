#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "usage: with-isolated-bf-env.sh <command> [args...]" >&2
  exit 2
fi

tmp_root=$(mktemp -d -t bf-isolated-XXXXXX)
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

export HOME="$tmp_root/home"
export CODEX_HOME="$HOME/codex"
export BF_HOME="$HOME/bf-state"
mkdir -p "$HOME" "$CODEX_HOME" "$BF_HOME"

set +e
"$@"
rc=$?
set -e
exit "$rc"
