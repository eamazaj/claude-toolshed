# D2 Styling Guide

Reference for themes, layout engines, sketch mode, and the embedded `vars` config block.

---

## `vars { d2-config }` Block

Every generated `.d2` file should include a config block at the top. This makes diagrams self-contained — renderable with just `d2 file.d2` without CLI flags.

```d2
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: dagre
    sketch: false
  }
}
```

**Placement:** The `vars` block MUST be the first statement in the file. Placing it after other content causes a parse error.

**Building from config:** Read `.claude/d2.json` and map fields:

| Config key | `d2-config` key |
|---|---|
| `theme_id` | `theme-id` |
| `layout` | `layout-engine` |
| `sketch` | `sketch` |

---

## Themes

D2 themes are referenced by numeric ID.

| ID | Name | Character |
|---|---|---|
| 0 | Neutral | Clean, minimal, works for both light/dark |
| 1 | Neutral Dark | Inverted neutral |
| 3 | Terrastruct | Official D2 theme, polished |
| 4 | Cool Classics | Muted blues and greens |
| 5 | Mixed Berry Blue | Vibrant blue tones |
| 8 | Colorblind Clear | Accessible for color-blind users |
| 100 | Vanilla Nitro Cola | Warm cream/caramel palette |
| 101 | Orange Creamsicle | Orange and cream |
| 200 | Dark Mauve | Dark purple tones |
| 300 | Terminal | Monochrome terminal aesthetic |
| 301 | Terminal Grayscale | Grayscale terminal |

**Default:** `theme-id: 0` (Neutral) — works well in both light and dark environments.

**For dark mode viewers:** Use `dark-theme-id` alongside `theme-id`:

```d2
vars: {
  d2-config: {
    theme-id: 0
    dark-theme-id: 200
  }
}
```

---

## Layout Engines

| Engine | Best for | Notes |
|---|---|---|
| `dagre` | Simple directed graphs, most diagrams | Fast, default, always available |
| `elk` | Complex diagrams with many nodes | Better spacing, handles dense graphs |
| `tala` | Multi-directional nested layouts | Requires separate `brew install tala` |

### Choosing the Right Engine

- **Architecture diagrams:** `elk` handles large component graphs better
- **Sequence diagrams:** `dagre` (layout engine is ignored for sequence diagrams)
- **ER diagrams:** `elk` for schemas with many tables
- **Class diagrams:** `dagre` for simple hierarchies, `elk` for complex ones
- **Default:** `dagre` — fast, always available, good for most cases

### Container Direction

Each container can have its own direction, independent of the layout engine:

```d2
container: {
  direction: right
  a -> b -> c
}
```

Valid values: `up`, `down`, `left`, `right`

---

## Sketch Mode

Sketch mode renders diagrams in a hand-drawn style.

```d2
vars: {
  d2-config: {
    sketch: true
  }
}
```

**Use when:** User explicitly asks for a casual, informal, or hand-drawn style.
**Avoid when:** Using `sql_table` shapes — sketch mode is incompatible with them.

---

## Style Overrides

Only apply explicit style overrides when the user requests specific colors.

### Node Styles

```d2
node: {
  style: {
    fill: "#4a90d9"
    stroke: "#2563eb"
    font-color: "#ffffff"
    border-radius: 8
    shadow: true
  }
}
```

### Connection Styles

```d2
a -> b: {
  style: {
    stroke: "#ff0000"
    stroke-dash: 4
    stroke-width: 2
  }
}
```

### Shape Types

D2 provides many built-in shapes:

| Shape | Use case |
|---|---|
| `rectangle` | Default, general purpose |
| `circle` | Start/end states |
| `diamond` | Decision points |
| `cylinder` | Databases, storage |
| `hexagon` | Processing nodes |
| `person` | Users, actors |
| `cloud` | Cloud services |
| `queue` | Message queues |
| `page` | Documents, files |
| `sql_table` | Database tables with fields |
| `sequence_diagram` | Makes container a sequence diagram |

---

## Padding

```d2
vars: {
  d2-config: {
    pad: 50
  }
}
```

Default padding is 100. Reduce for compact diagrams, increase for more whitespace.

---

## Centering

```d2
vars: {
  d2-config: {
    center: true
  }
}
```

Centers the diagram in the output canvas.
