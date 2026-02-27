#!/usr/bin/env bash
# dev-tmux-start.sh — Start (or reuse) a detached tmux dev session.
#
# Usage:
#   pnpm dev:start
#   bash tools/dev/dev-tmux-start.sh
#
# Behavior:
# - Reuses an existing tmux session for the current branch when available.
# - Otherwise creates a detached 3-pane session and starts API, Web, and Storybook.
# - Reads ports from .wt-ports.env (wt worktrees) or .env/.env.example.
# - On port-validation failure, prints current `dev:status` output before exit.
#
# Exit codes:
#   0  Session exists or started successfully (detached)
#   1  Missing dependency, invalid port configuration, or startup failure
#
# Requires: bash, tmux, pnpm, lsof
# Context:  Use in restart/start workflows where UI attach should stay optional.

set -euo pipefail

readonly WORKDIR="$PWD"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=dev-session-name.sh
source "$SCRIPT_DIR/dev-session-name.sh"
SESSION="$(dev_session_name)"
readonly SESSION

for cmd in tmux pnpm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
done

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "TMUX=$SESSION RESULT=running ATTACHED=false"
  exit 0
fi

# Read configured ports (exports API_PORT, WEB_PORT, STORYBOOK_PORT)
# shellcheck source=dev-read-ports.sh
source "$SCRIPT_DIR/dev-read-ports.sh"

# Validate distinct/free ports before creating a new tmux session.
if ! bash "$SCRIPT_DIR/dev-check-ports.sh"; then
  echo ""
  echo "START RESULT=failed REASON=port-validation-failed"
  echo "Current service status:"
  bash "$SCRIPT_DIR/dev-servers-status.sh"
  echo ""
  echo "Hint: run 'pnpm dev:stop' then 'pnpm dev:start' for a clean tmux-managed session." >&2
  exit 1
fi

tmux new-session -d -s "$SESSION" -n dev -c "$WORKDIR"
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "

tmux split-window -h -t "$SESSION" -c "$WORKDIR"
tmux split-window -h -t "$SESSION" -c "$WORKDIR"
tmux select-layout -t "$SESSION" even-horizontal

tmux select-pane -t "$SESSION:dev.1" -T "api  :${API_PORT}"
tmux select-pane -t "$SESSION:dev.2" -T "web  :${WEB_PORT}"
tmux select-pane -t "$SESSION:dev.3" -T "storybook :${STORYBOOK_PORT}"

tmux send-keys -t "$SESSION:dev.1" "clear" Enter
tmux send-keys -t "$SESSION:dev.2" "clear" Enter
tmux send-keys -t "$SESSION:dev.3" "clear" Enter

tmux send-keys -t "$SESSION:dev.1" "PORT=${API_PORT} pnpm dev:back" Enter
tmux send-keys -t "$SESSION:dev.2" "VITE_API_PORT=${API_PORT} WEB_PORT=${WEB_PORT} pnpm dev:front" Enter
tmux send-keys -t "$SESSION:dev.3" "VITE_API_PORT=${API_PORT} STORYBOOK_PORT=${STORYBOOK_PORT} pnpm dev:storybook" Enter

# Start ttyd (read-only browser view of the tmux session)
if command -v ttyd >/dev/null 2>&1; then
  # Kill stale ttyd on this port if any
  lsof -ti :"$TTYD_PORT" -sTCP:LISTEN 2>/dev/null | xargs kill 2>/dev/null || true
  sleep 0.3
  ttyd -p "$TTYD_PORT" -R tmux attach -t "$SESSION" >/dev/null 2>&1 &
  disown
  echo "TTYD=http://localhost:$TTYD_PORT RESULT=started"
else
  echo "TTYD=none RESULT=skipped REASON=ttyd-not-installed"
fi

echo "TMUX=$SESSION RESULT=started ATTACHED=false"
