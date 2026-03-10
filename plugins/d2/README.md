# D2 Diagram Plugin for Claude Code

Generate, validate, and render [D2](https://d2lang.com) diagrams from natural language descriptions or codebase analysis.

## Requirements

- **d2** CLI: `brew install d2` (macOS) or `go install oss.terrastruct.com/d2@latest`
- PNG export requires Playwright (installed separately)

## Commands

| Command | Description |
|---|---|
| `/d2-diagram [description]` | Generate a D2 diagram from a text description — auto-detects type |
| `/d2-convert [mermaid code or file]` | Convert a Mermaid diagram to D2 format |
| `/d2-architect [path]` | Scan a codebase and auto-generate 3-5 relevant D2 diagrams |
| `/d2-validate [path]` | Validate `.d2` syntax in files or directories |
| `/d2-render [path]` | Render `.d2` files to SVG or PNG |
| `/d2-config` | Configure theme, layout engine, output settings, and check dependencies |

## Diagram Types

| Type | When to use | Example |
|---|---|---|
| **Architecture** | System design, microservices, infrastructure, CI/CD, workflows | "microservices with API gateway" |
| **Sequence** | API flows, service interactions, request/response | "JWT auth flow" |
| **ER** | Database schema, SQL tables, entity relationships | "user, order, product schema" |
| **Class** | OOP design, class hierarchies, data models | "payment processor class hierarchy" |

## Configuration

Run `/d2-config` to set preferences. Settings are stored in `.claude/d2.json`:

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

### Themes

| ID | Name |
|---|---|
| 0 | Neutral |
| 1 | Neutral Dark |
| 3 | Terrastruct |
| 4 | Cool Classics |
| 5 | Mixed Berry Blue |
| 8 | Colorblind Clear |
| 100 | Vanilla Nitro Cola |
| 200 | Dark Mauve |
| 300 | Terminal |
| 301 | Terminal Grayscale |

### Layout Engines

| Engine | Best for |
|---|---|
| `dagre` | Fast, simple directed graphs (default) |
| `elk` | Complex diagrams with many nodes and edges |
| `tala` | Multi-directional nested layouts (requires tala binary) |

## Self-Contained Diagrams

Generated `.d2` files include an embedded `vars` block so they render correctly with just `d2 file.d2`:

```d2
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: dagre
    sketch: false
  }
}

# ... diagram content
```

## Agent

The `diagram-architect` agent proactively detects diagram opportunities during active development work — when you're writing code, designing APIs, or planning data models.

## Troubleshooting

See `skills/d2/references/guides/troubleshooting.md` for documented error patterns.
Run `/d2-config` → option 8 (health check) to verify your D2 installation.
