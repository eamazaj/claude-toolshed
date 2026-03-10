# D2 Troubleshooting Guide

Common errors and their fixes. Each entry includes: symptom, cause, and correct solution.

---

## 1. Arrow Syntax Error

**ERROR:** `unexpected token ->`
**CAUSE:** Using Mermaid-style `-->` double-dash arrows.

```
# WRONG
a --> b: message
a -> -> b: label

# CORRECT
a -> b: message
a <- b: message
a <-> b: bidirectional
```

---

## 2. Connection Label Quoting

**ERROR:** Diagram renders incorrectly, label truncated or missing.
**CAUSE:** Labels with special characters not quoted.

```
# WRONG
a -> b: POST /api/users: 200 OK

# CORRECT
a -> b: "POST /api/users: 200 OK"
```

---

## 3. Sequence Diagram Shape Missing

**ERROR:** Diagram renders as a flow graph instead of sequence diagram.
**CAUSE:** Missing `shape: sequence_diagram` declaration.

```
# WRONG
client -> server: request
server -> db: query

# CORRECT
shape: sequence_diagram

client -> server: request
server -> db: query
```

---

## 4. `vars` Block Not at Top

**ERROR:** `unexpected token vars` or config not applied.
**CAUSE:** `vars` block must be the first statement in the file.

```
# WRONG
a -> b
vars: {
  d2-config: { theme-id: 0 }
}

# CORRECT
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: dagre
  }
}

a -> b
```

---

## 5. SQL Table Field Syntax

**ERROR:** `unexpected token {` in table field definition.
**CAUSE:** Incorrect constraint syntax.

```
# WRONG
users: {
  shape: sql_table
  id: int (primary key)
  email: string UNIQUE
}

# CORRECT
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  email: varchar(255) {constraint: unique}
  name: varchar(100)
}
```

---

## 6. Container Syntax Error

**ERROR:** `unexpected token }` or `unexpected EOF`.
**CAUSE:** Missing closing brace or incorrect nesting.

```
# WRONG
container: {
  a -> b

# CORRECT
container: {
  a -> b
}
```

---

## 7. Reserved Keyword as Node ID

**ERROR:** `unexpected token` on a line using keywords as identifiers.
**CAUSE:** D2 reserves certain words. Quote them if needed.

```
# WRONG
class -> interface

# CORRECT
"class" -> "interface"
```

Reserved words to quote: `class`, `shape`, `style`, `label`, `link`, `icon`, `near`, `vars`, `direction`

---

## 8. Layout Engine Not Found

**ERROR:** `layout engine not found: tala` or similar.
**CAUSE:** The `tala` layout engine requires a separate binary.

**Fix:** Install tala: `brew install tala`
Or switch to a built-in engine in `.claude/d2.json`:

```json
{ "layout": "dagre" }
```

Or in the `vars` block: `layout-engine: elk`

---

## 9. PNG Export Fails

**ERROR:** `PNG export requires a browser` or `playwright not found`.
**CAUSE:** PNG rendering requires Playwright headless browser.

**Fix:**

```bash
npm install -g playwright
playwright install chromium
```

Or switch to SVG output in config: `"output_format": "svg"`

---

## 10. Node ID with Special Characters

**ERROR:** Parse error on node label with spaces or special chars.
**CAUSE:** Node IDs with spaces or special characters must be quoted.

```
# WRONG
API Gateway -> Auth Service: JWT validation

# CORRECT
"API Gateway" -> "Auth Service": JWT validation
```

---

## 11. Connection Between Nested Nodes

**ERROR:** Node not found error when referencing nested nodes from outside container.
**CAUSE:** Must use dot notation for paths to nested nodes.

```
# WRONG
services.api -> db

# CORRECT
services.api -> db
# OR access from within the container:
services: {
  api -> db
}
```

---

## 12. Direction Keyword

**ERROR:** Diagram layout is unexpected orientation.
**CAUSE:** `direction` keyword usage.

```
# Direction applies to the whole diagram:
direction: right

# Direction for a container only:
container: {
  direction: down
  a -> b -> c
}
```

Valid values: `up`, `down`, `left`, `right`

---

## 13. Semicolon in Label Text

**ERROR:** Label truncated at semicolon.
**CAUSE:** D2 uses `;` as a statement separator on a single line.

```
# WRONG (semicolon in label)
a -> b: "step 1; then step 2"

# CORRECT — avoid semicolons in labels, use comma or dash:
a -> b: "step 1, then step 2"
a -> b: "step 1 — then step 2"
```

---

## 14. Style Block Syntax

**ERROR:** Style not applied or parse error.
**CAUSE:** Incorrect style block syntax.

```
# WRONG
a.color: red

# CORRECT
a: {
  style: {
    fill: "#ff0000"
    stroke: "#990000"
  }
}
```

---

## 15. Sketch Mode with Complex Shapes

**ERROR:** Some shapes don't render correctly in sketch mode.
**CAUSE:** Sketch mode is not compatible with all shape types (particularly `sql_table`).

**Fix:** Disable sketch mode for diagrams using SQL tables:

```d2
vars: {
  d2-config: {
    sketch: false
  }
}
```

---

## Quick Reference

| Symptom | Check |
|---|---|
| Arrow not rendering | Use `->`, not `-->` |
| Sequence renders as flow | Add `shape: sequence_diagram` at top |
| Config not applied | Move `vars` block to first line |
| SQL field parse error | Use `{constraint: primary_key}` syntax |
| PNG fails | Install Playwright or switch to SVG |
| Missing closing brace | Count `{` and `}` pairs |
| Label cut off | Quote labels with special characters |
| Wrong layout | Check layout engine installed (tala needs separate install) |
