# Git & Commit Rules

## GitButler Workflow

- Always invoke `gitbutler` skill before committing
- Use `but push <branch>` instead of `git push`
- Never use `but push --force` (invalid flag - `but push` auto-handles force push when needed)
- Never use `but describe <commit-sha>` (opens interactive editor, hangs session)

## Commit Guidelines

- Never commit without explicit user request
- Never push without explicit user request
- Group commits logically: feature+tests together, config separate, docs separate
- Do not add "Generated with Claude Code" footer to commits or PRs

## PR Creation

Use `gh pr create --head <branch-name>` which handles push automatically.
