---
name: Yolo Merge
description: Push, PR, and merge branches sequentially
---

Merge the specified branches one at a time to avoid force pushes.

**Branches to merge:** $ARGUMENTS

## Process

For each branch in order:

1. **Push** - `but push <branch>`
2. **Create PR** - `gh pr create --head <branch> --title "<branch title>" --body "..."`
3. **Merge PR** - `gh pr merge <pr-number> --merge`
4. **Pull** - `but pull` to update base before next branch

## PR Format

- **Title**: Derive from branch name or first commit message
- **Body**: Brief summary, no footers

## Error Handling

- If push fails, report and skip to next branch
- If PR creation fails (already exists), try to merge existing PR
- If merge fails (conflicts), report and continue to next branch
- If pull fails due to uncommitted changes, report but continue

## After All Branches

Report summary:
- Successfully merged: [list]
- Failed: [list with reasons]
