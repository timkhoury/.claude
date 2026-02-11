---
name: Status
description: Show unified workflow status - OpenSpec changes, tasks, and git state
category: Workflow
tags: [status, overview, orientation]
---

# Status Command

Display a unified view of current workflow state including OpenSpec changes, tasks, and git status. Use this for orientation at session start or to check progress mid-session.

## Usage

```
/status
```

No arguments needed.

## Information Gathered

Run these to collect status:

```
TaskList                        # All tasks with status and blockers
openspec list                   # Active OpenSpec changes (if using OpenSpec)
but status                      # Git branches and uncommitted changes
```

### Task Status Partitioning

Partition tasks from TaskList into:
- **In Progress**: status = "in_progress"
- **Ready**: status = "pending" AND blockedBy is empty
- **Blocked**: status = "pending" AND blockedBy is not empty
- **Completed**: status = "completed"

### Checking Remote Push Status

To accurately determine if branches are pushed, compare local branch commits with remote:

```bash
# Get remote branch refs
git ls-remote --heads origin | grep -E "(branch1|branch2)"

# Compare: if remote SHA matches local SHA, branch is pushed
```

**Logic:**
- If branch exists on remote AND remote SHA = local SHA → **Pushed**
- If branch exists on remote AND remote SHA != local SHA → **Unpushed commits**
- If branch does NOT exist on remote → **Not pushed**

Do NOT rely on `git branch -vv` tracking info in GitButler workspaces.

## Output Format

Present the information in this format:

```markdown
## Workflow Status

### Active OpenSpec Changes
| Change ID | Summary |
|-----------|---------|
| <id> | <first line of proposal.md> |

_None active_ (if empty or not using OpenSpec)

### Tasks
| # | Subject | Status | Blocked By |
|---|---------|--------|------------|
| 1 | <subject> | in_progress | - |
| 2 | <subject> | pending (ready) | - |
| 3 | <subject> | pending (blocked) | #1, #2 |
| 4 | <subject> | completed | - |

_No tasks_ (if empty)

### Git Status
**GitButler Branches:**
| Branch | Local SHA | Remote Status |
|--------|-----------|---------------|
| <branch> | <sha> | Pushed / Not pushed / Unpushed commits |

**Uncommitted changes:**
- <branch>: <n> files modified

_All clean_ (if nothing to report)

### Warnings
- <warning message if any inconsistencies detected>

_No warnings_ (if everything is consistent)
```

## Consistency Checks

After gathering status, check for these inconsistencies:

| Check | Warning Message |
|-------|-----------------|
| OpenSpec change exists but no task with matching metadata.specId | "OpenSpec `<id>` has no tracking tasks" |
| In-progress task matches archived OpenSpec | "Task #<id> tracks archived OpenSpec - complete it" |
| Uncommitted changes but no in-progress task | "Uncommitted changes but no task in progress" |
| Multiple OpenSpec changes active | "Multiple OpenSpec changes active - ensure they don't conflict" |
| Branch not pushed to remote | "Branch `<branch>` not pushed - run `but push <branch>` if work is complete" |

## Usage Tips

- Run at **session start** to orient yourself
- Run **mid-session** to check what's in flight
- Run **before `/wrap`** to preview what needs to be completed
