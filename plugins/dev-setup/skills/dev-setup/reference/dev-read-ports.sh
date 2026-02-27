#!/usr/bin/env bash
# dev-read-ports.sh — Read dev server ports for the current worktree.
#
# Usage (sourced only — do not call directly):
#   source tools/dev/dev-read-ports.sh
#   # Exports: API_PORT, WEB_PORT, STORYBOOK_PORT
#
# Reads from (first match wins):
#   .wt-ports.env → .env → .env.example → main worktree .env → hardcoded defaults
#
# Exported variables:
#   API_PORT     API server port (from PORT key)
#   WEB_PORT     Web app dev server port
#   STORYBOOK_PORT   Storybook component explorer port
#
# Requires: bash, grep, cut
# Context:  Shared utility sourced by dev lifecycle scripts.

# shellcheck shell=bash

# Note: intentionally no 'set -euo pipefail' — this file is sourced only.
# Adding strict mode here would enable it in the calling shell, which is undesirable.

_read_env() {
  local var="$1" default="$2" file dir
  # Search local files first
  for file in .wt-ports.env .env .env.example; do
    if [[ -f "$file" ]]; then
      local val
      val=$(grep -E "^${var}=" "$file" | head -1 | cut -d= -f2)
      if [[ -n "$val" ]]; then
        echo "$val"
        return
      fi
    fi
  done
  # Fallback: check main worktree (parent repo) if we're in a linked worktree
  dir=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/^worktree //')
  if [[ -n "$dir" && "$dir" != "$(pwd)" ]]; then
    for file in "$dir/.env" "$dir/.env.example"; do
      if [[ -f "$file" ]]; then
        local val
        val=$(grep -E "^${var}=" "$file" | head -1 | cut -d= -f2)
        if [[ -n "$val" ]]; then
          echo "$val"
          return
        fi
      fi
    done
  fi
  echo "$default"
}

API_PORT=$(_read_env PORT 3000)
WEB_PORT=$(_read_env WEB_PORT 5173)
STORYBOOK_PORT=$(_read_env STORYBOOK_PORT 61000)
TTYD_PORT=$(_read_env TTYD_PORT 7681)

export API_PORT WEB_PORT STORYBOOK_PORT TTYD_PORT
