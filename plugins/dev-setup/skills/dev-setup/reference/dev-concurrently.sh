#!/usr/bin/env bash
# dev-concurrently.sh — Start all dev servers via concurrently with worktree-aware ports.
#
# Usage:
#   pnpm dev
#   bash tools/dev/dev-concurrently.sh
#
# Reads ports from .wt-ports.env → .env → .env.example (first match wins),
# checks they are free, then launches API + Web + Storybook with the correct ports.
#
# Exit codes:
#   0  Process started successfully (then inherited from concurrently)
#   1  Port validation or command startup failed
#
# Requires: bash, pnpm, lsof
# Context:  Run on local dev machine when you want all dev services in one
#           terminal process (non-tmux workflow).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Read and verify ports (exports API_PORT, WEB_PORT, STORYBOOK_PORT)
# shellcheck source=dev-check-ports.sh
source "$SCRIPT_DIR/dev-check-ports.sh"

exec pnpm exec concurrently \
  -n api,web,storybook \
  -c blue,cyan,magenta \
  "PORT=${API_PORT} pnpm dev:back" \
  "VITE_API_PORT=${API_PORT} WEB_PORT=${WEB_PORT} pnpm dev:front" \
  "VITE_API_PORT=${API_PORT} STORYBOOK_PORT=${STORYBOOK_PORT} pnpm dev:storybook"
