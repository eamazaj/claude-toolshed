---
description: Compositional patterns for architecture and infrastructure diagrams
allowed-tools: Read, Bash, Write
---

# D2 Architecture Specialist

## Default Configuration

- **Layout engine:** `elk` (handles dense graphs with nested containers)
- **Direction:** `right` for flows/pipelines, `down` for hierarchies
- **Abstraction level:** container (default), deployment if infra-focused

## Node Placement

| Position | Node types |
|---|---|
| Left edge | Users, external clients, entry points |
| Center-left | Gateways, load balancers, API layers |
| Center | Application services, workers |
| Center-right | Databases, caches, queues |
| Right edge | External APIs, third-party services |
| Below main flow | Monitoring, logging, async workers, supporting infra |

## Grouping Defaults

- **Container diagrams:** group by layer (clients / services / data)
- **Microservices:** group by domain (auth / orders / payments)
- **Deployment:** group by environment or network boundary

## D2 Patterns

**Shapes by node kind:**

| Kind | Shape |
|---|---|
| Database, cache | `shape: cylinder` |
| Message queue | `shape: queue` |
| Cloud service | `shape: cloud` |
| User, actor | `shape: person` |
| Everything else | rectangle (default) |

**Reusable styles with `classes`** (use when >4 nodes of same type):

```d2
classes: {
  service: {
    style.border-radius: 4
    style.shadow: true
  }
  database: {
    shape: cylinder
  }
  external: {
    style.stroke-dash: 4
  }
}

auth_svc: "Auth Service" { class: service }
orders_db: "Orders DB" { class: database }
stripe: "Stripe API" { class: external }
```

**Container grouping:**

```d2
services: {
  label: Application Services
  api: "API Gateway"
  user_svc: "User Service"
  order_svc: "Order Service"
}

data: {
  label: Data Layer
  pg: "PostgreSQL" { shape: cylinder }
  redis: "Redis" { shape: cylinder }
  rabbit: "RabbitMQ" { shape: queue }
}

services.api -> services.user_svc: REST
services.api -> services.order_svc: REST
services.order_svc -> data.pg
services.order_svc -> data.rabbit: async
```

**Pipeline/flow (linear left-to-right):**

```d2
direction: right
source -> build -> test -> deploy -> monitor
```

**Grid layout (replicas, pod arrays):**

```d2
cluster: {
  grid-columns: 3
  pod1: API Pod
  pod2: API Pod
  pod3: API Pod
}
```

## Type-Specific Rules

- Use `classes` block when diagram has >4 nodes of the same type
- Use `grid-columns` for replica sets or pod arrays
- Label connections with protocol or data description (REST, gRPC, async, SQL)
- For cross-container connections use full dot-path: `container.node`
- Quote all node IDs containing spaces (but prefer snake_case IDs)
