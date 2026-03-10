---
name: d2-render
description: Render .d2 files to SVG or PNG images
argument-hint: [path]
allowed-tools: Read, Bash, Write
---

# /d2-render

User request: "$ARGUMENTS"

## Task

Render D2 diagrams from an existing `.d2` file or a `.md` file with D2 code blocks to SVG or PNG images.

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

If `.claude/d2.json` does **not** exist, display a one-time nudge before continuing:

> First time using the d2 plugin? Run `/d2-config` to pick a theme and output settings. Using defaults for now (theme 0 / Neutral, `./diagrams`).

### Step 3: Read Config

If `.claude/d2.json` exists, read:

- `output_directory` (default: ./diagrams)
- `output_format` (default: svg)

**Resolve output path:**

- If `output_directory` is `"same"` AND input file path is known:
  `OUTPUT_DIR=$(dirname {input_file})`
- If `output_directory` is `"same"` AND no input file:
  `OUTPUT_DIR=./diagrams`
- Otherwise:
  `OUTPUT_DIR={output_directory}`

### Step 4: Determine Input

From `$ARGUMENTS`:

- **`.d2` file** → render directly
- **`.md` file** → extract D2 blocks first:
  `bash "$PLUGIN_DIR/scripts/extract_d2.sh" {file.md}`
- **Directory** → find all `.d2` files:
  `find {dir} -name "*.d2" -not -path "*/node_modules/*"`
- **No argument** → ask: "Which file or directory should I render?"

### Step 5: Render

Run for each `.d2` file:

```bash
mkdir -p {OUTPUT_DIR}
d2 {input_file} {OUTPUT_DIR}/{basename}.{output_format}
```

**For PNG output:** Warn the user if PNG fails that it requires Playwright:

```
PNG rendering failed. Playwright is required for PNG export.
Install: npm install -g playwright && playwright install chromium
Or switch to SVG: /d2-config → option 7
```

**Note:** Generated `.d2` files already contain the `vars { d2-config }` block with the theme and layout settings — no additional CLI flags are needed. The `d2` command will use the embedded configuration automatically.

### Step 6: Report

List all output files generated with full paths:

```
Rendered {N} diagrams:
  ✅ diagrams/architecture-services-20260310.svg
  ✅ diagrams/sequence-auth-flow-20260310.svg
```

If any rendering failed:

```
  ❌ diagrams/er-schema-20260310.svg — {error message}

Run /d2-config → health check to diagnose issues.
```

## Output Format

```
Rendered {N} / {total} diagrams:

  ✅ {output_path_1}
  ✅ {output_path_2}
  ❌ {output_path_3} — {error}
```
