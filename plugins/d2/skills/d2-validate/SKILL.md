---
name: d2-validate
description: Validate D2 syntax in .d2 files or directories
argument-hint: [path]
allowed-tools: Read, Bash, Glob
---

# /d2-validate

User request: "$ARGUMENTS"

## Task

Validate D2 syntax in `.d2` files or `.md` files containing D2 code blocks.

## Process

### Step 1: Resolve Plugin Path

```bash
PLUGIN_DIR=$(find "$HOME/.claude/plugins/cache" -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
[ -z "$PLUGIN_DIR" ] && PLUGIN_DIR=$(find "$HOME" -maxdepth 8 -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
```

### Step 2: Ensure D2 is installed

```bash
bash "$PLUGIN_DIR/scripts/ensure-deps.sh"
```

### Step 3: Determine Input

From `$ARGUMENTS`:

- **`.d2` file** → validate directly
- **`.md` file** → extract D2 blocks first with `extract_d2.sh`, then validate each
- **Directory** → find all `.d2` files and `.md` files with D2 blocks
- **No argument** → ask: "Which file or directory should I validate?"

### Step 4: Collect Files to Validate

**For `.d2` files:**

```bash
# Validate directly
d2 validate {file.d2}
```

**For `.md` files:**

```bash
# Extract D2 blocks to temp files
bash "$PLUGIN_DIR/scripts/extract_d2.sh" {file.md}
# Then validate each extracted temp file
d2 validate {temp_file}
```

**For directories:**

```bash
# Find all .d2 files
find {dir} -name "*.d2" -not -path "*/node_modules/*" -not -path "*/.git/*"

# Find .md files containing d2 blocks
grep -rl '```d2' {dir} --include="*.md" 2>/dev/null
```

### Step 5: Validate Each File

For each file:

```bash
d2 validate {file} 2>&1
# Exit 0 = valid, non-zero = error
```

Track: filename, pass/fail, error message (if any).

### Step 6: Report Results

```
Validated {N} diagrams:

  ✅ diagrams/architecture-services-20260310.d2
  ✅ diagrams/sequence-auth-flow-20260310.d2
  ❌ docs/design.md (block 2) — unexpected token at line 14: missing closing brace
```

If any failures:

```
{N} validation error(s) found.
See $PLUGIN_DIR/references/guides/troubleshooting.md for fixes.
```

If all pass:

```
All {N} diagrams valid ✅
```

## Output Summary Format

```
D2 Validation Summary
─────────────────────
Path: {input_path}
Files checked: {N}
Passed: {N}    Failed: {N}

{per-file results}

{troubleshooting hint if any failures}
```
