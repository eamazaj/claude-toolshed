---
name: d2
description: Internal routing hub for d2 diagram skills
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
---

# D2 — Diagram Composition Policies

Global rules for all D2 diagram generation. Every specialist and generation flow MUST enforce these. They are not optional.

## CRITICAL — Every Diagram Must

1. **Use snake_case IDs** — `api_gw: "API Gateway"`, NOT `"API Gateway"` as ID. Emojis go in labels only.
2. **Set `direction` explicitly** — `direction: right` for flows, `direction: down` for hierarchies. If unsure, use `direction: right`. Never omit.
3. **Stay at one abstraction level** — don't mix context actors with component internals.
4. **Stay under visual budget** — max 12 top-level nodes, 7 per group, 3 nesting levels, 4 outgoing edges.

---

## Abstraction Levels

Every diagram operates at exactly ONE of these levels:

| Level | Shows | Does NOT show |
|---|---|---|
| Context | Users, external systems, the system as a black box | Internal services, databases, queues |
| Container | Applications, services, databases, message brokers | Internal classes, functions, SQL columns |
| Component | Modules, layers, handlers within a single container | Other containers, infrastructure |
| Deployment | Runtime nodes, pods, VMs, networks, regions | Business logic, data models |

**Rule:** Do not mix levels. If the user's request implies multiple levels, normalize to the dominant level or generate separate diagrams.

## Grouping Discipline

Every diagram uses exactly ONE grouping criterion:

| Criterion | Groups by | Typical use |
|---|---|---|
| Layer | frontend / backend / data / infra | Container diagrams, layered architectures |
| Domain | auth / orders / payments / users | Microservices, bounded contexts |
| Ownership | team-a / team-b / platform | Org-level views |
| Environment | dev / staging / prod | Deployment diagrams |

**Rule:** Choose one. If the user's description mixes criteria, ask or default to the most prominent one.

## Visual Budget

Hard limits:

| Metric | Limit | Action if exceeded |
|---|---|---|
| Visible top-level elements | 12 | Simplify or split into overview + details |
| Nodes per group | 7 | Split the group or elevate children |
| Nesting depth | 3 levels | Flatten or extract to separate diagram |
| Outgoing edges from one node | 4 | Introduce hub / gateway / bus |
| Groups with exactly 1 node | 0 | Remove the group wrapper |
| Label length | ~24 chars | Shorten, abbreviate, or move detail to tooltip |

When the budget is exceeded:

1. Simplify (remove low-value nodes)
2. If all nodes are essential: split into overview + detail diagrams

## Orientation Heuristics

| Pattern | Direction |
|---|---|
| Request flow, API integration, pipeline, data flow | `direction: right` |
| Hierarchy, org chart, tree, dependency graph | `direction: down` (default) |
| Deployment with environments | One column per environment |
| Sequence diagrams | N/A (fixed layout) |

**Rule:** Always set `direction` explicitly. Never rely on the engine default.

## Layout Engine Selection

| Profile | Engine | Reason |
|---|---|---|
| < 8 nodes, simple flow, pipeline | `dagre` | Fast (~78ms), clean for simple graphs |
| >= 8 nodes, nested containers, dense graphs | `elk` | Better spacing (~586ms), handles density |
| Sequence diagrams | `dagre` | Layout engine is ignored for sequences |
| ER with > 6 tables | `elk` | Better table spacing |

## Node IDs and Labels

- **IDs:** short, semantic, snake_case — `api_gw`, `user_svc`, `orders_db`
- **Labels:** descriptive but compact — `API Gateway`, `User Service`, `Orders DB`
- **Emojis:** in labels only, never in IDs
- **Format:** `api_gw: "API Gateway"` — not `"API Gateway"` as both ID and label

## Compositional Patterns by Type

Defaults — override if the flow demands otherwise.

### System Context

- Left: users, actors
- Center: system under design (single box, no internals)
- Right or below: external dependencies
- Max: 5-8 nodes

### Container

- Left: entry points (users, gateways)
- Center: application tier (services, APIs)
- Right: data tier (databases, caches, queues)
- Below: async/supporting (workers, monitoring)
- Group by: layer (default) or domain

### Component

- Scope: one container only
- Group by: layer or module (not both)
- No deployment concerns, no external systems
- Max: 8-10 nodes

### Deployment

- Group by: environment or network boundary
- Separate: ingress / compute / data
- No business actors unless showing access paths

### Sequence

- Max: 5-6 actors
- Use groups for happy path / error path
- Avoid self-messages — use notes instead
- Labels under 30 chars

### ER

- Core entities: center
- Lookup/reference tables: periphery
- Crow's foot notation for cardinality
- Max: 10 tables per diagram (split by domain)

### Class

- Interfaces/abstracts: top
- Implementations: below
- One package/module per diagram

## Repair Pass

Before delivering ANY diagram, verify:

1. **Level mixing:** context-level actors mixed with component internals? Fix.
2. **Grouping consistency:** same criterion throughout? Fix.
3. **Budget compliance:** counts within limits? Simplify or split.
4. **Labels:** any label > 24 chars? Shorten.
5. **Orphan nodes:** any node with zero connections? Remove or connect.
6. **Single-child groups:** any group with 1 node? Dissolve.
7. **Fanout:** any node with > 4 outgoing edges? Add intermediary.
8. **Self-loops (sequences):** can they become notes? Convert.
9. **Direction set?** Is `direction` explicitly declared? Add it.
10. **Engine appropriate?** Complexity matches engine? Switch if needed.

## Split Strategy

If the structural plan exceeds the visual budget:

1. Generate an **overview** diagram at one level higher of abstraction
2. Generate **detail** diagrams for each major group or subsystem
3. Naming: `{type}-{scope}-overview-{date}.d2`, `{type}-{scope}-detail-{subsystem}-{date}.d2`

## Plugin Path Resolution

Run once before any file reads or script calls:

```bash
PLUGIN_DIR=$(find "$HOME/.claude/plugins/cache" -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
```

If empty (dev/repo usage):

```bash
PLUGIN_DIR=$(find "$HOME" -maxdepth 8 -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
```

If still empty: stop — "Plugin not found. Is it installed? Run `/plugin install d2@claude-toolshed`."

## Config Reading

Read `.claude/d2.json` as a first step. Supported keys:

- `theme_id` (default: 0) — D2 theme ID
- `layout` (default: "dagre") — layout engine: dagre, elk, tala
- `sketch` (default: false) — hand-drawn style
- `output_directory` (default: "./diagrams")
- `auto_validate` (default: true)
- `auto_render` (default: false)
- `output_format` (default: "svg")

## Embedded Config

Every generated `.d2` file includes a `vars` block at the top:

```d2
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: dagre
    sketch: false
  }
}
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Using Mermaid arrow syntax (`-->`) | D2 uses `->` for directed connections |
| Sequence diagram outside container | Use `shape: sequence_diagram` at root level |
| `vars` block not at top of file | Must be the first statement |
| Layout engine `tala` not working | Requires separate `tala` binary: `brew install tala` |
| PNG rendering fails | Requires Playwright: see troubleshooting.md |

## Entry Points

| Entry point | When to use |
|---|---|
| `/d2-diagram` | Generate one diagram from a description |
| `/d2-convert` | Convert a Mermaid diagram to D2 format |
| `/d2-validate` | Batch-check existing `.d2` or `.md` files |
| `/d2-render` | Render an existing `.d2` file to SVG or PNG |
| `/d2-config` | Configure defaults and check dependencies |
| `/d2-architect` | Analyze a codebase path and generate a diagram suite |
| `diagram-architect` agent | Claude detects diagram need during active development |

## Diagram Type Routing

| User wants | Specialist |
|---|---|
| API flow, service-to-service calls, request/response | `specialists/d2-sequence.md` |
| System design, microservices, infrastructure, CI/CD, workflows | `specialists/d2-architecture.md` |
| Database schema, SQL tables, entities, relationships | `specialists/d2-er.md` |
| Class hierarchy, OOP design, data models, interfaces | `specialists/d2-class.md` |

## Reference Guides

| Need | Load |
|---|---|
| Syntax errors, rendering failures | `references/guides/troubleshooting.md` |
| Learning D2, preventing errors | `references/guides/common-mistakes.md` |
| Themes, layout engines, sketch mode | `references/guides/styling-guide.md` |
| D2 layout features (grids, padding, direction syntax) | `references/guides/layout-guide.md` |
| Quick routing from symptom to action | `references/guides/quick-decision-matrix.md` |
