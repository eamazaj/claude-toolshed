#!/bin/bash
# posttool-trim-md.sh — Auto-format markdown files after Write/Edit.
#
# Triggered by PostToolUse hook on Write|Edit events.
# Reads file path from the hook JSON payload on stdin.
# Runs markdownlint --fix + table compaction on .md files only.
#
# Requires: npx (for markdownlint-cli2)

# Extract file_path from hook JSON payload without jq.
# Tries tool_input.file_path first, then tool_response.filePath.
PAYLOAD=$(cat)
FILE=$(echo "$PAYLOAD" | grep -o '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')
[[ -z "$FILE" ]] && FILE=$(echo "$PAYLOAD" | grep -o '"filePath"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')

# Skip if no file path or not a markdown file
[[ -z "$FILE" ]] && exit 0
[[ "$FILE" == *.md ]] || exit 0
[[ -f "$FILE" ]] || exit 0

# Resolve plugin root (set by Claude Code when running plugin hooks)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPT="$PLUGIN_ROOT/skills/trim-md/scripts/trim-md.sh"

[[ -x "$SCRIPT" ]] || [[ -f "$SCRIPT" ]] || exit 0

bash "$SCRIPT" "$FILE" >/dev/null 2>&1 || true
