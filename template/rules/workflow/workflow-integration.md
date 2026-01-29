# Unified Workflow: Beads + OpenSpec

This rule defines how beads (issue tracking) and OpenSpec (spec-driven development) work together.

## Decision Tree: When to Use What

```
New work item?
├─ Small task, bug fix, or isolated change
│  └─ Beads only → Create bead, work, close bead
│
├─ Complex feature, architectural change, or breaking change
│  └─ Beads + OpenSpec → Create both, keep in sync, archive then close
│
└─ Unclear scope?
   └─ Start with bead → Upgrade to OpenSpec if complexity emerges
```

### Use Beads Only When:
- Bug fixes (restore intended behavior)
- Feature changes that don't alter functional requirements
- Configuration or dependency updates
- Documentation updates
- Refactoring without behavior change

### Use Beads + OpenSpec When:
- New features or capabilities
- Breaking changes (API, schema, behavior)
- Cross-cutting changes (multiple systems/files)
- Architectural changes
- Anything benefiting from upfront design

## Keeping Beads and OpenSpec in Sync

When using both systems:

### At Creation Time

1. Create OpenSpec change first (`/opsx:new` or `/opsx:ff`)
2. Create tracking bead with title matching the change-id
3. **For 3+ tasks**: Use epic structure (see below)
4. **For 1-2 tasks**: Simple bead is sufficient

**Simple bead (1-2 tasks):**
```bash
bd create --title="<change-id>" --type=feature --priority=2
bd update <id> --status=in_progress
```

### Epic Structure for Complex Changes

For OpenSpec changes with 3+ tasks, create an epic with child task beads. See `beads-workflow.md` for epic creation steps.

### Standard Epic Tasks

**Every epic MUST include these tasks.** Create them when setting up the epic structure.

| Task | Type | Blocked By | Closed By |
|------|------|------------|-----------|
| Unit & integration tests | `task` | All implementation tasks | Agent (after tests pass) |
| E2E tests | `task` | Unit tests (if user-facing) | Agent (after tests pass) |
| Documentation updates | `task` | Implementation tasks | Agent (if docs changed) |

**Rules for standard tasks:**
- **Tests**: Must pass `npm run test` and achieve reasonable coverage for new code
- **E2E**: Required if feature has user-facing UI; skip with `--reason="No UI changes"` if not
- **Docs**: Update relevant docs in `docs/` or inline comments; skip if truly no doc changes

### During Implementation

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

### At Completion Time

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
   - If review passes, run `/pr-check` skill
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
| `/work <task-id>` | Execute one specific task, then stop |
| `/work <epic-id>` | Work through all ready tasks in the epic sequentially |
| `/status` | Show unified view of OpenSpec, beads, and git state |
| `/wrap` | End-of-session workflow - archive, close, push, verify |

Use `/work <id>` to implement tasks, `/status` for orientation, and `/wrap` to complete a session.

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
