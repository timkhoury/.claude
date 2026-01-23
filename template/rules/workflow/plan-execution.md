# Plan Execution

When implementing an approved plan, use the hybrid orchestrator pattern with beads for tracking.

## Workflow

1. **Create epic**: `bd create --title="<plan-name>" --type=epic --priority=2`
2. **Create task beads**: One for each implementation step
3. **Set dependencies**: Mirror the plan's task dependencies with `bd dep add`
4. **Execute**: `/work <epic-id>` to work through tasks sequentially

## Why This Pattern

- **Context preservation**: Each task gets fresh subagent context
- **Crash recovery**: `bd ready` shows exactly where to resume
- **Parallel safety**: Multiple sessions can't conflict on claimed tasks
- **Commit granularity**: One commit per task, clear attribution

## Task Creation

For each step in the plan:

```bash
bd create --title="<step title>" --type=task --priority=2 \
  --description="<step details from plan>"
bd update <task-id> --parent=<epic-id>
bd dep add <task-id> <blocking-task-id>  # If dependencies exist
```

## Execution

```bash
/work <epic-id>  # Executes ready tasks until epic complete or blocked
```

The `/work` command handles:
- Finding the next ready child task
- Claiming it (marking in_progress)
- Delegating to task-implementer
- Closing the task after completion
- Continuing to next ready task
