---
name: d2-diagram
description: Generate a D2 diagram from a text description
argument-hint: [description]
allowed-tools: Read, Bash, Write
---

# /d2-diagram

User request: "$ARGUMENTS"

## Task

Analyze the user's description, select the appropriate diagram type, and generate the diagram.

## Instructions

### Step 1: Resolve Plugin Path

```bash
PLUGIN_DIR=$(find "$HOME/.claude/plugins/cache" -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
```

If empty, run fallback (for dev/repo usage):

```bash
PLUGIN_DIR=$(find "$HOME" -maxdepth 8 -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
```

If still empty: stop and report — "Plugin not found. Is it installed?"

### Step 2: Ensure Dependencies

```bash
bash "$PLUGIN_DIR/scripts/ensure-deps.sh"
```

If `.claude/d2.json` does **not** exist, display a one-time nudge before continuing:

> First time using the d2 plugin? Run `/d2-config` to pick a theme and output settings. Using defaults for now (theme 0 / Neutral, `./diagrams`).

### Step 3: Read Config

If `.claude/d2.json` exists, read and apply:

- `theme_id` (default: 0)
- `layout` (default: "dagre")
- `sketch` (default: false)
- `output_directory` (default: ./diagrams)
- `auto_validate` (default: true)
- `auto_render` (default: false)

**Resolve output path:**

- If `output_directory` is `"same"` AND an input file is known: `OUTPUT_DIR=$(dirname {input_file})`
- If `output_directory` is `"same"` AND no input file: `OUTPUT_DIR=./diagrams`
- Otherwise: `OUTPUT_DIR={output_directory}`

### Step 4: Analyze User Description

**Analyze the request semantically** — interpret intent regardless of language:

| What the user wants to show | Type |
|---|---|
| API calls, request/response, service-to-service communication, message passing | Sequence |
| System components, microservices, architecture, infrastructure, deployment, CI/CD pipelines, workflows | Architecture |
| Database tables, entities, schema design, foreign keys, SQL relationships | ER |
| Classes, objects, inheritance, OOP design, interfaces, data models | Class |

If the description matches multiple types, present the top 2 options briefly and ask which.

If the request is ambiguous, ask: "Briefly describe what you want to visualize — API flows, system components, a database schema, or class structures?"

### Step 5: Present Recommendation

```
Based on your description "{description}", I recommend a **{type}** diagram because {reason}.

Proceeding with {type}...
```

### Step 6: Load and Execute Specialist

Read the specialist file and follow its **Process** exactly. Do not ask the user again — generate the diagram.

Type-to-filename mapping:

- Sequence → `$PLUGIN_DIR/specialists/d2-sequence.md`
- Architecture → `$PLUGIN_DIR/specialists/d2-architecture.md`
- ER → `$PLUGIN_DIR/specialists/d2-er.md`
- Class → `$PLUGIN_DIR/specialists/d2-class.md`

### Step 7: Auto-render (if enabled)

If `auto_render == true` (or user explicitly asks to render):

```bash
d2 {output_file} {OUTPUT_DIR}/{basename}.{output_format}
```

If `d2` is not found, tell the user to run `/d2-config` → option 8 (health check).

### Step 8: Offer design document (opt-in)

If the user's request mentions "document", "design doc", "design", or the generated diagram has 5+ components, offer:

```
This diagram could anchor a full design document.
I can scaffold one around it — say "yes" to proceed.
```

### Code/Script Flow Requests

If the user asks to "diagram the flow" of a file or script:

1. Read the file and derive the flow from actual control paths.
2. If the diagram type is still unclear, ask one short clarification.
3. Execute as the appropriate specialist after confirming intent.

## Examples

**Input:** `/d2-diagram "order processing with payment gateway"`
**Analysis:** Business workflow → Architecture
**Executes:** `$PLUGIN_DIR/specialists/d2-architecture.md`

**Input:** `/d2-diagram "API call from React frontend to FastAPI backend"`
**Analysis:** Service interaction → Sequence
**Executes:** `$PLUGIN_DIR/specialists/d2-sequence.md`

**Input:** `/d2-diagram "user, order, product database schema"`
**Analysis:** Database schema → ER
**Executes:** `$PLUGIN_DIR/specialists/d2-er.md`
