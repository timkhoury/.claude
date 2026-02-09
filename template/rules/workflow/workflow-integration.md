# Unified Workflow: Beads + OpenSpec

This rule defines how beads (issue tracking) and OpenSpec (spec-driven development) work together.

## Starting Work

**After plan approval, always invoke `/execute-plan`.** This is mandatory - it sets up the correct workflow structure (epic, tasks, branch) regardless of complexity.

`/execute-plan` analyzes the plan and routes to:
- **OpenSpec** (`/opsx:ff`) for new features, breaking changes, cross-cutting work
- **Direct beads** (epic + tasks) for bug fixes, refactors, config changes

See the `execute-plan` skill for decision criteria and full setup workflow.

## During Implementation

```bash
bd ready                              # Find next unblocked task
bd update <task-id> --status=in_progress
# ... implement task ...
bd close <task-id> --reason="Implemented in <commit>"
bd ready                              # See what's unblocked next
```

The epic stays open until all tasks are closed and OpenSpec (if applicable) is archived.

## Completion Order

**Follow this order exactly:**

1. Verify all child tasks are closed
2. Archive OpenSpec (if applicable): `/opsx:archive <change-id>`
3. Close the epic: `bd close <epic-id> --reason="Archived: <change-id>"`
4. Run quality gates: `code-reviewer` agent, then `/pr-check`
5. Land the plane: push, sync, verify

See `completion-criteria.md` for quality bar at each level.

## Workflow Commands

| Command | Purpose |
|---------|---------|
| `/execute-plan` | Set up workflow after plan approval (mandatory) |
| `/work <task-id>` | Execute one specific task, then stop |
| `/work <epic-id>` | Work through all ready tasks in the epic sequentially |
| `/status` | Show unified view of OpenSpec, beads, and git state |
| `/wrap` | End-of-session workflow - archive, close, push, verify |

## Subagent Strategy

Use parallel subagents for independent exploration; sequential subagents for implementation.

| Situation | Strategy |
|-----------|----------|
| Exploring multiple files/areas | 2-4 parallel Explore agents |
| Implementing tasks from an epic | Sequential task-implementer (one at a time) |
| Research + implementation | Research in parallel, then implement sequentially |
| Broad codebase questions | 2-3 parallel agents covering different areas |

**Sweet spot is 2-4 parallel agents.** Beyond that, consolidation overhead outweighs exploration gains. Each subagent gets fresh context, so use them to protect the main conversation from context exhaustion - not to maximize parallelism.

**Avoid:** 5+ parallel agents for routine work, parallel implementation agents (they conflict on files), spawning agents for tasks you could do directly in 1-2 tool calls.

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Skip `/execute-plan` after plan approval | No epic, no task tracking, no structure |
| Close epic before archiving OpenSpec | Loses traceability, spec not updated |
| Add dependency between child and its parent | Circular blocking, child never becomes ready |
| Skip `--parent` on task beads | Tasks not grouped under epic |
| Close epic before all tasks closed | Premature completion, tasks orphaned |
| Work 3+ tasks in main context | Context exhaustion - use `/work` with subagents |
| Batch multiple tasks into one commit | Loses granularity, harder to review/revert |
