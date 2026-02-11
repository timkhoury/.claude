---
name: work
description: >
  Execute tasks via subagent delegation. Use for "work on tasks",
  task execution, or continuing implementation after /execute-plan.
---

# Work Skill

Execute tasks with subagent delegation for context efficiency.

## Critical Rules

1. **Claim immediately** - `TaskUpdate({ status: "in_progress" })` before any work
2. **One commit per task** - never batch multiple tasks into one commit
3. **Pass target branch** - every task-implementer invocation needs the branch name

## Usage

```
/work              # Work through all ready tasks
/work
Branch: <name>     # Work on branch (from execute-plan)
```

## Architecture

```
Main Orchestrator (stays lean)
  |
  +- /work
  +- TaskList -> find next ready (pending + no blockers)
  +- TaskUpdate({ status: "in_progress" })
  +- Delegate to task-implementer (fresh context)
  +- Commit via gitbutler
  +- TaskUpdate({ status: "completed" })
  +- Loop to next ready task
  +- Done when no more ready tasks
```

## Branch Management

**Receiving branch from execute-plan:**

The orchestrator may specify a branch in the invocation:
```
/work
Branch: <branch-name>
```

**If no branch specified, create one:**
```bash
but branch new <task-name>    # kebab-case, no feat/fix/ prefixes
```

**One branch for all tasks** - all tasks commit to the same branch.

## Workflow

### Step 1: Find Next Task

```
TaskList -> find tasks where status="pending" AND blockedBy is empty
```

- **Found**: Proceed to Step 2
- **None ready but blocked tasks exist**: Report what's blocking and stop
- **All completed**: Proceed to Step 5

### Step 2: Claim Task

```
TaskUpdate({ taskId: "<id>", status: "in_progress" })
```

### Step 3: Assess Delegation

| Complexity | Action |
|------------|--------|
| Simple (few files) | Work directly |
| Complex (multiple files) | Delegate to task-implementer |

### Step 4: Execute

**Delegating (recommended):**

```
Use the task-implementer agent:

Target Branch: <branch-name>   # REQUIRED - from execute-plan or created in Branch Management
Task: <subject>
Description: <description>
```

**After completion:**
- Tick tasks.md checkbox (if OpenSpec with metadata.specId)
- Verify commit on correct branch: `but status`
- Complete task: `TaskUpdate({ taskId: "<id>", status: "completed" })`

### Step 5: Next Task

- Check TaskList for more ready tasks
- If ready: go to Step 2
- If none: proceed to Step 6

### Step 6: All Done

When all tasks are completed:

1. Run `code-reviewer` agent
2. If passes, run `/pr-check`
3. Invoke `/wrap` to complete the session

## When NOT to Delegate

| Situation | Action |
|-----------|--------|
| Single quick fix | Work directly |
| Needs previous task context | Work directly |
| User wants to see the work | Work directly |

## Task Completion Sync

Tick tasks.md when completing OpenSpec-linked tasks:

```markdown
- [x] Task description
```

**Never tick tasks requiring manual testing.**
