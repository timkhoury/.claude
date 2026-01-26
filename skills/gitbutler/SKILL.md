---
name: gitbutler
description: Invoke BEFORE any git/but commands - branches, commits, pushes, status, PR creation. Don't use but/git commands without this skill.
---

# GitButler Workflow

GitButler manages multiple virtual branches simultaneously. See git-rules for constraints.

## Key Practices

- **Run `but status` after every action** - file IDs shift after commits
- **Group changes logically** - feature+tests together, config separate

## Command Reference

| Command | Description |
|---------|-------------|
| `but status` | View uncommitted changes by branch (`-v` verbose, `-f` files, `-u` upstream) |
| `but show <id>` | Show commit or branch details (`-v` for verbose) |
| `but branch new <name>` | Create new virtual branch |
| `but stage <file-id> <branch>` | Assign file/hunk to branch |
| `but rub <source> <target>` | Squash commits, amend, move commits |
| `but commit <branch> --only -m "..."` | Commit only assigned files |
| `but reword <id> -m "message"` | Edit commit message (or rename branch) |
| `but push <branch>` | Push branch to remote (`--dry-run` to preview) |
| `but pull` | Update branches from remote |
| `but pull --check` | Check merge status without updating |

## Staging Files

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
| `bulk-stage.sh` | Stage multiple files with automatic ID refresh |
| `resolve-ambiguous.sh` | Handle ID ambiguity using git add workaround |
| `branch-health.sh` | Branch status overview (unpushed, remote sync) |

## Branch Naming

Descriptive names without conventional commit prefixes:

| Good | Bad |
|------|-----|
| `server-action-optimizations` | `perf/server-action-optimizations` |
| `fix-login-redirect` | `fix/login-redirect` |

## Standard Workflow

```bash
but branch new feature-name           # 1. Create branch
# ... make changes ...
but status                            # 2. See changed files
~/.claude/skills/gitbutler/bulk-stage.sh feature-name file1.ts file2.ts
but commit feature-name --only -m "feat: description"
```

## Commit Workflow

1. Run `but status` to see branches and uncommitted changes
2. If multiple branches have changes, ask user which branch
3. Group changes logically (feature+tests together, config separate)
4. For each group:
   - Stage with `bulk-stage.sh`
   - Commit with `but commit <branch> --only -m "..."`
5. Confirm with `but status`

## ID Ambiguity

If you see "Source 'XX' is ambiguous":

```
g8 D .claude/agents/example.md
│  │  └── file path
│  └── status (D=Deleted, M=Modified, A=Added, R=Renamed)
└── ID (just "g8", NOT "g8D")
```

**Workaround:**
```bash
git add <file-path>              # Stage with git directly
but commit <branch> -m "..."     # Omit --only to include staged changes
but rub <new-commit> <previous>  # Squash into previous if needed
```

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
