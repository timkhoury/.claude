# OpenSpec Rules (when openspec/ folder exists)

These rules apply when the project uses OpenSpec for change management.

## Slash Commands

```bash
/openspec:proposal <description>   # Create new OpenSpec change proposal
/openspec:apply <change-id>        # Implement an approved OpenSpec change
/openspec:archive <change-id>      # Archive a deployed OpenSpec change
```

**Invalid commands - do NOT use:**
```bash
npx openspec new ...               # This command does NOT exist
npx openspec proposal ...          # Use slash command instead
```

**Validation command:**
```bash
npx openspec validate --specs --strict   # Validate all specs with strict mode
npx openspec validate <change-id>        # Validate specific change
```

## When to Use OpenSpec

- Planning complex features or architectural changes
- Breaking changes or new capabilities
- Features requiring cross-cutting changes
- Anything that benefits from upfront design and structured implementation

## Commit Timing

Use gitbutler skill for commits during OpenSpec workflows:

| Command | When to commit |
|---------|----------------|
| `/openspec:proposal` | After validation passes - commit all proposal files to new branch |
| `/openspec:apply` | After each logical unit of work (task or task group) - incremental commits |
| `/openspec:archive` | After archiving - commit the moved files and any spec updates |

This ensures atomic commits with clear history, not one large commit at the end.

### GitButler Archive Commit Workaround

When archiving with GitButler, file moves (renames) and deletes can get split due to lock conflicts. Follow this process:

```bash
# 1. Run the archive
npx openspec archive <change-id> --yes

# 2. First commit - catches renames and spec updates
git add openspec/
but commit <branch> -m "docs: archive <change-id> OpenSpec change"

# 3. Check for leftover deletes (old change files showing as 🔒 locked)
but status

# 4. If deleted files remain unassigned, commit them separately
git add openspec/changes/<change-id>/
but commit <branch> -m "temp: remove old change files"

# 5. Squash into the archive commit
but status  # Get commit IDs
but rub <temp-commit> <archive-commit>
```

**Why this happens:** GitButler locks files to commits where they were modified. Archive moves files to a new path, but the old paths remain locked to historical commits, preventing them from being included in the first commit.

## PR Creation

```bash
gh pr create --head <branch-name>  # Handles push automatically
```

Do NOT include "Generated with Claude Code" footer in PR descriptions or commit messages.

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Mark manual testing tasks as complete | Only humans can verify manual tests |
| Mark tasks complete without doing them | False progress, bugs slip through |
| Use `--skip-specs` without asking user | Specs become out of sync with implementation |

**Archive failures:** If `openspec archive` fails due to spec validation errors, STOP and ask the user how to proceed. Never use `--skip-specs` without explicit user approval.

## Beads Integration

OpenSpec changes should be tracked with beads for visibility. See `workflow-integration.md` for the complete workflow.

**Quick reference (simple, 1-2 tasks):**

| OpenSpec Stage | Beads Action |
|----------------|--------------|
| After `/openspec:proposal` | Create tracking bead: `bd create --title="<change-id>" --type=feature` |
| Before `/openspec:archive` | Ensure bead exists and is `in_progress` |
| After `/openspec:archive` | Close bead: `bd close <id> --reason="Archived: <change-id>"` |

**Epic structure (3+ tasks):**

For complex changes, create an epic with child task beads mirroring tasks.md:

1. Create epic: `bd create --title="<change-id>" --type=epic`
2. Create task bead for each task in tasks.md
3. Set parent: `bd update <task-id> --parent=<epic-id>`
4. Mirror dependencies: `bd dep add <task-id> <blocking-task-id>`
5. Use `bd ready` to find unblocked work during implementation
6. Close tasks as completed, close epic after archiving OpenSpec

**Critical:** Always archive OpenSpec BEFORE closing the tracking bead/epic.

## Reference

For detailed OpenSpec workflow, format, and conventions, see `openspec/AGENTS.md` in the project.
