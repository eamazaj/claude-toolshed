#!/usr/bin/env bash
# dev-stop-all-servers.sh — Stop all dev servers for the current worktree.
#
# Usage:
#   pnpm dev:stop
#   bash tools/dev/dev-stop-all-servers.sh
#
# Output: key=value lines, no ANSI colours, LLM-parseable.
# Exit:   0 — all services killed or already stopped
#         1 — at least one port held by a non-node process

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=dev-read-ports.sh
source "$SCRIPT_DIR/dev-read-ports.sh"

# shellcheck source=dev-session-name.sh
source "$SCRIPT_DIR/dev-session-name.sh"
SESSION="$(dev_session_name)"

_stop_service() {
  local name="$1" port="$2"
  local pid
  pid=$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null | head -n1 || true)

  if [[ -z "$pid" ]]; then
    echo "STOP SERVICE=$name PORT=$port RESULT=skipped REASON=already-stopped"
    return 0
  fi

  local cmd
  cmd=$(basename "$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")")

  if [[ ! "$cmd" =~ ^(node|pnpm|vite)$ ]]; then
    echo "STOP SERVICE=$name PORT=$port RESULT=failed REASON=\"port held by $cmd (pid=$pid)\""
    return 1
  fi

  kill "$pid" 2>/dev/null || true

  local _
  for _ in 1 2 3; do
    sleep 1
    if ! lsof -ti :"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      break
    fi
  done

  if lsof -ti :"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "STOP SERVICE=$name PORT=$port RESULT=failed REASON=process-still-running PID=$pid"
    return 1
  fi

  echo "STOP SERVICE=$name PORT=$port RESULT=killed PID=$pid"
  return 0
}

errors=0
_stop_service api "$API_PORT" || ((errors++)) || true
_stop_service web "$WEB_PORT" || ((errors++)) || true
_stop_service storybook "$STORYBOOK_PORT" || ((errors++)) || true

if ((errors > 0)); then
  echo "STOP RESULT=error FAILED=${errors} REASON=non-node-process TMUX=preserved"
  exit 1
fi

# Stop ttyd if running on TTYD_PORT
_ttyd_pid=$(lsof -ti :"$TTYD_PORT" -sTCP:LISTEN 2>/dev/null | head -n1 || true)
if [[ -n "$_ttyd_pid" ]]; then
  kill "$_ttyd_pid" 2>/dev/null || true
  echo "STOP TTYD=:$TTYD_PORT RESULT=killed PID=$_ttyd_pid"
else
  echo "STOP TTYD=:$TTYD_PORT RESULT=skipped REASON=already-stopped"
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
  echo "STOP TMUX=$SESSION RESULT=killed"
else
  echo "STOP TMUX=$SESSION RESULT=skipped REASON=no-session"
fi
