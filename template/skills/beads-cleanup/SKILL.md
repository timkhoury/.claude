---
name: beads:cleanup
description: >
  Clean up old closed beads issues to reduce database size.
  Use when the beads database is getting cluttered with old closed issues.
allowed-tools: [Bash, AskUserQuestion]
---

# Beads Cleanup

Reduce database size by compacting or deleting old closed issues.

## Usage

```
/beads:cleanup [--days N] [--hard]
```

| Argument | Default | Description |
|----------|---------|-------------|
| `--days` | 30 | Minimum age in days for closed issues |
| `--hard` | false | Use aggressive deletion instead of compaction |

## Approaches

| Mode | Command | Effect |
|------|---------|--------|
| **Compact** (default) | `bd admin compact` | Summarizes content, preserves metadata, recoverable |
| **Cleanup** (`--hard`) | `bd admin cleanup` | Deletes issues, converts to tombstones, permanent |

Prefer compaction unless you need aggressive cleanup.

## Workflow

### Step 1: Parse Arguments

Extract `--days` (default 30) and `--hard` flag from arguments.

### Step 2: Preview Changes

Run dry-run to show what would be affected:

```bash
# Compaction (default)
bd admin compact --prune --older-than <days> --dry-run

# Or cleanup (if --hard)
bd admin cleanup --older-than <days> --dry-run
```

### Step 3: Confirm with User

Use AskUserQuestion to confirm before proceeding. Show:
- Number of issues to be affected
- The `--days` threshold used
- Which mode (compact vs cleanup)

### Step 4: Execute

If confirmed, run the appropriate command:

```bash
# Compaction (default)
bd admin compact --prune --older-than <days>

# Or cleanup (if --hard)
bd admin cleanup --older-than <days> --force
```

### Step 5: Sync Changes

After cleanup, sync to commit the changes:

```bash
bd sync
```

## Recovery

Compacted issues can be restored from git history:

```bash
bd restore <id>
```

Deleted issues (via `--hard`) cannot be recovered.

## Example Session

```
User: /beads:cleanup --days 14

Claude: Running preview...
[Shows dry-run output]

Found 5 closed issues older than 14 days eligible for compaction.
Proceed?

User: Yes

Claude: [Runs compact]
Compacted 5 issues. Use `bd restore <id>` if you need to recover any.
```
