# D2 Layout Features Reference

Reference for D2 layout features. For composition rules (visual budget, orientation, engine selection), see the root `d2/SKILL.md` policies.

---

## Direction Per Container

Each container can have its own direction:

```d2
container: {
  direction: right
  a -> b -> c
}
```

Valid values: `up`, `down`, `left`, `right`

Global direction applies to the whole diagram:

```d2
direction: right
a -> b -> c
```

---

## Grid Layout

Use `grid-columns` or `grid-rows` for uniform grids:

```d2
cluster: {
  grid-columns: 3
  pod1: API Pod
  pod2: API Pod
  pod3: API Pod
  pod4: Worker Pod
  pod5: Worker Pod
  pod6: Worker Pod
}
```

---

## Padding

```d2
vars: {
  d2-config: {
    pad: 50
  }
}
```

Default is 100. Reduce to 50 for compact diagrams.

---

## Markdown Block Limitation

D2 `|md ... |` blocks render as foreignObject in SVG. The engine collapses them to a single line with enormous widths (600-1200px) and fixed height (24px).

Use `|md ... |` only for short text needing bold/italic/links. For plain multiline, use `\n`:

```text
WRONG:
node: |md
  **Title** — long description here
  *More details*
|

CORRECT:
node: "Title\nLong description here\nMore details" {
  style.font-size: 14
}
```

---

## Self-Loops and Back-Edges

**Self-loops** (`node -> node`) always expand diagram width horizontally. Move info to the node label or a note instead.

**Back-edges** (lower node -> upper node) route through the sides in dagre and elk, expanding width. Consider an intermediate node or accept the tradeoff.
