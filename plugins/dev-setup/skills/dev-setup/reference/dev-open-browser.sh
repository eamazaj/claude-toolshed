#!/usr/bin/env bash
# dev-open-browser.sh — Open a Chrome profile with one tab per running dev server.
#
# Usage:
#   pnpm dev:browser                    # uses CHROME_PROFILE from env
#   pnpm dev:browser my-launcher        # override with a specific launcher script
#   bash tools/dev/dev-open-browser.sh [launcher-name]
#
# Reads running services from dev:status output and opens a tab for each one.
# Only opens tabs for services with STATUS=running.
# Warns about stopped services and missing optional tools (ttyd).
#
# Profile resolution (first match wins):
#   1. CLI argument ($1)
#   2. CHROME_PROFILE from .wt-ports.env → .env → .env.example
#
# CHROME_PROFILE must be the name of a launcher script on PATH
# (created by tools/dev/chrome-profile-setup.sh).
#
# Requires: bash, lsof (via dev-servers-status.sh)
# Context:  Run after pnpm dev:start to open the app in a browser.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Resolve Chrome launcher ─────────────────────────────────────────────────

# shellcheck source=dev-read-ports.sh
source "$SCRIPT_DIR/dev-read-ports.sh"

LAUNCHER="${1:-$(_read_env CHROME_PROFILE "")}"

if [[ -z "$LAUNCHER" ]]; then
  echo "ERROR: No Chrome profile configured." >&2
  echo "Set CHROME_PROFILE in .env or pass a launcher name as argument." >&2
  echo "Run 'pnpm dev:browser:setup' to create a profile." >&2
  exit 1
fi

if ! command -v "$LAUNCHER" &>/dev/null; then
  echo "ERROR: '$LAUNCHER' not found in PATH." >&2
  echo "Run 'pnpm dev:browser:setup' to create it." >&2
  exit 1
fi

# ── Parse dev:status once ────────────────────────────────────────────────────
# api → open /docs (Scalar API reference) instead of blank root
# ttyd → log viewer (browser terminal)
# web, storybook → open as-is

URLS=()
WARNINGS=()
API_KEY=""
API_URL=""
STATUS_OUTPUT=$(bash "$PROJECT_DIR/tools/dev/dev-servers-status.sh")

# URL-encode a string (percent-encoding for query params)
_urlencode() {
  local string="$1" i c
  for ((i = 0; i < ${#string}; i++)); do
    c="${string:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
      *) printf '%%%02X' "'$c" ;;
    esac
  done
}

# First pass: extract API key and API port for web URL params
while IFS= read -r line; do
  if [[ "$line" =~ ^APP_API_KEY=(.+)$ ]]; then
    API_KEY="${BASH_REMATCH[1]}"
  fi
  if [[ "$line" =~ ^SERVICE=api\ PORT=([^ ]+)\ STATUS=running ]]; then
    API_URL="http://localhost:${BASH_REMATCH[1]}"
  fi
done <<<"$STATUS_OUTPUT"

# Second pass: build URLs and warnings
while IFS= read -r line; do
  if [[ "$line" =~ ^SERVICE=([^ ]+)\ PORT=([^ ]+)\ STATUS=([^ ]+) ]]; then
    SERVICE="${BASH_REMATCH[1]}"
    PORT="${BASH_REMATCH[2]}"
    STATUS="${BASH_REMATCH[3]}"

    if [[ "$STATUS" == "running" ]]; then
      case "$SERVICE" in
        api) URL="http://localhost:$PORT/docs" ;;
        web)
          # Pre-fill connection form with API URL and key
          URL="http://localhost:$PORT"
          local_params=""
          [[ -n "$API_URL" ]] && local_params="api_url=$(_urlencode "$API_URL")"
          [[ -n "$API_KEY" && "$API_KEY" != "not-set" ]] && local_params="${local_params:+$local_params&}api_key=$(_urlencode "$API_KEY")"
          [[ -n "$local_params" ]] && URL="$URL?$local_params"
          ;;
        *) URL="http://localhost:$PORT" ;;
      esac
      URLS+=("$URL")
      echo "  ✓ $SERVICE → $URL"
    else
      # Stopped service — provide actionable hint
      case "$SERVICE" in
        ttyd)
          if ! command -v ttyd &>/dev/null; then
            WARNINGS+=("  ⚠  $SERVICE not installed — log viewer unavailable (brew install ttyd)")
          else
            WARNINGS+=("  ⚠  $SERVICE stopped on :$PORT — restart with: pnpm dev:restart")
          fi
          ;;
        *)
          WARNINGS+=("  ⚠  $SERVICE stopped on :$PORT — restart with: pnpm dev:restart")
          ;;
      esac
    fi
  fi
done <<<"$STATUS_OUTPUT"

# Show warnings after the success lines
for warn in "${WARNINGS[@]+"${WARNINGS[@]}"}"; do
  echo "$warn"
done

if [[ ${#URLS[@]} -eq 0 ]]; then
  echo "No running services found. Start servers first with: pnpm dev:start" >&2
  exit 1
fi

# ── Launch Chrome ────────────────────────────────────────────────────────────

echo ""
echo "Opening ${#URLS[@]} tab(s) with $LAUNCHER..."
exec "$LAUNCHER" "${URLS[@]}"
