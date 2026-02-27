---
name: mermaid-render
description: Render .mmd or .md files to SVG images
argument-hint: [path]
allowed-tools: Read, Bash, Write
---

# /mermaid-render

User request: "$ARGUMENTS"

## Task

Render Mermaid diagrams from an existing `.mmd` file or a `.md` file with Mermaid blocks to SVG image files.

## Process

1. **Resolve Plugin Path**:

   ```bash
   find "$HOME/.claude/plugins/cache" -type d -name "mermaid" -path "*/skills/mermaid" 2>/dev/null | head -1
   ```

   If empty, run fallback:

   ```bash
   find "$HOME" -maxdepth 8 -type d -name "mermaid" -path "*/skills/mermaid" 2>/dev/null | head -1
   ```

   Use the returned path as `PLUGIN_DIR`.

2. **Ensure Dependencies**:

   ```bash
   bash "$PLUGIN_DIR/scripts/ensure-deps.sh"
   ```

   If `.claude/mermaid.json` does **not** exist, display a one-time nudge before continuing:

   > First time using the mermaid plugin? Run `/mermaid-config` to pick a theme and output settings. Using defaults for now (zinc-light, `./diagrams`).

3. **Read Config**: If `.claude/mermaid.json` exists, read:
   - `theme` (default: zinc-light)
   - `output_directory` (default: ./diagrams)
   - `output_format` (default: svg)

   **Resolve output path:**
   - If `output_directory` is `"same"` AND an input file path is known:
     `OUTPUT_DIR=$(dirname {input_file})`
   - If `output_directory` is `"same"` AND no argument was provided:
     `OUTPUT_DIR=./diagrams`
   - Otherwise:
     `OUTPUT_DIR=<output_directory from config>`

4. **Determine Input**:
   - `.mmd` file → render directly
   - `.md` file → extract Mermaid blocks first:
     `node "$PLUGIN_DIR/scripts/extract_mermaid.js" {file}`
   - Directory → find all `.mmd` files:
     `find {dir} -name "*.mmd" -not -path "*/node_modules/*"`
   - No argument → ask: "Which file or directory should I render?"

5. **Render**:
   Run for each input file. `resilient_diagram.js` renders SVG via beautiful-mermaid and maps errors to troubleshooting.md.

   **Theme handling:**
   - If `theme == "custom"` and `themeVariables` is present in config:

     ```bash
     node "$PLUGIN_DIR/scripts/resilient_diagram.js" {input_file} --output-dir $OUTPUT_DIR --custom-theme '{"bg":"#...","fg":"#..."}'
     ```

     Pass the serialized `themeVariables` JSON as the `--custom-theme` value.
   - If `theme == "custom"` but `themeVariables` is absent from config: render without custom theme and display a note:
     > Custom theme configured but no themeVariables found — run `/mermaid-config` → option 6 to define colors.
   - Otherwise:

     ```bash
     node "$PLUGIN_DIR/scripts/resilient_diagram.js" {input_file} --output-dir $OUTPUT_DIR --theme {theme}
     ```

6. **Report**:
   - List all output files generated with full paths
   - If rendering failed: "Run `/mermaid-config` → health check to diagnose missing dependencies."

## Output

```
Rendered 3 diagrams:
  ✅ diagrams/sequence-auth.svg
  ✅ diagrams/er-users.svg
  ✅ diagrams/architecture.svg
```
