# Task Workflow

Use built-in Task tools for work tracking. Tasks are session-scoped and flat - no epics or hierarchies.

## Workflow

1. `TaskList` to find ready work (pending + no blockers)
2. `TaskUpdate` to claim (in_progress) before starting
3. Implement, then `TaskUpdate` to complete
4. `TaskList` again for newly unblocked work

## Guidelines

- **Flat lists** - the session's task list IS the unit of work; dependencies provide ordering
- **One commit per task** - don't batch multiple tasks into one commit
- **Proactive creation** - when you discover work that doesn't block the current task, create a task for it
- **OpenSpec linking** - use `metadata: { specId: "change-id" }` to link tasks to specs

## Standard Tasks

Every implementation session should include:

| Task | Blocked By |
|------|------------|
| Unit & integration tests | All implementation tasks |
| E2E tests (if user-facing) | Unit tests |
| Documentation updates | Implementation tasks |

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Skip claiming (in_progress) before working | Unclear what's active |
| Mark task completed without doing the work | False progress |
| Forget dependencies for ordered work | Tasks worked out of order |
