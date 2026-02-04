# Unified Workflow: Beads + OpenSpec

This rule defines how beads (issue tracking) and OpenSpec (spec-driven development) work together.

## Starting Work

Use `/execute-plan` after plan approval. The skill analyzes complexity and routes to:
- **OpenSpec** (`/opsx:ff`) for new features, breaking changes, cross-cutting work
- **Direct beads** (epic + tasks) for bug fixes, refactors, config changes

See the `execute-plan` skill for decision criteria and setup workflow.

## During Implementation

**Simple bead workflow:**

| OpenSpec State | Beads State |
|----------------|-------------|
| Proposal created | Bead created (open) |
| Implementation started | Bead in_progress |
| Tasks being completed | Keep bead in_progress |
| All tasks done | Keep bead in_progress (not closed yet) |

**Epic workflow:**

| OpenSpec State | Epic State | Task States |
|----------------|------------|-------------|
| Proposal created | Epic open | All tasks open |
| Starting task N | Epic open | Task N in_progress |
| Task N complete | Epic open | Task N closed, next task in_progress |
| All tasks done | Epic open | All tasks closed |
| After archive | Epic closed | All tasks closed |

**Working with tasks:**
```bash
bd ready                              # Find unblocked work
bd update <task-id> --status=in_progress
# ... implement task ...
bd close <task-id> --reason="Implemented in <commit>"
bd ready                              # See what's unblocked next
```

## At Completion Time

**CRITICAL: Follow this order exactly:**

1. **Verify Epic Completion Checklist** (for epics only):
   ```
   [ ] All implementation tasks closed
   [ ] Unit & integration tests task closed (tests passing)
   [ ] E2E tests task closed (or skipped with reason)
   [ ] Documentation updates task closed (or skipped with reason)
   ```

2. **Archive OpenSpec first** (if applicable) - `/opsx:archive <change-id>`
3. **Then close the bead(s)**:
   - Simple bead: `bd close <bead-id> --reason="Archived: <change-id>"`
   - Epic: `bd close <epic-id> --reason="Archived: <change-id>"` (closes epic; tasks should already be closed)
4. **Run quality gates**:
   - Run `code-reviewer` agent to review all changes
   - After implementing fixes from review, suggest next step:
     - **Large features**: Do 3 review/fix cycles before `/pr-check`
     - **Small changes**: Run `/pr-check` after fixes
   - If review passes with no issues, run `/pr-check` skill
   - Prompt user if they want to create a PR (don't auto-create)
5. **Then land the plane** - Push, sync, verify

**Why this order matters:**
- OpenSpec archive updates the specs (source of truth)
- Closing the bead before archiving loses traceability
- Landing the plane pushes everything together

**Epic completion note:** All child tasks should be closed during implementation. The epic stays open until the OpenSpec is archived, then close the epic as the final step.

## Workflow Commands

| Command | Purpose |
|---------|---------|
| `/execute-plan` | Set up workflow after plan approval |
| `/work <task-id>` | Execute one specific task, then stop |
| `/work <epic-id>` | Work through all ready tasks in the epic sequentially |
| `/status` | Show unified view of OpenSpec, beads, and git state |
| `/wrap` | End-of-session workflow - archive, close, push, verify |

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Close bead/epic before archiving OpenSpec | Loses traceability, spec may not be updated |
| Archive OpenSpec without closing bead/epic | Orphaned issue, unclear completion status |
| Create OpenSpec without tracking bead | No visibility into work in progress |
| Forget to sync at session end | Changes stranded locally |
| Skip setting --parent on task beads | Tasks not grouped under epic, no completion tracking |
| Skip mirroring dependencies | `bd ready` shows blocked tasks as ready |
| Close epic before all tasks closed | Premature completion, tasks orphaned |
| Work 3+ tasks directly in main context | Context exhaustion, session ends prematurely |
| Skip subagent delegation for complex tasks | Main context bloated, loses efficiency |
| Skip commit after task completion | Work lost, can't attribute commits to tasks |
| Batch multiple tasks into one commit | Loses granularity, harder to review/revert |
| Create epic without standard tasks | Missing tests, docs - incomplete delivery |
