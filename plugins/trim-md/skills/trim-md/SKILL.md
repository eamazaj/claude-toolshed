---
name: trim-md
description: Trim markdown for LLM consumption — remove token waste, normalize structure
argument-hint: [--dry-run] <paths...>
allowed-tools: Bash, Glob, Read
---

# /trim-md

User request: "$ARGUMENTS"

## Task

Trim and optimize markdown files for LLM/agent consumption. Run the trim-md script on the given paths, then present the output.

## Opt-out

Files containing `<!-- trim-md:disable -->` on its own line are excluded. The comment must be a standalone line — inline mentions in prose or code blocks are ignored.

## Process

### Step 1: Resolve skill directory

```bash
SKILL_DIR="$(find "$HOME/.claude/plugins/cache" -type d -name "trim-md" -path "*/skills/trim-md" 2>/dev/null | head -1)"
[[ -z "$SKILL_DIR" ]] && SKILL_DIR="$(find "$HOME" -maxdepth 8 -type d -name "trim-md" -path "*/skills/trim-md" 2>/dev/null | head -1)"
echo "SKILL_DIR=$SKILL_DIR"
```

If `SKILL_DIR` is empty, stop with: "Could not locate the trim-md skill directory. Ensure the plugin is installed."

### Step 2: Ensure dependencies

```bash
bash "$SKILL_DIR/scripts/ensure-deps.sh"
```

If the script exits with an error, show the missing dependency message to the user and stop.

### Step 3: Run trim-md

Parse `$ARGUMENTS` for paths and the dry-run flag.

**Dry-run detection:** If `$ARGUMENTS` contains any of these tokens (case-insensitive): `dry`, `dry-run`, `--dry-run`, `dryrun` — pass `--dry-run` to the script. Remove the token from the path list.

Remaining arguments are the target paths. If no paths remain, use `.` (current directory).

```bash
bash "$SKILL_DIR/scripts/trim-md.sh" [--dry-run] <paths>
```

### Step 4: Present output

Show the script output to the user as-is. No additional commentary needed unless there were errors.
