---
name: work
description: >
  Execute beads tasks via subagent delegation. Use for "work on <id>",
  epic execution, or bead ID references. Requires task/epic ID.
---

# Work Skill

Execute beads tasks with subagent delegation for context efficiency.

## Critical Rules

1. **Always require an ID** - prevents race conditions between parallel sessions
2. **Claim immediately** - `bd update <id> --status=in_progress` before any work
3. **One commit per task** - never batch multiple tasks into one commit
4. **Pass target branch** - every task-implementer invocation needs the branch name

## Usage

```
/work <task-id>    # Work on one specific task
/work <epic-id>    # Work through all ready tasks in the epic
```

Find available work: `bd ready`

## Architecture

```
Main Orchestrator (stays lean)
  │
  ├─ /work <id>
  ├─ If epic: find next ready child
  ├─ bd update <task-id> --status=in_progress
  ├─ Delegate to task-implementer (fresh context)
  ├─ Commit via gitbutler
  ├─ bd close <task-id>
  ├─ If epic: loop to next ready child
  └─ Done when no more ready tasks
```

## Branch Management

**Receiving branch from execute-plan:**

The orchestrator may specify a branch in the invocation:
```
/work <epic-id>
Branch: <branch-name>
```

**If no branch specified, create one:**
```bash
but branch new <epic-name>    # kebab-case, no feat/fix/ prefixes
```

**One branch for entire epic** - all tasks commit to the same branch.

## Workflow

### Step 1: Validate ID

```bash
bd show $ARGUMENTS
```

- **Task**: Proceed to Step 2
- **Epic**: Find first ready child via `bd list --parent=$ARGUMENTS --status=open`

### Step 2: Claim Task

```bash
bd update <task-id> --status=in_progress
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
Task ID: <bead-id>
Task: <title>
Description: <description>
```

**After completion:**
- Tick tasks.md checkbox (if applicable)
- Verify commit on correct branch: `but status`
- Close bead: `bd close <id> --reason="<summary>"`

### Step 5: Next Task (Epic Mode)

- Check for more ready children
- If ready: go to Step 2
- If none: proceed to Step 6

### Step 6: Epic Complete

When all tasks are done (no more ready children):

1. Run `code-reviewer` agent
2. If passes, run `/pr-check`
3. Ask user about PR creation
4. Invoke `/wrap` to complete the session

## When NOT to Delegate

| Situation | Action |
|-----------|--------|
| Single quick fix | Work directly |
| Needs previous task context | Work directly |
| User wants to see the work | Work directly |

## Session Handoff

**Ending mid-workflow:**
1. Commit in-progress work
2. `bd sync`

**Starting new session:**
1. `bd ready` shows next task
2. `/work <epic-id>` to continue

## Task Completion Sync

Tick tasks.md when closing beads:

```markdown
- [x] Task description
```

**Never tick tasks requiring manual testing.**
