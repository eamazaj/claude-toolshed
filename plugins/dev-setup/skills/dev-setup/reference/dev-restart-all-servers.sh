#!/usr/bin/env bash
# dev-restart-all-servers.sh — Stop all dev servers and restart detached tmux services.
#
# Usage:
#   pnpm dev:restart
#   bash tools/dev/dev-restart-all-servers.sh
#
# Stops all running servers (see dev-stop-all-servers.sh), then launches a full
# 3-pane tmux session in detached mode via dev-tmux-start.sh.
# Aborts if stop fails (port held by non-node process).
#
# Exit codes:
#   0  Restart completed (tmux session running detached)
#   1  Stop phase failed due to non-managed process/port conflict
#
# Requires: bash, tmux, pnpm, lsof
# Context:  Recommended reset workflow for local development sessions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/dev-stop-all-servers.sh"
exec bash "$SCRIPT_DIR/dev-tmux-start.sh"
