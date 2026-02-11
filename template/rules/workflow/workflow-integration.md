# Unified Workflow: Tasks + OpenSpec

This rule defines how Task tools (work tracking) and OpenSpec (spec-driven development) work together.

## Starting Work

**After plan approval, always invoke `/execute-plan`.** This is mandatory - it sets up the correct workflow structure (tasks, dependencies, branch) regardless of complexity.

`/execute-plan` analyzes the plan and routes to:
- **OpenSpec** (`/opsx:ff`) for new features, breaking changes, cross-cutting work
- **Direct tasks** for bug fixes, refactors, config changes

See the `execute-plan` skill for decision criteria and full setup workflow.

## During Implementation

```
TaskList                                          # Find next unblocked task (pending + no blockers)
TaskUpdate({ taskId: "<id>", status: "in_progress" })
# ... implement task ...
TaskUpdate({ taskId: "<id>", status: "completed" })
TaskList                                          # See what's unblocked next
```

Work continues until all tasks are completed and OpenSpec (if applicable) is archived.

## Completion Order

**Follow this order exactly:**

1. Verify all tasks are completed (`TaskList` - check for remaining pending/in_progress)
2. Verify OpenSpec (if applicable): `/opsx:verify <change-id>`
3. Archive OpenSpec (if applicable): `/opsx:archive <change-id>`
4. Run quality gates: `code-reviewer` agent, then `/pr-check`
5. Land the plane: push, verify

See `completion-criteria.md` for quality bar at each level.

## Workflow Commands

| Command | Purpose |
|---------|---------|
| `/execute-plan` | Set up workflow after plan approval (mandatory) |
| `/work` | Work through all ready tasks sequentially |
| `/wrap` | End-of-session workflow - archive, complete tasks, push, verify |

## Subagent Strategy

Use parallel subagents for independent exploration; sequential subagents for implementation.

| Situation | Strategy |
|-----------|----------|
| Exploring multiple files/areas | 2-4 parallel Explore agents |
| Implementing tasks | Sequential task-implementer (one at a time) |
| Research + implementation | Research in parallel, then implement sequentially |
| Broad codebase questions | 2-3 parallel agents covering different areas |

**Sweet spot is 2-4 parallel agents.** Beyond that, consolidation overhead outweighs exploration gains. Each subagent gets fresh context, so use them to protect the main conversation from context exhaustion - not to maximize parallelism.

**Avoid:** 5+ parallel agents for routine work, parallel implementation agents (they conflict on files), spawning agents for tasks you could do directly in 1-2 tool calls.

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Skip `/execute-plan` after plan approval | No task tracking, no structure |
| Archive OpenSpec before all tasks completed | Spec archived with incomplete work |
| Work 3+ tasks in main context | Context exhaustion - use `/work` with subagents |
| Batch multiple tasks into one commit | Loses granularity, harder to review/revert |
