---
name: d2-diagram
description: Generate a D2 diagram from a text description
argument-hint: [description]
allowed-tools: Read, Bash, Write
---

# /d2-diagram

User request: "$ARGUMENTS"

## Task

Generate a well-composed D2 diagram from the user's description.

## Step 1: Setup

Resolve plugin path and read config:

```bash
PLUGIN_DIR=$(find "$HOME/.claude/plugins/cache" -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
[ -z "$PLUGIN_DIR" ] && PLUGIN_DIR=$(find "$HOME" -maxdepth 8 -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
bash "$PLUGIN_DIR/scripts/ensure-deps.sh"
```

Read `.claude/d2.json` if it exists (theme_id, layout, sketch, output_directory, auto_validate, auto_render). If it does not exist, display a one-time nudge:

> First time using the d2 plugin? Run `/d2-config` to pick a theme. Using defaults for now.

## Step 2: Classify

Determine diagram type from the description:

| Intent | Type |
|---|---|
| API calls, request/response, message passing | Sequence |
| System components, microservices, infrastructure, pipelines, workflows | Architecture |
| Database tables, schema, foreign keys, entities | ER |
| Class hierarchy, OOP, interfaces, data models | Class |

If ambiguous between 2 types, ask one clarifying question. If clear, proceed.

## Step 3: Structural Plan

**Before writing any D2**, build this plan internally. Apply the policies from `$PLUGIN_DIR/SKILL.md`.

Determine:

- **diagram_type** — from Step 2
- **abstraction_level** — infer from prompt: context, container, component, or deployment
- **grouping_criterion** — infer or default: layer, domain, ownership, or environment
- **direction** — from orientation heuristics (right for flows, down for hierarchies)
- **layout_engine** — from engine selection table (<8 nodes: dagre, >=8: elk)
- **nodes** — inventory with id (snake_case), label, kind (actor/service/database/queue/cache/gateway/external)
- **groups** — with label and children node IDs
- **edges** — with from, to, and optional label
- **budget_check** — count total nodes, max group size, nesting depth, max fanout against visual budget limits
- **split_decision** — pass or split_required

**Visibility rule:** If the budget check passes and there is no ambiguity in level or grouping, proceed directly to Step 4. If split is required OR the abstraction level or grouping is ambiguous, present a summary to the user:

```text
I'm planning to generate:
- Type: {type} at {abstraction_level} level
- Grouping: by {criterion}
- Direction: {direction}
- {N} nodes in {M} groups
- Split: {overview + N detail diagrams | single diagram}

Proceed, or want to adjust?
```

## Step 4: Load Specialist

Read the specialist for the classified type:

- Sequence: `$PLUGIN_DIR/specialists/d2-sequence.md`
- Architecture: `$PLUGIN_DIR/specialists/d2-architecture.md`
- ER: `$PLUGIN_DIR/specialists/d2-er.md`
- Class: `$PLUGIN_DIR/specialists/d2-class.md`

Use the specialist's compositional patterns and D2 syntax conventions. The structural plan from Step 3 governs the structure — the specialist provides type-specific syntax.

## Step 5: Generate D2

Write the diagram following:

1. **Structural plan** — governs structure (what nodes, what groups, what edges)
2. **Specialist patterns** — governs D2 syntax (shapes, conventions, type-specific features)
3. **Global policies** — governs conventions (IDs, labels, direction, engine)

Order in the `.d2` file:

1. `vars` block (theme, engine, sketch from config)
2. `direction` declaration
3. `classes` block (if >4 nodes of same type)
4. Node and group declarations
5. Connections

**Non-negotiable conventions:**

- **IDs:** snake_case, no emojis, no spaces — `api_gw`, `user_svc`, `orders_db`
- **Labels:** `api_gw: "API Gateway"` — emojis allowed in labels only
- **Direction:** MUST appear right after `vars` block — `direction: right` for flows, `direction: down` for hierarchies. If unsure, use `direction: right`. Never omit.
- Quote labels containing spaces or special characters.

## Step 6: Repair Pass

Before delivering, run the 10-point repair checklist from `$PLUGIN_DIR/SKILL.md`:

1. No level mixing
2. Consistent grouping criterion
3. Budget compliance (12 top-level, 7 per group, 3 nesting, 4 fanout)
4. Labels <= 24 chars
5. No orphan nodes
6. No single-child groups
7. No excessive fanout (>4 edges out)
8. Self-loops converted to notes (sequences)
9. Direction explicitly set
10. Layout engine appropriate for complexity

Fix any violations silently. Do not ask the user — just fix them.

## Step 7: Validate Syntax

```bash
d2 validate {output_file}
```

Fix syntax errors using `$PLUGIN_DIR/references/guides/troubleshooting.md`.

## Step 8: Save and Deliver

```bash
mkdir -p {output_directory}
```

Filename: `{type}-{short-description}-{YYYYMMDD}.d2`

Render if `auto_render=true` or user asks:

```bash
d2 {output_file} {output_directory}/{basename}.svg
```

**Output:**

```text
{d2 code block}

**What this shows:** {1-2 sentences describing the diagram}
**Saved to:** {filename}
**Elements:** {N} nodes, {M} connections
**Layout:** {engine}, direction {direction}

Want to adjust? I can change the detail level, scope, grouping, or type.
```

If split was required, list all generated files.

## Code/Script Flow Requests

If the user asks to "diagram the flow" of a file or script:

1. Read the file and derive the flow from actual control paths
2. Build the structural plan from the code structure
3. Execute as the appropriate specialist
