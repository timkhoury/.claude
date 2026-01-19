---
name: beads-cleanup
description: Clean up old closed beads issues to reduce database size. Use when the beads database is getting cluttered with old closed issues.
---

# Beads Cleanup

Clean up old closed issues to keep the beads database lean.

## When to Use

- `.beads/` directory is getting large
- Many old closed issues cluttering `bd list`
- Before archiving/sharing the project

## Cleanup Commands

```bash
# Compact old closed issues (summarizes and archives)
bd compact --older-than 30d

# Delete specific closed issues
bd delete <id1> <id2> ...

# Export before cleanup (backup)
bd export --status=closed > closed-issues-backup.jsonl
```

## Compaction

Compaction uses semantic summarization to preserve essential context while reducing storage:

```bash
bd compact --older-than 30d --dry-run  # Preview what would be compacted
bd compact --older-than 30d            # Actually compact
```

**What compaction does:**
- Summarizes issue description and comments
- Preserves key metadata (title, type, priority, dates)
- Reduces storage while maintaining searchability
- Original history recoverable via `bd restore`

## Best Practices

1. **Export first** - Always backup before bulk operations
2. **Use dry-run** - Preview changes before applying
3. **Keep recent** - Don't compact issues less than 30 days old
4. **Sync after** - Run `bd sync` to push changes

## Recovery

If you need to restore a compacted issue's full history:

```bash
bd restore <id>  # Restores from git history
```
