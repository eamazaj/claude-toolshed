# trim-md

Trim and optimize markdown files for LLM agent consumption. Removes token waste (extra blank lines, trailing whitespace, hard tabs), normalizes document structure (heading hierarchy, code block style), and produces a summary of changes.

See the [root README](../../README.md#trim-md) for a quick overview.

## Contents

- [Install](#install)
- [Commands](#commands)
- [Auto-formatting hook](#auto-formatting-hook)
- [How it works](#how-it-works)
  - [Dual-config strategy](#dual-config-strategy)
  - [Opt-out](#opt-out)
- [Rules](#rules)
  - [Full mode (15 rules)](#full-mode-15-rules)
  - [Safe mode (4 rules)](#safe-mode-4-rules)
  - [Disabled rules](#disabled-rules)
- [Output](#output)
- [Testing](#testing)

## Install

```text
/plugin install trim-md@claude-toolshed
```

**Requires:** Node.js (for `npx markdownlint-cli2`, auto-downloaded on first run)

## Commands

| Command | What it does |
| --- | --- |
| `/trim-md docs/` | Fix all markdown files in `docs/` |
| `/trim-md file.md other.md` | Fix specific files |
| `/trim-md dry-run .` | Preview what would change without modifying files |
| `/trim-md` | Fix all markdown files in current directory |

The `dry-run` flag is flexible — `dry`, `dry-run`, `--dry-run`, and `dryrun` are all recognized.

## Auto-formatting hook

The plugin includes a `PostToolUse` hook that automatically formats `.md` files whenever Claude writes or edits them. No manual invocation needed — every markdown file touched during a session gets lint-fixed and table-compacted on the fly.

The hook is registered in `hooks/hooks.json` and activates automatically when the plugin is installed. It:

1. Reads the file path from the hook JSON payload
2. Skips non-`.md` files immediately (zero overhead for other file types)
3. Runs `trim-md.sh` on the single file (markdownlint --fix + table compaction)

To disable the hook without uninstalling the plugin, use `/hooks` in Claude Code and delete the trim-md entry.

## How it works

The skill delegates to a bash script (`trim-md.sh`) that:

1. Collects all `.md` and `.markdown` files from the given paths (recursive for directories)
2. Excludes `node_modules/`, `.worktrees/`, `.git/`, `.pytest_cache/`, `.venv/`, `__pycache__/`
3. Filters out files with the `<!-- trim-md:disable -->` opt-out comment
4. Detects whether the project has an existing markdownlint config
5. Runs `npx markdownlint-cli2 --fix` (or lint-only in dry-run mode)
6. Prints a summary with modified file paths

### Dual-config strategy

The plugin ships two markdownlint configs to avoid conflicts with existing project linters:

| Mode | Config | When used | Rules |
| --- | --- | --- | --- |
| **full** | `full.markdownlint-cli2.jsonc` | No existing markdownlint config detected | 15 rules (token waste + heading hierarchy + structural clarity) |
| **safe** | `safe.markdownlint-cli2.jsonc` | Existing `.markdownlint*` config found at project root | 4 rules (universally non-conflicting) |

**Detection:** The script resolves the project root via `git rev-parse --show-toplevel` (fallback: `pwd`), then checks for any file matching `.markdownlint*` or `.markdownlint-cli2*` at that root. No config parsing — just file existence.

### Opt-out

Add this HTML comment on its own line anywhere in a markdown file to exclude it from processing:

```html
<!-- trim-md:disable -->
```

The comment must appear as a standalone line (with optional leading/trailing whitespace). Inline mentions within prose, code blocks, or frontmatter are ignored. The comment is invisible in rendered markdown.

## Rules

### Full mode (15 rules)

**Token waste reduction** — removes bytes that get tokenized but carry zero semantic value:

| Rule | Name | LLM rationale |
| --- | --- | --- |
| MD009 | No trailing spaces | Invisible bytes that still consume tokens |
| MD010 | No hard tabs | Tabs tokenize inconsistently across models |
| MD012 | No multiple blank lines (max: 1) | Each blank line wastes ~1 token |
| MD047 | File ends with newline | Prevents tokenization edge cases at file boundaries |

**Heading hierarchy** — headings are the #1 structural signal for RAG chunking:

| Rule | Name | LLM rationale |
| --- | --- | --- |
| MD001 | Heading increment | Skipped levels break semantic hierarchy; RAG uses headings as chunk boundaries |
| MD003 | ATX heading style | Consistent `#` headings; Setext underlines waste tokens |
| MD022 | Blanks around headings | Clean section boundaries for chunking |
| MD025 | Single top-level H1 | Unambiguous document root for hierarchy parsing |

**Structural clarity** — clean boundaries help LLMs parse document structure:

| Rule | Name | LLM rationale |
| --- | --- | --- |
| MD031 | Blanks around fenced code | Clean code block boundaries |
| MD032 | Blanks around lists | Proper list parsing by renderers and LLMs |
| MD037 | No spaces in emphasis | Prevents broken emphasis rendering |
| MD038 | No spaces in code spans | Prevents broken code span rendering |
| MD039 | No spaces in link text | Prevents broken link rendering |
| MD046 | Fenced code blocks | Fenced blocks are unambiguous; indented blocks can be confused with nested list content |
| MD048 | Backtick code fences | Consistent style; tildes are rare and waste a "novelty" token |

### Safe mode (4 rules)

When the project already has a markdownlint config, only these universally non-conflicting rules are applied:

| Rule | Name | Why it's safe |
| --- | --- | --- |
| MD009 | No trailing spaces | No config wants invisible whitespace |
| MD010 | No hard tabs | No config wants tabs in markdown prose |
| MD012 | No multiple blank lines (max: 1) | No config wants 3+ consecutive blanks |
| MD047 | File ends with newline | No config wants missing final newline |

### Disabled rules

| Rule | Name | Why disabled |
| --- | --- | --- |
| MD013 | Line length | LLMs don't care about 80-char wraps; hard wraps split semantic units |
| MD024 | No duplicate headings | Valid in large docs with repeated section patterns |
| MD033 | No inline HTML | HTML inside code blocks (Mermaid, etc.) is legitimate |
| MD036 | No emphasis as heading | Used stylistically in some documents |
| MD040 | Code block language | Unfixable automatically; unlabeled blocks don't affect LLM comprehension |
| MD041 | First line is H1 | Files with YAML frontmatter legitimately don't start with H1 |
| MD055 | Table pipe style | Pure cosmetics, no semantic impact |
| MD056 | Table column count | Minor inconsistencies don't confuse LLMs |
| MD060 | Table column alignment | Pure cosmetics, zero token or semantic impact |

## Output

**Fix mode:**

```text
trim-md summary
───────────────
Mode:                full (no existing config)
Files scanned:       42
Files skipped:       1 (opt-out)
Files checked:       41
Files modified:      3

Modified files:
  docs/README.md
  docs/guides/setup.md
  CONTRIBUTING.md
```

**Dry-run mode** — shows per-file issue breakdown without modifying files:

```text
trim-md summary (dry run)
─────────────────────────
Mode:                safe (existing markdownlint config detected)
Files scanned:       42
Files skipped:       1 (opt-out)
Files checked:       41
Files with issues:   2

Issues by file:

  docs/README.md
    Line 3 error MD012/no-multiple-blanks Multiple consecutive blank lines [Expected: 1; Actual: 3]
    Line 45:17 error MD009/no-trailing-spaces Trailing spaces [Expected: 0 or 2; Actual: 3]
  docs/guides/setup.md
    Line 12 error MD012/no-multiple-blanks Multiple consecutive blank lines [Expected: 1; Actual: 2]

39 file(s) clean
```

## Testing

```bash
# Unit tests (29 assertions, ~15 seconds)
bash plugins/trim-md/tests/test-trim-md.sh

# Integration test via Claude skill invocation (run from a regular terminal)
bash plugins/trim-md/tests/test-integration.sh
```

## Research basis

This config is based on research into markdown optimization for LLM consumption:

- **Cloudflare "Markdown for Agents" (2026):** HTML-to-Markdown achieves ~80% token reduction; clean markdown is the most token-efficient structured format
- **Anthropic CLAUDE.md guidance:** ~150-200 instructions is the ceiling for reliable following; every unnecessary token degrades adherence
- **GitHub agents.md analysis (2500+ repos):** markdownlint validation as a standard agent workflow step
- **General RAG research:** heading hierarchy is the #1 structural factor for chunking accuracy
