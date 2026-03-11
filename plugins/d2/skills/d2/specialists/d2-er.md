---
description: Compositional patterns for entity-relationship and database schema diagrams
allowed-tools: Read, Bash, Write
---

# D2 ER Specialist

## Default Configuration

- **Layout engine:** `elk` for schemas with >6 tables, `dagre` otherwise
- **Sketch mode:** always `false` (sql_table is incompatible with sketch)

## Node Placement

| Position | Entity type |
|---|---|
| Center | Core domain entities (users, orders, products) |
| Periphery | Lookup/reference tables (statuses, categories, roles) |
| Grouped | Junction/join tables near their parent entities |

## D2 Patterns

**Table definition:**

```d2
users: {
  shape: sql_table
  id: bigint {constraint: primary_key}
  email: varchar(255) {constraint: unique}
  name: varchar(100)
  created_at: timestamp
}
```

**Relationships with crow's foot notation:**

```d2
users.id -> orders.user_id: {
  source-arrowhead.shape: cf-one-required
  target-arrowhead.shape: cf-many
}
```

**Crow's foot arrowhead values:**

| Value | Meaning |
|---|---|
| `cf-one` | Exactly one (optional) |
| `cf-one-required` | Exactly one (required) |
| `cf-many` | Zero or more |
| `cf-many-required` | One or more |

**Constraint values:**

| Constraint | Meaning |
|---|---|
| `primary_key` | PK |
| `foreign_key` | FK |
| `unique` | Unique |
| `not_null` | Not nullable |

**Complete example:**

```d2
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: elk
    sketch: false
  }
}

users: {
  shape: sql_table
  id: bigint {constraint: primary_key}
  email: varchar(255) {constraint: unique}
  name: varchar(100)
}

orders: {
  shape: sql_table
  id: bigint {constraint: primary_key}
  user_id: bigint {constraint: foreign_key}
  total: "decimal(10,2)"
  status: varchar(50)
}

users.id -> orders.user_id: {
  source-arrowhead.shape: cf-one-required
  target-arrowhead.shape: cf-many
}
```

## Type-Specific Rules

- `shape: sql_table` is REQUIRED for each entity
- Always set `sketch: false` — sketch mode breaks sql_table rendering
- Use `{constraint: primary_key}` syntax, NOT SQL keywords
- Connect via field dot-path: `table.field -> other_table.fk_field`
- Max 10 tables per diagram — split larger schemas by domain
- Use crow's foot arrowheads for cardinality (no text labels needed)
