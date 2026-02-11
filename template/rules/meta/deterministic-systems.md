# Deterministic Systems Over Manual Duplication

Prefer build systems and scripts that generate outputs from structured sources over manual duplication or AI-driven classification.

## Examples

| Pattern | Source | Generated Output |
|---------|--------|------------------|
| Agent definitions | YAML in `.claude/agents-src/` | Markdown in `.claude/agents/` |
| Task tracking | Built-in Task tools | Session-scoped state |
| Change proposals | OpenSpec format | Specs and tasks |
| File sync operations | Shell script with flags | Copied/updated files |

## Shell Scripts for Repetitive Operations

When a skill involves repetitive file operations or complex conditional logic, extract the deterministic parts into a shell script.

### Script Location

| Location | When to Use |
|----------|-------------|
| `.claude/skills/<skill>/` | Default - colocate with the skill |
| `.claude/scripts/` | Only if shared across multiple skills |

**Prefer colocation.** Most scripts are skill-specific and should live alongside their `SKILL.md`. This keeps the skill self-contained and discoverable.

### Script Design Principles

1. **Flags over AI judgment** - Use explicit flags (`--tools=X`, `--dry-run`) instead of asking the AI to classify or decide
2. **Safe defaults** - Default to showing what would change rather than applying changes
3. **Self-documenting** - Include `--help` with examples
4. **Consistent patterns** - Use similar flag names across scripts (`--auto`, `--report`, `--force`)
5. **Colored output** - Use ANSI colors for clear visual feedback
6. **Idempotent** - Running twice produces the same result

### When to Use Scripts vs Skill Logic

**Extract to script when:**
- File copying, moving, or comparing
- Tool/directory existence checks
- Operations that should be testable independently
- Complex conditional logic based on file system state
- Pattern matching on file paths
- Iterating over files with filtering/counting logic (for-loops over spec files, counting patterns)

**Keep in skill when:**
- Gathering user input (AskUserQuestion)
- Making decisions that require codebase understanding
- Operations that need AI judgment (code review, refactoring)
- Orchestrating multiple steps with user feedback

### Example Structure

```bash
#!/usr/bin/env bash
# my-operation.sh [--auto|--report|--force]

MODE="report"  # Safe default
case "${1:-}" in
  --auto)   MODE="auto" ;;
  --report) MODE="report" ;;
  --force)  MODE="force" ;;
  --help)   echo "Usage: ..."; exit 0 ;;
esac

# Deterministic logic here...
if [[ "$MODE" == "report" ]]; then
  echo "Would update: $file"
else
  cp "$src" "$dst"
fi
```

## When to Apply

Consider a deterministic system when you notice:

- **Multiple similar files** that drift out of sync
- **Copy-paste patterns** that need updating in multiple places
- **Structured data** being manually formatted
- **Configuration** scattered across files
- **Skills with complex file operations** that could be scripted
- **AI making the same classification decisions repeatedly**
- **Pseudocode algorithms in skill docs** that agents translate into bash for-loops - extract the deterministic parts into script subcommands

## Benefits

- Single source of truth
- Consistent formatting
- Easier updates (change once, regenerate)
- Validation at build time
- Reduced human error
- Testable independently of AI
- Predictable behavior across invocations
