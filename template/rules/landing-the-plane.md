# Landing the Plane (Session Completion)

> **This workflow is for `/wrap` only.** Do NOT push after individual commits during a session.
> Batch all commits, then push once at the end to minimize CI runs.

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until changes are pushed to remote.

## Mandatory Workflow

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Run pr-check for code changes, skip for docs-only
3. **Archive OpenSpec changes first** (if applicable):
   ```bash
   openspec list                    # Check for active changes
   /openspec:archive <change-id>    # Archive completed changes BEFORE closing beads
   ```
4. **Update issue status** - Close finished work, update in-progress items
   - If OpenSpec was archived, close the tracking bead: `bd close <id> --reason="Archived: <change-id>"`
5. **PUSH TO REMOTE** - This is MANDATORY (only branches worked on this session):
   ```bash
   bd sync                      # Sync beads issues
   but push <branch>            # Push branches you committed to THIS session
   but status                   # Verify branch is pushed
   ```
6. **Clean up** - Clear stashes, prune remote branches
7. **Verify** - All changes committed AND pushed
8. **Hand off** - Provide context for next session

## Critical Rules

- Work is NOT complete until `but push <branch>` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
- Use `but push`, not `git push` (GitButler handles force push when needed)
- **ALWAYS archive OpenSpec before closing beads** - see workflow-integration.md
