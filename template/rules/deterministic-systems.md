# Deterministic Systems Over Manual Duplication

Prefer build systems that generate outputs from structured sources over manual duplication.

## Examples

| Pattern | Source | Generated Output |
|---------|--------|------------------|
| Agent definitions | YAML in `.claude/agents-src/` | Markdown in `.claude/agents/` |
| Issue tracking | Structured YAML (beads) | Git-backed state |
| Change proposals | OpenSpec format | Specs and tasks |

## When to Apply

When you notice repeated patterns or manual duplication, consider whether a deterministic build system would be more maintainable:

- **Multiple similar files** that drift out of sync
- **Copy-paste patterns** that need updating in multiple places
- **Structured data** being manually formatted
- **Configuration** scattered across files

## Benefits

- Single source of truth
- Consistent formatting
- Easier updates (change once, regenerate)
- Validation at build time
- Reduced human error
