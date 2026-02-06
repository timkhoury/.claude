# Git Rules

> NEVER use `git commit` or `git push` directly. Use GitButler (`but`) commands.

## Prerequisite

**Always invoke the `gitbutler` skill before using `but` commands.** The skill loads GitButler-specific context and ensures correct command usage.

## Mandatory Commands

| Instead of | Use |
|------------|-----|
| `git commit` | `but commit <branch> -m "..."` (see Commit Patterns below) |
| `git push` | `but push <branch>` |
| `git status` | `but status` |

## Commit Patterns

| Scenario | Command |
|----------|---------|
| Commit specific files | `but commit <branch> -p <id1>,<id2> -m "..."` |
| Commit all staged to branch | `but commit <branch> --only -m "..."` |
| Commit everything on branch | `but commit <branch> -m "..."` |

**Prefer `-p`** for selective commits - it takes file/hunk IDs directly, avoiding the ID-shifting problem when staging multiple files.

## Critical Rules

1. **Concise commit messages** - add a body for the "why" only when non-obvious; no footers, no Co-Authored-By
2. **NEVER push after committing** - only push when explicitly requested or at session end
3. **Use `git mv` for file moves** - preserves history (this is the one `git` command allowed)

## Commit Message Format

- Conventional prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `perf:`
- Single line for obvious changes
- Add a body paragraph explaining "why" when the reason isn't self-evident

## Danger Zone

| Never Do | Use Instead |
|----------|-------------|
| `git stash` | Nothing - breaks GitButler virtual branches |
| `git checkout main` | Nothing - breaks GitButler virtual branches |
| `but undo` | `but restore <snapshot-id>` - undo can lose work |
| `but reword <id>` without `-m` | Always use `-m "message"` - avoids interactive editor |
| `but pr new` | `gh pr create` - avoids interactive editor |
| Chain `but stage` with `&&` | Use `-p` on commit, or `bulk-stage.sh` for staging only |
