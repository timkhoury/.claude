# Task Workflow

This project uses built-in Task tools (`TaskCreate`, `TaskGet`, `TaskUpdate`, `TaskList`) for work tracking. Tasks are session-scoped and flat - no epics or parent-child hierarchies needed.

## Essential Tools

| Tool | Purpose |
|------|---------|
| `TaskCreate` | Create a new task (pending by default) |
| `TaskList` | List all tasks with status and blockers |
| `TaskGet` | Get full details of a specific task |
| `TaskUpdate` | Update status, set dependencies, modify fields |

## Finding Ready Work

"Ready" = pending + no blockers:

```
TaskList → filter where status="pending" AND blockedBy is empty
```

No separate "ready" command needed - just scan the task list.

## Task Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `subject` | Brief imperative title | "Create user model" |
| `description` | Detailed requirements | "Add User table with email, name fields..." |
| `activeForm` | Present continuous (shown in spinner) | "Creating user model" |
| `metadata` | Arbitrary key-value pairs | `{ specId: "add-notifications" }` |
| `status` | `pending` → `in_progress` → `completed` | |

## Workflow Pattern

1. **Start**: `TaskList` to find tasks where status=pending and blockedBy is empty
2. **Claim**: `TaskUpdate({ taskId, status: "in_progress" })`
3. **Work**: Implement the task
4. **Complete**: `TaskUpdate({ taskId, status: "completed" })`
5. **Next**: `TaskList` again to find newly unblocked work

## Dependencies

Set ordering between tasks with `addBlockedBy`:

```
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })
```

Task 3 won't appear as "ready" until tasks 1 and 2 are completed.

## Creating Tasks with Dependencies

```
TaskCreate({ subject: "Create migration", description: "...", activeForm: "Creating migration" })
TaskCreate({ subject: "Run migration", description: "...", activeForm: "Running migration" })
TaskCreate({ subject: "Write tests", description: "...", activeForm: "Writing tests" })

TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })   # Run depends on Create
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })  # Tests depend on both
```

## Flat Task Lists (No Epics)

The session's task list IS the unit of work. No wrapping epic needed.

```
Task 1: Create model (in_progress)
Task 2: Add API endpoint (blocked by 1)
Task 3: Build UI (blocked by 2)
Task 4: Write tests (blocked by 1, 2, 3)
```

Same dependency ordering as hierarchical systems. Session context provides the grouping.

## OpenSpec Integration

Link tasks to OpenSpec changes via metadata:

```
TaskCreate({
  subject: "Implement auth flow",
  metadata: { specId: "add-user-auth" }
})
```

## Standard Tasks

Every implementation session should include:

| Task | Blocked By |
|------|------------|
| Unit & integration tests | All implementation tasks |
| E2E tests (if user-facing) | Unit tests |
| Documentation updates | Implementation tasks |

## Proactive Task Creation

When you discover work that doesn't block the current task, create a task for it:

```
TaskCreate({
  subject: "Fix null check in auth middleware",
  description: "Discovered while testing sign-out flow"
})
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Skip claiming (in_progress) before working | Unclear what's active |
| Mark task completed without doing the work | False progress |
| Batch multiple tasks into one commit | Loses granularity |
| Forget dependencies for ordered work | Tasks worked out of order |
