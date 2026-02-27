#!/usr/bin/env bash
# ensure-deps.sh — Check dev-setup dependencies and offer install instructions.
#
# Required: bash 4+
# Optional: lsof (port checking), tmux (session management), node/npm (JS projects)

set -euo pipefail

MISSING=()
WARNINGS=()

# bash 4+ needed for associative arrays and mapfile
BASH_MAJOR="${BASH_VERSINFO[0]:-0}"
if ((BASH_MAJOR < 4)); then
  MISSING+=("bash 4+ (current: ${BASH_VERSION:-unknown})")
fi

# lsof is needed for port allocation and checking
if ! command -v lsof >/dev/null 2>&1; then
  WARNINGS+=("lsof (port allocation/checking will use fallback)")
fi

# tmux is optional — only for session management
if ! command -v tmux >/dev/null 2>&1; then
  WARNINGS+=("tmux (multi-server session management not available)")
fi

if ((${#MISSING[@]} > 0)); then
  echo "dev-setup: missing required dependencies:" >&2
  for dep in "${MISSING[@]}"; do
    echo "  - $dep" >&2
  done
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Quick install (macOS): brew install bash" >&2
  else
    echo "Quick install (Linux): sudo apt install bash" >&2
  fi
  exit 1
fi

if ((${#WARNINGS[@]} > 0)); then
  echo "dev-setup: optional tools not found (some features limited):" >&2
  for dep in "${WARNINGS[@]}"; do
    echo "  - $dep" >&2
  done
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Install (macOS): brew install lsof tmux" >&2
  else
    echo "Install (Linux): sudo apt install lsof tmux" >&2
  fi
fi
