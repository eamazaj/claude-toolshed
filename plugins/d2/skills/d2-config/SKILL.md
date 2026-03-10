---
name: d2-config
description: Change theme, layout engine, sketch mode, or check plugin dependencies
argument-hint: [setting value]
allowed-tools: Read, Bash, Write
---

# /d2-config

User request: "$ARGUMENTS"

## Task

Interactive config wizard: view and update D2 plugin settings, or run a dependency health check.

## Config file

All settings are stored in `.claude/d2.json` in the current project directory.

Default values (used when file does not exist):

```json
{
  "theme_id": 0,
  "layout": "dagre",
  "sketch": false,
  "output_directory": "./diagrams",
  "auto_validate": true,
  "auto_render": false,
  "output_format": "svg"
}
```

## Process

### Step 1: Resolve Plugin Path

```bash
PLUGIN_DIR=$(find "$HOME/.claude/plugins/cache" -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
[ -z "$PLUGIN_DIR" ] && PLUGIN_DIR=$(find "$HOME" -maxdepth 8 -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
```

### Step 2: Read current config

If `.claude/d2.json` exists, read it. Otherwise use defaults above.

### Step 3: If argument provided

If the user passed arguments (e.g. `theme_id 200` or `layout elk`), apply directly:

- Parse as `{setting} {value}`
- Validate value is allowed (see options below)
- Update `.claude/d2.json`
- Confirm: "✅ {setting} set to {value}"
- Done.

### Step 4: If no argument — show interactive menu

Display:

```
Current config (.claude/d2.json):

  1. theme_id           → {current}   (D2 theme ID — see list below)
  2. layout             → {current}   (dagre | elk | tala)
  3. sketch             → {current}   (true | false — hand-drawn style)
  4. output_directory   → {current}
  5. auto_validate      → {current}   (true | false)
  6. auto_render        → {current}   (true | false)
  7. output_format      → {current}   (svg | png)
  8. Run health check

What would you like to change? (enter 1-8)
```

### Step 5: Handle selection

**If 1 (theme_id):**

```
Available D2 themes:

  Light/Neutral:
    0 — Neutral             clean, minimal, default
    3 — Terrastruct         official D2 theme, polished
    4 — Cool Classics       muted blues and greens
    5 — Mixed Berry Blue    vibrant blue tones
    8 — Colorblind Clear    accessible palette

  Warm/Accent:
  100 — Vanilla Nitro Cola  warm cream/caramel
  101 — Orange Creamsicle   orange and cream

  Dark:
    1 — Neutral Dark        inverted neutral
  200 — Dark Mauve          dark purple tones

  Terminal:
  300 — Terminal            monochrome terminal
  301 — Terminal Grayscale  grayscale terminal

Enter theme ID (e.g. 0, 200, 300):
```

Update `theme_id` in `.claude/d2.json`.

**If 2 (layout engine):**

```
Available layout engines:

  dagre — fast, simple directed graphs (default, always available)
  elk   — complex diagrams, better spacing for many nodes (always available)
  tala  — multi-directional nested layouts (requires: brew install tala)

Enter: dagre | elk | tala
```

Update `layout` in `.claude/d2.json`.

**If 3 (sketch):** Toggle true/false. Update config.

Note: sketch mode is NOT compatible with ER diagrams (sql_table shapes). The d2-er specialist always overrides this to false.

**If 4 (output_directory):** Ask for path. Update config.

Special values:

- `"same"` — save output in the same directory as the input file. Falls back to `./diagrams` when there is no input file reference.

**If 5 (auto_validate):** Toggle true/false. Update config.

**If 6 (auto_render):** Toggle true/false. Update config.

Note: PNG rendering requires Playwright. If auto_render is enabled and output_format is `png`, run a health check to verify Playwright is available.

**If 7 (output_format):**

```
Available formats:
  svg — vector, works everywhere Git renders Markdown (recommended)
  png — raster image, requires Playwright headless browser

Enter: svg | png
```

Update `output_format` in `.claude/d2.json`.

**If 8 (health check):** See Health Check section below.

### Step 6: Write updated config

Create `.claude/` directory if it doesn't exist:

```bash
mkdir -p .claude
```

Write updated settings to `.claude/d2.json` (merge with existing, don't overwrite unrelated keys).

Confirm: "✅ Config saved to .claude/d2.json"

---

## Health Check

Run when user selects option 8.

### Check 1: d2 binary

```bash
which d2 && d2 --version 2>&1
```

✅ if found and prints version | ❌ if not found → show install instructions:

```
Install d2:
  macOS:   brew install d2
  Go:      go install oss.terrastruct.com/d2@latest
  Script:  curl -fsSL https://d2lang.com/install.sh | sh -s --
```

### Check 2: Render smoke test

```bash
printf 'vars: { d2-config: { theme-id: 0 } }\na -> b: hello' > /tmp/d2-health-check.d2
d2 /tmp/d2-health-check.d2 /tmp/d2-health-check.svg 2>&1
```

✅ if exit 0 and `/tmp/d2-health-check.svg` contains `<svg` | ❌ if error → show the error message

### Check 3: PNG support (only if output_format is "png")

```bash
d2 /tmp/d2-health-check.d2 /tmp/d2-health-check.png 2>&1
```

✅ if exit 0 | ❌ if error about Playwright → "PNG requires Playwright: `npm install -g playwright && playwright install chromium`"

### Output format

```
D2 plugin — dependency check

  ✅ d2 v0.6.x             installed
  ✅ Render smoke test      SVG generated OK
  ✅ PNG support            Playwright available

Features:
  ✅ Generate diagrams    ✅ Validate    ✅ Render SVG    ✅ Render PNG
```
