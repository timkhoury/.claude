---
name: gitbutler
description: Invoke BEFORE any git/but commands - branches, commits, pushes, status, PR creation. Don't use but/git commands without this skill.
---

# GitButler Workflow

GitButler manages multiple virtual branches simultaneously.

## Critical Rules

> **When the user says "commit", use GitButler (`but commit`), not `git commit`.**

- **Run `but status` after every action** - File IDs shift after commits, stages, rubs, and other operations. Always refresh IDs before the next action. Never chain stage commands with `&&` or run them in parallel.
- **Commit in logical groupings** - Group related changes into separate commits (e.g., feature + tests in one commit, config changes in another)
- **Use the `--only` flag** when committing: `but commit <branch> --only -m "..."`
- **Ask which branch** if target is ambiguous (multiple branches with changes)
- **NEVER push after committing** - Only push when user explicitly requests OR at session end. Pushing triggers CI - batch commits to minimize runs.

## File Moves and Renames

**Always use `git mv` to move or rename files.** This preserves git history.

```bash
# Correct - preserves history
git mv src/old-path/file.tsx src/new-path/file.tsx

# Incorrect - loses history
# Creating new file + deleting old file
```

**Why:** `git mv` tells git this is a rename/move, not a delete+create. This keeps `git log --follow` working and preserves blame history.

## Command Reference

| Command | Description |
|---------|-------------|
| `but status` | View uncommitted changes by branch (`-v` verbose, `-f` files, `-u` upstream) |
| `but show <id>` | Show commit or branch details (`-v` for verbose) |
| `but branch new <name>` | Create new virtual branch |
| `but stage <file-id> <branch>` | Assign file/hunk to branch (preferred for file assignment) |
| `but rub <source> <target>` | General operation: squash commits, amend, move commits |
| `but commit <branch> --only -m "..."` | Commit only assigned files |
| `but reword <id> -m "message"` | Edit commit message (or rename branch) |
| `but push <branch>` | Push branch to remote (`--dry-run` to preview) |
| `but pull` | Update branches from remote (replaces `but base update`) |
| `but pull --check` | Check merge status without updating |
| `but oplog` | View operation history |
| `but restore <snapshot-id>` | Restore to specific snapshot |

## Stage vs Rub

**Use `but stage`** for assigning files/hunks to branches (clearer intent):
```bash
but stage <file-id> <branch>    # Assign file to branch
```

**CRITICAL: Stage files one at a time.** File IDs change after each operation. Never use for loops, `&&` chains, or parallel commands:

```bash
# WRONG - IDs become stale after first stage
but stage a1 branch && but stage b2 branch && but stage c3 branch

# WRONG - parallel execution with stale IDs
but stage a1 branch & but stage b2 branch & but stage c3 branch

# CORRECT - refresh IDs after each operation
but stage a1 branch
but status              # Get fresh IDs
but stage <new-id> branch
but status              # Get fresh IDs again
but stage <new-id> branch
```

**Use `but rub`** for commit operations:

| Source | Target | Operation |
|--------|--------|-----------|
| File/Hunk | Commit | Amend commit |
| Commit | Commit | Squash |
| Commit | Branch | Move commit |

## Standard Workflow

```bash
but branch new feature-name           # 1. Create branch
# ... make changes ...
but status                            # 2. See file IDs
but stage <file-id> feature-name      # 3. Assign files to branch
but commit feature-name --only -m ""  # 4. Commit (use --only)
```

## Commit Workflow (Step by Step)

When user asks to commit:

1. Run `but status` to see branches and uncommitted changes
2. If multiple branches have changes, ask user which branch to commit to
3. **Group changes logically** - Identify distinct concerns:
   - Feature code + its tests = one commit
   - Config/tooling changes = separate commit
   - Documentation updates = separate commit
   - Unrelated bug fixes = separate commits
4. For each logical group:
   - Assign related files with `but stage <file-id> <branch>`
   - Use `but commit <branch> --only -m "<message>"`
5. Confirm success with `but status`

**Commit message rules:**
- **Single-line only** - no body, no description, no footer
- **No Co-Authored-By** - no attribution footers of any kind
- **No HEREDOC** - use simple `-m "prefix: message"` syntax
- Use conventional prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `perf:`

**Example logical groupings:**
```
# Group 1: Feature + tests
but status                          # Get current file IDs
but stage <component-file> my-branch
but stage <test-file> my-branch
but commit my-branch --only -m "feat: add feature X with tests"

# Group 2: Config change
but status                          # IDs shifted after commit - refresh!
but stage <config-file> my-branch
but commit my-branch --only -m "chore: update config for Y"
```

## ID Ambiguity

If you see "Source 'XX' is ambiguous", it means the short ID matches both an uncommitted file AND a committed file in the branch history.

**Understanding `but status` output:**
```
g8 D .claude/agents/example.md
│  │  └── file path
│  └── status (D=Deleted, M=Modified, A=Added, R=Renamed)
└── ID (just "g8", NOT "g8D")
```

**Workaround: git add + commit without --only**
```bash
git add <file-path>              # Stage with git directly
but commit <branch> -m "..."     # Omit --only to include staged changes
```

**After using this workaround**, squash into the previous commit:
```bash
but rub <new-commit> <previous-commit>  # Squashes new into previous
```

## Squashing Commits

To combine commits (e.g., after using the ambiguity workaround):

```bash
but rub <commit-to-squash> <target-commit>
```

Example: `but rub abc123 def456` squashes abc123 into def456.

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Chain `but stage` with `&&` or loops | File IDs change after each operation - subsequent commands use stale IDs |
| `but undo` | Can lose uncommitted work permanently - restores to previous snapshot |
| `but commit` without `--only` | Includes unassigned files (exception: ID ambiguity workaround) |
| `but reword <id>` without `-m` | Opens interactive editor, hangs session - always use `-m "message"` |
| `but pr new` | Opens interactive editor - use `gh pr create` instead |
| `but push --force` | Invalid flag - `but push` auto-handles force push when needed |
| `git push` instead of `but push` | Bypasses GitButler, use `but push <branch>` instead |
| `git commit` instead of `but commit` | Bypasses GitButler, breaks virtual branches |
| Push after committing | Triggers CI - batch commits, push only at session end or explicit request |

## Locked Files (🔒)

When `but status` shows a file with 🔒 locked to a commit on another branch:

**DO NOT undo previous commits.** Instead:
1. Assign the locked file to its locked branch: `but stage <file-id> <locked-branch>`
2. Commit it to that branch separately
3. Continue with other branches normally

The lock indicates where the file was last modified - respect that lineage by committing changes there.

## Recovery

**WARNING: `but undo` can lose uncommitted work. Avoid using it.**

If you need to recover from a bad state:
```bash
but oplog                   # See operation history
but restore <snapshot-id>   # Restore to specific point (use with --force if needed)
```

Prefer `but restore` with a specific snapshot ID over `but undo`.

## PR Creation

**Always ask the user before pushing or creating a PR.** The user decides when to push to remote.

```bash
# Only after user explicitly requests PR creation:
gh pr create --head <branch-name>  # Handles push automatically
```

**PR titles:** Use plain descriptive titles without conventional commit prefixes.

**PR descriptions:**
- **No footers** - no `Generated with Claude Code`, no signatures, no attribution
- Focus on Summary and Test plan sections only
- Keep descriptions concise and factual
