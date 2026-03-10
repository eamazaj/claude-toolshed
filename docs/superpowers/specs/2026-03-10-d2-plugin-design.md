# D2 Diagram Plugin — Design Document

**Date:** 2026-03-10
**Author:** Diego Marino
**Status:** Approved

---

## Problem

The `plugins/mermaid/` plugin provides a mature diagram generation system for Claude Code. D2 (d2lang) is a newer, cleaner diagram scripting language with better readability, multiple layout engines, and a standalone CLI — but there is no Claude plugin for it yet.

## Goal

Build a `plugins/d2/` plugin that mirrors the mermaid plugin's structure and UX, adapted for D2's CLI-based rendering model and diagram type system.

---

## Key Architectural Decisions

### 1. No Node.js / npm required

Mermaid requires the `beautiful-mermaid` npm library for rendering. D2 is a standalone Go binary: rendering is simply `d2 input.d2 output.svg`. No `package.json`, no `node_modules`, no npm installs.

**Impact:** Scripts directory contains only 2 bash scripts instead of 3 Node.js files + package.json.

### 2. 4 diagram types (vs 7 in mermaid)

D2's generic flow syntax handles what Mermaid splits into Activity + Architecture + Deployment as a single "Architecture/Flow" type. D2 also doesn't have a native State diagram type.

| D2 Specialist | Covers |
|---|---|
| `d2-architecture` | System design, microservices, infrastructure, CI/CD, deployment, workflows |
| `d2-sequence` | API flows, request/response, service interactions |
| `d2-er` | Database schema, SQL tables, entity relationships |
| `d2-class` | OOP design, class hierarchies, data models |

### 3. Embedded `vars { d2-config }` block for theme/config

Mermaid passes theme via CLI flag (`--theme zinc-light`). D2 supports embedding configuration directly inside `.d2` files via a `vars` block:

```d2
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: dagre
    sketch: false
  }
}
```

This makes generated `.d2` files **self-contained** — anyone can render them with just `d2 file.d2` and get the intended look without passing CLI flags.

User preferences are stored in `.claude/d2.json` and injected as a `vars` block at the top of each generated diagram.

---

## File Structure

```
plugins/d2/
├── .claude-plugin/plugin.json
├── .gitignore
├── LICENSE
├── CHANGELOG.md
├── README.md
├── agents/
│   └── diagram-architect.md
├── skills/
│   ├── d2/                          # Hub (internal routing)
│   │   ├── SKILL.md
│   │   ├── specialists/
│   │   │   ├── d2-sequence.md
│   │   │   ├── d2-architecture.md
│   │   │   ├── d2-er.md
│   │   │   └── d2-class.md
│   │   ├── references/guides/
│   │   │   ├── troubleshooting.md
│   │   │   ├── common-mistakes.md
│   │   │   ├── styling-guide.md
│   │   │   └── quick-decision-matrix.md
│   │   └── scripts/
│   │       ├── ensure-deps.sh
│   │       └── extract_d2.sh
│   ├── d2-diagram/SKILL.md
│   ├── d2-validate/SKILL.md
│   ├── d2-render/SKILL.md
│   ├── d2-config/SKILL.md
│   └── d2-architect/SKILL.md
└── tests/
    ├── scenarios/
    │   ├── baseline-flow.txt
    │   ├── skill-flow.txt
    │   └── skill-sequence.txt
    └── run-scenario.sh
```

---

## Config Format (`.claude/d2.json`)

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

Injected into each diagram as:

```d2
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: dagre
    sketch: false
  }
}
```

---

## D2 Theme IDs

| ID | Name |
|---|---|
| 0 | Neutral |
| 1 | Neutral Dark |
| 3 | Terrastruct |
| 4 | Cool Classics |
| 5 | Mixed Berry Blue |
| 8 | Colorblind Clear |
| 100 | Vanilla Nitro Cola |
| 101 | Orange Creamsicle |
| 200 | Dark Mauve |
| 300 | Terminal |
| 301 | Terminal Grayscale |

---

## Rendering

```bash
d2 input.d2 output.svg          # SVG (default)
d2 input.d2 output.png          # PNG (requires Playwright)
d2 validate input.d2            # Validation only
```

---

## Testing Strategy

TDD-style RED/GREEN scenarios using the same `run-scenario.sh` pattern as the mermaid plugin:

- **RED phase:** Claude without the skill — does it use valid D2 syntax? Save to right location?
- **GREEN phase:** Claude with skill injected — does it find PLUGIN_DIR? Call `ensure-deps.sh`? Run `d2 validate`? Use correct filename?
