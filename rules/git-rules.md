# Git Rules

> NEVER use `git commit` or `git push` directly. Use GitButler (`but`) commands.

## Mandatory Commands

| Instead of | Use |
|------------|-----|
| `git commit` | `but commit <branch> --only -m "..."` |
| `git push` | `but push <branch>` |
| `git status` | `but status` |

## Critical Rules

1. **Invoke gitbutler skill** before any git/commit operations for full workflow guidance
2. **Run `but status` after every action** - file IDs shift after commits
3. **Use `--only` flag** when committing: `but commit <branch> --only -m "..."`
4. **Single-line commit messages** - no body, no footers, no Co-Authored-By
5. **NEVER push after committing** - only push when explicitly requested or at session end
6. **Use `git mv` for file moves** - preserves history (this is the one `git` command allowed)

## Commit Message Format

- Conventional prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `perf:`
- Single line only, no HEREDOC

## Danger Zone

| Never Do | Use Instead |
|----------|-------------|
| `git commit` | `but commit <branch> --only -m "..."` |
| `git push` | `but push <branch>` |
| `but commit` without `--only` | Always include `--only` flag |
| Push after every commit | Batch commits, push at session end |
