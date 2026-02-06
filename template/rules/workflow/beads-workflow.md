# Beads Workflow

This project uses [beads](https://github.com/steveyegge/beads) for issue tracking. Issues are stored in `.beads/` and tracked in git.

## Essential Commands

```bash
# View issues (TUI - avoid in automated sessions)
bv

# CLI commands (use these for agents)
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies (alias: bd view)
bd children <id>      # Show child issues of an epic/parent

# Create & update
bd create --title="..." --type=task --priority=2
bd create --title="..." -m "description"  # -m is alias for --description
bd update <id> --status=in_progress
bd update <id> --append-notes="Additional context"  # Append to existing notes
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
| `npx beads ready` | `bd ready` |
| `npx beads list` | `bd list` |
| `bd close <id> --comment "..."` | `bd close <id> --reason "..."` |

The `bd` command is the correct CLI. `npx beads` does not exist and will fail.

## Best Practices

- Check `bd ready` at session start to find available work
- Update status as you work (in_progress → closed)
- Create new issues with `bd create` when you discover tasks
- Use descriptive titles and set appropriate priority/type
- Always `bd sync` before ending session

## Proactive Issue Creation

**Always create beads issues for discovered work.** When you encounter:

- Bugs that don't block current work
- Technical debt or code smells
- Missing tests or test failures unrelated to current task
- Documentation gaps
- Performance issues
- Accessibility problems

Create a bead immediately with `bd create`. This ensures nothing gets lost and provides visibility into discovered work.

```bash
# Example: Found a bug while working on something else
bd create --title="Fix null check in auth middleware" --type=bug --priority=2 \
  --description="Discovered while testing sign-out flow. See auth/sign-out.spec.ts"
```

**Why this matters:**
- Work discovered but not tracked is work forgotten
- Beads provide context recovery after session compaction
- Future sessions can pick up where you left off
- Users have visibility into all known issues

## Parent vs Dependency

These are different relationships - never confuse them:

| Relationship | Command | Meaning |
|-------------|---------|---------|
| **Parent** (structural) | `bd update <task> --parent=<epic>` | Task belongs to epic |
| **Dependency** (ordering) | `bd dep add <blocked> <blocker>` | Task can't start until blocker completes |

**Never add a dependency between a child and its own parent.** Children are linked to epics via `--parent`. Dependencies are for ordering between sibling tasks (e.g., "run migration" depends on "create migration").

## Epic Setup

Use `/execute-plan` to create epics with child tasks. It handles:
- Routing to OpenSpec or direct beads based on complexity
- Creating epic + child tasks with `--parent`
- Setting dependencies between sibling tasks
- Adding standard tasks (tests, docs)
