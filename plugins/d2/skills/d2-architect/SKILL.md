---
name: d2-architect
description: Scan a codebase and auto-generate relevant diagrams from its structure
argument-hint: [path]
allowed-tools: Read, Bash, Glob, Grep, Write
---

# /d2-architect

User request: "$ARGUMENTS"

## Task

Analyze a codebase or project path and generate a relevant suite of D2 diagrams (typically 3-4 types based on what's found).

## Difference from /d2-diagram

- `/d2-diagram` generates **one diagram** from a **text description**
- `/d2-architect` generates **multiple diagrams** from **actual code/files** at a given path

## Process

### Step 1: Resolve Plugin Path

```bash
PLUGIN_DIR=$(find "$HOME/.claude/plugins/cache" -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
[ -z "$PLUGIN_DIR" ] && PLUGIN_DIR=$(find "$HOME" -maxdepth 8 -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
```

If still empty, stop: "Plugin not found. Is it installed?"

### Step 2: Ensure Dependencies

```bash
bash "$PLUGIN_DIR/scripts/ensure-deps.sh"
```

If `.claude/d2.json` does **not** exist, display a one-time nudge before continuing:

> First time using the d2 plugin? Run `/d2-config` to pick a theme and output settings. Using defaults for now (theme 0 / Neutral, `./diagrams`).

### Step 3: Read Config

If `.claude/d2.json` exists, read `output_directory`, `theme_id`, `layout`, `sketch`, `auto_validate`, `auto_render`.

**Resolve output path:**

- If `output_directory` is `"same"` AND an input path is known: `OUTPUT_DIR={input_directory}`
- Otherwise: `OUTPUT_DIR={output_directory or ./diagrams}`

### Step 4: Resolve Target Path

- If no argument, use current directory.
- If argument is a file, analyze that single file.
- If argument is a directory, explore it.

### Step 5: Explore Codebase

```bash
find {path} \( -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.rb" -o -name "*.go" \) | grep -v node_modules | grep -v dist | head -50
find {path} \( -name "*.sql" -o -name "*.prisma" -o -name "*schema*" \) | grep -v node_modules | head -20
find {path} \( -name "routes*" -o -name "router*" -o -name "urls*" -o -name "endpoints*" \) | grep -v node_modules | head -20
find {path} \( -name "docker-compose*" -o -name "Dockerfile*" -o -name "k8s" -o -name "*.yaml" \) | grep -v node_modules | head -10
```

Read key files to understand the domain (models, routes, services, main entry point).

### Step 6: Infer Diagram Types

Based on what's found:

| Found | Generates |
|---|---|
| Database models / ORM / schema files / `.sql` / `.prisma` | ER diagram |
| API routes / controllers / endpoints | Sequence diagram (request flow) |
| Service classes / modules / `services/` directory | Architecture diagram |
| Class files with inheritance (`extends`, `implements`) | Class diagram |
| Config / deployment files (docker, k8s, cloud) | Architecture diagram (deployment view) |

Select **2-4 most relevant types**. Do not generate all 4 unless the codebase clearly warrants it.

### Step 6b: Apply Composition Policies

Read the global policies from `$PLUGIN_DIR/SKILL.md`. For each diagram to generate:

1. Determine abstraction level (context/container/component/deployment)
2. Choose grouping criterion (layer/domain/ownership/environment)
3. Check estimated node count against visual budget (max 12 top-level, 7 per group)
4. Select layout engine (dagre for <8 nodes, elk for >=8)
5. Set direction explicitly (right for flows, down for hierarchies)

If a diagram would exceed the visual budget, split into overview + detail.

### Step 7: Generate Each Diagram

For each selected type, load the specialist:

```bash
cat "$PLUGIN_DIR/specialists/d2-{type}.md"
```

Follow the specialist's compositional patterns using the actual code found in Step 5. The structural decisions from Step 6b (abstraction, grouping, direction, engine) govern the output. After generating, run the repair pass from `$PLUGIN_DIR/SKILL.md` before validating.

### Step 8: Validate

For each generated diagram:

```bash
d2 validate {output_file}
```

Fix any errors using `$PLUGIN_DIR/references/guides/troubleshooting.md`.

### Step 9: Render (if `auto_render=true` or user requests)

```bash
d2 {file} {OUTPUT_DIR}/{basename}.svg
```

### Step 10: Report

```
Analyzed: {path}
Generated {N} diagrams:

  ✅ {OUTPUT_DIR}/er-{name}-{timestamp}.d2       (ER — 5 tables, 4 relationships)
  ✅ {OUTPUT_DIR}/sequence-{name}-{timestamp}.d2  (Sequence — 4 actors, 8 messages)
  ✅ {OUTPUT_DIR}/architecture-{name}-{timestamp}.d2 (Architecture — 6 components)

Validation: all passed
```

### Step 11: Offer design document (opt-in)

If 3 or more diagrams were generated:

```
Generated {N} diagrams — want me to assemble them into a system design document?
I'll embed each diagram in the relevant section.
```

If fewer than 3 diagrams: skip silently.

## Common Mistakes

- **Generating all 4 diagram types** when only 2 are warranted — select only types with clear evidence in the code.
- **Empty PLUGIN_DIR** — if both find commands return nothing, stop and report the install message.
- **Including node_modules or dist** — always exclude with `-not -path "*/node_modules/*"` and `-not -path "*/dist/*"`.
- **Inferring from file names only** — read actual function bodies, model fields, and route handlers.
