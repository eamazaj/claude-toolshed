#!/usr/bin/env bash
# ensure-deps.sh — verify d2 CLI binary is installed
#
# Called from skill SKILL.md before any d2 commands.
# Exits 0 if d2 is available, exits 1 with install instructions if not.

set -euo pipefail

if ! command -v d2 &>/dev/null; then
  echo "❌ d2 not found. Install it first:" >&2
  echo "" >&2
  echo "  macOS:   brew install d2" >&2
  echo "  Go:      go install oss.terrastruct.com/d2@latest" >&2
  echo "  Script:  curl -fsSL https://d2lang.com/install.sh | sh -s --" >&2
  echo "" >&2
  echo "After installing, re-run the command." >&2
  exit 1
fi
