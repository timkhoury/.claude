---
name: Work
description: Execute beads tasks. Task ID = one task. Epic ID = work through all ready tasks in epic.
category: Workflow
tags: [work, tasks, beads, delegation, implementation]
argument-hint: <task-id or epic-id>
---

# Work Command

Execute beads tasks using the hybrid orchestrator pattern. Requires an ID to prevent race conditions between parallel Claude instances.

## Usage

```
/work <task-id>    # Work on one specific task
/work <epic-id>    # Work through all ready tasks in the epic
```

**The ID is required.** This ensures multiple sessions don't accidentally work on the same task.

To find available work:
```bash
bd ready
```

## Behavior

| ID Type | Behavior |
|---------|----------|
| Task ID | Execute that one task, then stop |
| Epic ID | Execute ready tasks sequentially until epic is complete or blocked |

## Workflow

### Step 1: Validate and Resolve ID

Check if the specified ID is a task or epic:

```bash
bd show $ARGUMENTS
```

**If it's a task:** Proceed to Step 2 with this task.

**If it's an epic:** Find the first ready child task:
1. List children: `bd list --parent=$ARGUMENTS --status=open`
2. Check which are unblocked (no pending dependencies)
3. If no ready children, inform user and stop
4. Proceed to Step 2 with the first ready child

### Step 2: Claim the Task

**Mark in_progress IMMEDIATELY to prevent race conditions:**

```bash
bd update <task-id> --status=in_progress
```

### Step 3: Assess Delegation Need

| Task Complexity | Action |
|-----------------|--------|
| Simple (< 5 minutes, few files) | Work directly |
| Complex (multiple files, significant changes) | Delegate to task-implementer |

### Step 4: Execute the Task

**If delegating (recommended for most tasks):**

1. Delegate to task-implementer agent:
   ```
   Task ID: <bead-id>
   Task: <title from bd show>
   Description: <description from bd show>
   ```

2. After subagent completes, close the task:
   ```bash
   bd close <task-id> --reason="<brief summary>"
   ```

3. If task has associated tasks.md, tick the checkbox

**If working directly:**

1. Implement the task
2. Commit changes via gitbutler
3. Close the task:
   ```bash
   bd close <task-id> --reason="<brief summary>"
   ```

### Step 5: Next Task (Epic Mode Only)

**If the original ID was an epic:**
1. Check for more ready children: `bd list --parent=<epic-id> --status=open`
2. If another child is ready (unblocked), go back to Step 2
3. If no ready children remain, stop and report status

**If the original ID was a task:** Stop. Work complete.

### Step 6: Session End

After all work complete, run quality gates:

1. **Code review** - Run `code-reviewer` agent to review changes
2. **Quality gates** - If review passes, run pr-check
3. **Prompt user** - Ask if they want to create a PR (don't auto-create)

```bash
bd ready   # See what's available next
bd sync    # Sync if ending session
```

## Why Require ID

**Prevents conflicts:** Multiple Claude instances can run `/work` simultaneously without stepping on each other.

**Explicit intent:** User decides which task/epic to work on, not the AI.

**Sequential execution:** Tasks are processed one at a time, maintaining commit order and avoiding merge conflicts.

## When NOT to Delegate

| Situation | Action |
|-----------|--------|
| Single quick fix (< 5 minutes) | Work directly |
| Task needs context from just-completed task | Work directly or pass context |
| User explicitly asks to see the work | Work directly |

## Examples

### Working on a specific task

```bash
$ bd ready
1. [task] project-abc: Implement auth validation
2. [task] project-def: Add unit tests for auth

$ /work project-abc
# Works on abc, then stops
```

### Working on an epic (continues until done/blocked)

```bash
$ bd ready
1. [epic] project-xyz: Auth feature
2. [task] project-abc: Implement auth (child of xyz)
3. [task] project-def: Add tests (child of xyz, blocked by abc)

$ /work project-xyz
# 1. Selects abc (first ready child)
# 2. Completes abc → def becomes unblocked
# 3. Selects def (next ready child)
# 4. Completes def → no more children
# 5. Epic complete, stops
```
