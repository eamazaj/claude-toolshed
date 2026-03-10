---
description: Generate sequence diagrams for API interactions and message flows
argument-hint: [description]
allowed-tools: Read, Bash, Write
---

# D2 Sequence Specialist

User request: "$ARGUMENTS"

## Task

Generate a D2 sequence diagram for API calls, service interactions, and message flows.

## Process

1. **Resolve Plugin Path**:

   ```bash
   PLUGIN_DIR=$(find "$HOME/.claude/plugins/cache" -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
   [ -z "$PLUGIN_DIR" ] && PLUGIN_DIR=$(find "$HOME" -maxdepth 8 -type d -name "d2" -path "*/skills/d2" 2>/dev/null | head -1)
   ```

2. **Ensure D2 is installed**:

   ```bash
   bash "$PLUGIN_DIR/scripts/ensure-deps.sh"
   ```

3. **Read Config**: If `.claude/d2.json` exists, read `theme_id`, `layout`, `sketch`, `output_directory`, `auto_validate`, `auto_render`. Fall back to defaults (theme_id: 0, layout: dagre, output: ./diagrams).

4. **Identify Participants**: Extract users/clients, frontend, API layer, backend services, data layer, external services.

5. **Map Message Flow**: Who initiates? What messages? Sync or async? Conditionals? How does it end?

6. **Generate Diagram**:

   - Start with `vars` block built from config
   - Add `shape: sequence_diagram` declaration — this is REQUIRED for D2 sequence diagrams
   - Use descriptive actor names, quoted if they contain spaces
   - Include HTTP methods and status codes for API flows: `"POST /login: 200 OK"`
   - Use `->` for messages (not `-->`)
   - Quote labels containing `:` — they will break the parser otherwise
   - Include error paths and failure cases, not just the happy path
   - Use Unicode symbols for semantic clarity: 👤 user, 🌐 gateway, 🔐 auth, ⚙️ service, 💾 database, ⚡ cache, 📨 queue

   **Template:**

   ```d2
   vars: {
     d2-config: {
       theme-id: {theme_id}
       layout-engine: {layout}
     }
   }

   shape: sequence_diagram

   # Actors are defined implicitly by their first appearance
   "👤 Client" -> "🌐 API Gateway": "POST /auth/login"
   "🌐 API Gateway" -> "🔐 Auth Service": validate credentials
   "🔐 Auth Service" -> "💾 Database": lookup user
   "💾 Database" -> "🔐 Auth Service": user record
   "🔐 Auth Service" -> "🌐 API Gateway": JWT token
   "🌐 API Gateway" -> "👤 Client": "200 OK {token}"
   ```

7. **Validate**:

   ```bash
   d2 validate {output_file}
   ```

   Fix any errors using `$PLUGIN_DIR/references/guides/troubleshooting.md`.

8. **Save**:

   ```bash
   mkdir -p {output_directory}
   ```

   Filename: `sequence-{short-description}-{YYYYMMDD}.d2`

9. **Render** (if `auto_render=true`):

   ```bash
   d2 {output_file} {output_directory}/{basename}.svg
   ```

## Advanced Sequence Features

### Notes

Attach a note to an actor using dot notation — no arrow needed:

```d2
shape: sequence_diagram
alice -> bob: request
bob."This is a note attached to bob"
```

Notes can also go inside groups (see below).

### Groups (Fragments)

Label a subset of messages with a named group. **Actors used inside a group must be pre-declared at the top level:**

```d2
shape: sequence_diagram

# Pre-declare actors when using groups
client
server
db

happy path: {
  client -> server: "POST /login"
  server -> db: lookup user
  db -> server: user record
  server -> client: "200 JWT"
}

error path: {
  client -> server: "POST /login"
  server -> client: "401 Unauthorized"
}
```

Groups render as named frames around their messages — equivalent to Mermaid's `alt/opt/loop`.

### Spans (Activation Boxes)

Show the duration of an actor's activity using named spans via dot notation:

```d2
shape: sequence_diagram
# alice.t1 creates a span named t1 on alice's lifeline
alice.t1 -> bob
alice.t1 <- bob
```

Nested spans create nested activation boxes:

```d2
shape: sequence_diagram
alice.outer -> bob
alice.outer.inner -> bob
alice.outer.inner <- bob
alice.outer <- bob
```

### Self-messages

```d2
shape: sequence_diagram
service -> service: "internal processing"
```

## Critical Rules

- `shape: sequence_diagram` is REQUIRED — without it, D2 renders a flow graph instead
- Actors are defined implicitly on first use — no separate actor declaration needed
- **Exception:** actors used inside groups MUST be pre-declared at the top level
- Quote all labels containing `:` or other special characters
- Use `->` for messages (D2 syntax), never `-->`
- Keep actor names consistent across all messages (case-sensitive)
- Notes use `actor."text"` syntax — NOT a self-loop `actor -> actor: text`

## Output

```d2
{complete diagram}
```

**Saved to:** {filename}
**Validation:** passed
**Participants:** {list} | **Messages:** {count}

## Reference

- Troubleshooting: `$PLUGIN_DIR/references/guides/troubleshooting.md`
- Common mistakes: `$PLUGIN_DIR/references/guides/common-mistakes.md`
