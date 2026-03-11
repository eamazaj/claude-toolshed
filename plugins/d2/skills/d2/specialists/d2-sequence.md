---
description: Compositional patterns for sequence and message flow diagrams
allowed-tools: Read, Bash, Write
---

# D2 Sequence Specialist

## Default Configuration

- **Layout engine:** `dagre` (engine is ignored for sequence diagrams)
- **Shape:** `shape: sequence_diagram` is REQUIRED at root level

## Actor Guidelines

- Max 5-6 actors per diagram
- Use short, consistent names throughout
- Pre-declare actors at top level when using groups

## D2 Patterns

**Basic sequence:**

```d2
shape: sequence_diagram

client -> api: "POST /login"
api -> auth: validate credentials
auth -> db: lookup user
db -> auth: user record
auth -> api: JWT token
api -> client: "200 OK {token}"
```

**Groups (fragments) for happy/error paths:**

Actors used inside groups MUST be pre-declared at top level:

```d2
shape: sequence_diagram

client
server
db

happy_path: {
  client -> server: "POST /login"
  server -> db: lookup user
  db -> server: user record
  server -> client: "200 JWT"
}

error_path: {
  client -> server: "POST /login"
  server -> client: "401 Unauthorized"
}
```

**Notes (instead of self-messages):**

```d2
shape: sequence_diagram

alice -> bob: request
bob."Processing request locally"
bob -> alice: response
```

**Spans (activation boxes):**

```d2
shape: sequence_diagram

alice.t1 -> bob
alice.t1 <- bob
```

## Type-Specific Rules

- `shape: sequence_diagram` is REQUIRED — without it D2 renders a flow graph
- Avoid self-messages (`svc -> svc: text`) — they expand diagram width. Use notes instead: `svc."text"`
- Quote all labels containing `:` or special characters: `"POST /api: 200"`
- Use `->` for messages, never `-->`
- Keep message labels under 30 chars
- Groups render as named frames — equivalent to Mermaid's alt/opt/loop
- Actors are defined implicitly on first use, EXCEPT when using groups (pre-declare)
