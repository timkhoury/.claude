# OpenSpec Rules

These rules apply when the project uses OpenSpec for change management.

## Slash Commands

```bash
/openspec:proposal <description>   # Create new OpenSpec change proposal
/openspec:apply <change-id>        # Implement an approved OpenSpec change
/openspec:archive <change-id>      # Archive a deployed OpenSpec change
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

| Command | When to commit |
|---------|----------------|
| `/openspec:proposal` | After validation passes - commit all proposal files to new branch |
| `/openspec:apply` | After each logical unit of work (task or task group) - incremental commits |
| `/openspec:archive` | After archiving - commit the moved files and any spec updates |

This ensures atomic commits with clear history, not one large commit at the end.

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

OpenSpec changes should be tracked with beads for visibility:

| OpenSpec Stage | Beads Action |
|----------------|--------------|
| After `/openspec:proposal` | Create tracking bead: `bd create --title="<change-id>" --type=feature` |
| Before `/openspec:archive` | Ensure bead exists and is `in_progress` |
| After `/openspec:archive` | Close bead: `bd close <id> --reason="Archived: <change-id>"` |

**Critical:** Always archive OpenSpec BEFORE closing the tracking bead.
