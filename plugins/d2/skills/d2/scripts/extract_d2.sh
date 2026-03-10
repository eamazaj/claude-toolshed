#!/usr/bin/env bash
# extract_d2.sh — extract ```d2 code blocks from a Markdown file
#
# Usage:
#   ./extract_d2.sh <file.md>
#
# Writes each D2 block to a temp file and prints the file paths.
# Used by d2-validate to check D2 blocks embedded in Markdown.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <file.md>" >&2
  exit 1
fi

INPUT="$1"

if [[ ! -f "$INPUT" ]]; then
  echo "Error: file not found: $INPUT" >&2
  exit 1
fi

TMPDIR_BASE="${TMPDIR:-/tmp}/d2-extract-$$"
mkdir -p "$TMPDIR_BASE"

# Extract ```d2 ... ``` blocks using awk
awk '
  /^```d2/ { in_block=1; block_count++; tmpfile=ENVIRON["TMPDIR_BASE"] "/block-" block_count ".d2"; next }
  /^```/ && in_block { in_block=0; print tmpfile; next }
  in_block { print > tmpfile }
' TMPDIR_BASE="$TMPDIR_BASE" "$INPUT"
