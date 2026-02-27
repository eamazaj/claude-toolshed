#!/usr/bin/env bash
# dev-tmux.sh — Attach to an existing tmux dev session.
#
# Usage:
#   pnpm dev:tmux
#   bash tools/dev/dev-tmux.sh
#
# Behavior:
# - Attaches to an existing tmux session for the current branch.
# - Does not create or start services.
#
# Exit codes:
#   0  Session attached successfully
#   1  Missing dependency or no running tmux session
#
# Requires: bash, tmux
# Context:  Run on local dev machine when services are already running in tmux.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=dev-session-name.sh
source "$SCRIPT_DIR/dev-session-name.sh"
SESSION="$(dev_session_name)"
readonly SESSION

if ! command -v tmux >/dev/null 2>&1; then
  echo "Error: required command not found: tmux" >&2
  exit 1
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Attaching to existing session: $SESSION"
  tmux attach -t "$SESSION"
  exit 0
fi

echo "Error: tmux session not found: $SESSION" >&2
echo "Hint: run 'pnpm dev:restart' (or 'pnpm dev:start') first." >&2
exit 1
