# Git Rules

> NEVER use `git commit` or `git push` directly. Use GitButler (`but`) commands.

## Prerequisite

**Always invoke the `gitbutler` skill before using `but` commands.** The skill loads GitButler-specific context and ensures correct command usage.

## Mandatory Commands

| Instead of | Use |
|------------|-----|
| `git commit` | `but commit <branch> --only -m "..."` |
| `git push` | `but push <branch>` |
| `git status` | `but status` |

## Critical Rules

1. **Single-line commit messages** - no body, no footers, no Co-Authored-By
2. **NEVER push after committing** - only push when explicitly requested or at session end
3. **Use `git mv` for file moves** - preserves history (this is the one `git` command allowed)

## Commit Message Format

- Conventional prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `perf:`
- Single line only, no HEREDOC

## Danger Zone

| Never Do | Use Instead |
|----------|-------------|
| `but undo` | `but restore <snapshot-id>` - undo can lose work |
| `but reword <id>` without `-m` | Always use `-m "message"` - avoids interactive editor |
| `but pr new` | `gh pr create` - avoids interactive editor |
| Chain `but stage` with `&&` | Use `bulk-stage.sh` - IDs shift after each stage |
