---
name: gitbutler
description: Manage git operations through GitButler virtual branches. Use when working with branches, commits, pushes, status checks, or PR creation. Invoke before any git/but commands.
---

# GitButler Workflow

GitButler manages multiple virtual branches simultaneously. See git-rules for constraints.

## Key Practices

- **Run `but status` before committing** - to get current file/hunk IDs
- **Use `--files` for selective commits** - avoids ID-shifting problems
- **Group changes logically** - feature+tests together, config separate

## Command Reference

| Command | Description |
|---------|-------------|
| `but status` | View uncommitted changes by branch (`-v` verbose, `-f` files, `-u` upstream) |
| `but show <id>` | Show commit or branch details (`-v` for verbose) |
| `but branch new <name>` | Create new virtual branch |
| `but stage <file-id> <branch>` | Assign file/hunk to branch (use for organizing, not committing) |
| `but rub <source> <target>` | Squash commits, amend, move commits |
| `but commit <branch> --files <ids> -m "..."` | Commit specific files/hunks by ID (preferred) |
| `but commit <branch> --only -m "..."` | Commit only staged files |
| `but commit <branch> -m "..."` | Commit all changes on branch |
| `but reword <id> -m "message"` | Edit commit message (or rename branch) |
| `but push <branch>` | Push branch to remote (`--dry-run` to preview) |
| `but pull` | Update branches from remote |
| `but pull --check` | Check merge status without updating |

## Committing Specific Files

**Preferred:** Use `--files` to commit specific files/hunks directly by their IDs:
```bash
but status                                    # Get file IDs (e.g., g1, g2, h3)
but commit <branch> --files g1,g2,h3 -m "..."  # Commit those specific items
```

This avoids the ID-shifting problem entirely - no staging step needed.

## Staging Files (for organizing across branches)

Use staging when you need to organize files across multiple branches before committing:

**For multiple files, use `bulk-stage.sh`** - handles ID refresh automatically:
```bash
~/.claude/skills/gitbutler/bulk-stage.sh <branch> file1.ts file2.ts
```

**For a single file:**
```bash
but stage <file-id> <branch>
```

File IDs change after each `but stage` operation. Never chain `but stage` commands with `&&` or loops.

## Rub Operations

| Source | Target | Operation |
|--------|--------|-----------|
| File/Hunk | Commit | Amend commit |
| Commit | Commit | Squash |
| Commit | Branch | Move commit |

## Helper Scripts

Scripts in `~/.claude/skills/gitbutler/`. All support `--help` and `--dry-run`.

| Script | Purpose |
|--------|---------|
| `bulk-stage.sh` | Stage multiple files to organize across branches (use `--files` for commits) |
| `branch-health.sh` | Branch status overview (unpushed, remote sync) |

## Branch Naming

Descriptive names without conventional commit prefixes:

| Good | Bad |
|------|-----|
| `server-action-optimizations` | `perf/server-action-optimizations` |
| `fix-login-redirect` | `fix/login-redirect` |

## Standard Workflow

```bash
but branch new feature-name                          # 1. Create branch
# ... make changes ...
but status                                           # 2. See changed files with IDs
but commit feature-name --files g1,g2 -m "feat: ..." # 3. Commit specific files by ID
```

## Commit Workflow

1. Run `but status` to see branches and uncommitted changes with IDs
2. If multiple branches have changes, ask user which branch
3. Group changes logically (feature+tests together, config separate)
4. For each group:
   - Use `but commit <branch> --files <ids> -m "..."` with the file IDs
5. Confirm with `but status`

## Locked Files (🔒)

When `but status` shows a file locked to another branch:

1. Stage to its locked branch: `but stage <file-id> <locked-branch>`
2. Commit to that branch separately
3. Continue with other branches

## Recovery

If you need to undo operations or restore from history, use the GitButler desktop app. The oplog and restore commands can cause issues - avoid using them from CLI.

## PR Creation

Ask user before pushing or creating PRs.

```bash
but push <branch-name>             # Push first - required for GitButler branches
gh pr create --head <branch-name>  # Then create PR
```

**Note:** `gh pr create` does NOT auto-push GitButler virtual branches. Always `but push` first.

PR descriptions: Summary and Test plan only, no footers.
