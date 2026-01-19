# Beads Workflow

This project uses [beads](https://github.com/Dicklesworthstone/beads_viewer) for issue tracking. Issues are stored in `.beads/` and tracked in git.

## Essential Commands

```bash
# View issues
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies

# Create & update
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id> --reason="Completed"
bd close <id1> <id2>  # Close multiple issues at once

# Sync
bd sync               # Commit and push changes
```

## Workflow Pattern

1. **Start**: Run `bd ready` to find actionable work
2. **Claim**: Use `bd update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: Use `bd close <id>`
5. **Sync**: Always run `bd sync` at session end

## Key Concepts

- **Dependencies**: Issues can block other issues. `bd ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers, not words)
- **Types**: task, bug, feature, epic, question, docs
- **Blocking**: `bd dep add <issue> <depends-on>` to add dependencies

## Danger Zone

| Never | Use Instead |
|-------|-------------|
| `npx beads ...` | `bd ...` |
| `bd close <id> --comment "..."` | `bd close <id> --reason "..."` |

The `bd` command is the correct CLI. `npx beads` does not exist.

## Best Practices

- Check `bd ready` at session start to find available work
- Update status as you work (in_progress → closed)
- Create new issues with `bd create` when you discover tasks
- Use descriptive titles and set appropriate priority/type
- Always `bd sync` before ending session

## Epic Structure (for complex work)

For changes with 3+ tasks, use epics:

1. Create epic: `bd create --title="Feature X" --type=epic`
2. Create task beads for each task
3. Set parent: `bd update <task-id> --parent=<epic-id>`
4. Mirror dependencies: `bd dep add <task-id> <blocking-task-id>`
5. Use `bd ready` to find unblocked work
6. Close tasks as completed, close epic when all done

**Benefits:**
- `bd ready` shows only unblocked tasks
- Granular progress tracking
- Clear handoff between sessions
