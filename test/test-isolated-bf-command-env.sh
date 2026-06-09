#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

STDOUT=$(bash "$REPO_ROOT/.github/scripts/with-isolated-bf-env.sh" bash -c '
  set -euo pipefail
  [ -d "$HOME" ]
  [ -d "$CODEX_HOME" ]
  [ -d "$BF_HOME" ]
  tmp_root=$(dirname "$HOME")
  case "$(basename "$tmp_root")" in bf-isolated-*) ;; *) echo "bad HOME=$HOME"; exit 1 ;; esac
  case "$CODEX_HOME" in "$HOME"/*) ;; *) echo "CODEX_HOME not under HOME"; exit 1 ;; esac
  case "$BF_HOME" in "$HOME"/*) ;; *) echo "BF_HOME not under HOME"; exit 1 ;; esac
  printf "isolated\n"
' 2>&1)
RC=$?

assert_eq "$RC" "0" "isolated helper exits 0"
assert_eq "$STDOUT" "isolated" "isolated helper output"

pass
