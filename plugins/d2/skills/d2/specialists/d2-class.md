---
description: Compositional patterns for class and OOP design diagrams
allowed-tools: Read, Bash, Write
---

# D2 Class Specialist

## Default Configuration

- **Layout engine:** `dagre` for simple hierarchies, `elk` for complex ones
- **Direction:** `down` (inheritance flows top to bottom)

## Node Placement

| Position | Node type |
|---|---|
| Top | Interfaces, abstract classes |
| Middle | Concrete implementations |
| Bottom | Value objects, enums, utilities |

## Grouping Defaults

- One package or module per diagram
- Group by namespace if multiple packages must appear

## D2 Patterns

**Class with attributes and methods:**

```d2
user_svc: UserService {
  -db_client: DBClient
  -cache: RedisCache
  +get_user(id: str): User
  +create_user(data: dict): User
  -validate(data: dict): bool
}
```

Visibility prefixes: `+` public, `-` private, `#` protected.

**Interface:**

```d2
payment_iface: "<<interface>>\nPaymentProcessor" {
  +process(amount: Money): Result
  +refund(tx_id: str): Result
}
```

Use `\n` in labels for stereotypes (`<<interface>>`, `<<abstract>>`).

**Relationships:**

| Relationship | D2 pattern |
|---|---|
| Inheritance (extends) | `child -> parent: extends` |
| Implementation | `impl -> iface: implements {style.stroke-dash: 4}` |
| Composition (strong) | `parent -> child: has` |
| Aggregation (weak) | `parent -> child: contains` |
| Association | `a -> b: uses` |
| Dependency | `a -> b: depends {style.stroke-dash: 4}` |

**Complete example:**

```d2
vars: {
  d2-config: {
    theme-id: 0
    layout-engine: dagre
  }
}

payment_iface: "<<interface>>\nPaymentProcessor" {
  +process(amount: Money): Result
  +refund(tx_id: str): Result
}

stripe_proc: StripeProcessor {
  -api_key: str
  +process(amount: Money): Result
  +refund(tx_id: str): Result
}

paypal_proc: PaypalProcessor {
  -client_id: str
  +process(amount: Money): Result
  +refund(tx_id: str): Result
}

stripe_proc -> payment_iface: implements {style.stroke-dash: 4}
paypal_proc -> payment_iface: implements {style.stroke-dash: 4}
```

## Type-Specific Rules

- D2 has no native `classDiagram` — use labeled containers with attribute lists
- Quote names with special characters: `"<<interface>>\nName"`
- Newlines in labels use `\n`
- Relationship labels go after the arrow: `A -> B: extends`
- Dashed lines use `{style.stroke-dash: 4}`
- Reserved words as names must be quoted: `"class"`, `"interface"`
