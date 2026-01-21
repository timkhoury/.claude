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

1. Create OpenSpec proposal first (`/openspec:proposal`)
2. Create tracking bead with title matching the change-id
3. **For 3+ tasks**: Use epic structure (see below)
4. **For 1-2 tasks**: Simple bead is sufficient

**Simple bead (1-2 tasks):**
```bash
bd create --title="<change-id>" --type=feature --priority=2
bd update <id> --status=in_progress
```

### Epic Structure for Complex Changes

For OpenSpec changes with 3+ tasks, create an epic with child task beads:

**Step 1: Create epic from tracking bead**
```bash
bd create --title="<change-id>" --type=epic --priority=2 \
  --description="OpenSpec: <brief description>"
```

**Step 2: Create task beads for each task in tasks.md**
```bash
bd create --title="<task title>" --type=task --priority=2 \
  --description="<task goal from tasks.md>"
```

**Step 3: Set parent-child relationships**
```bash
bd update <task-id> --parent=<epic-id>
```

**Step 4: Mirror dependencies from tasks.md**
```bash
bd dep add <dependent-task> <blocking-task>
```

**Benefits:**
- `bd ready` shows only unblocked tasks
- Granular progress visibility
- Clear handoff between sessions
- Epic auto-tracks completion percentage

**Example structure:**
```
Epic: add-user-notifications (abc)
├── Task 1: Create notification service (def) ← ready
├── Task 2: Add database schema (ghi) ← blocked by def
├── Task 3: Build UI components (jkl) ← blocked by def, ghi
├── [Standard] Unit & integration tests (mno) ← blocked by implementation tasks
├── [Standard] E2E tests (pqr) ← blocked by tests, if user-facing
├── [Standard] Documentation updates (stu) ← blocked by implementation tasks
└── [Standard] Manual QA verification (vwx) ← blocked by all, human-only
```

### Standard Epic Tasks

**Every epic MUST include these tasks.** Create them when setting up the epic structure.

| Task | Type | Blocked By | Closed By |
|------|------|------------|-----------|
| Unit & integration tests | `task` | All implementation tasks | Agent (after tests pass) |
| E2E tests | `task` | Unit tests (if user-facing) | Agent (after tests pass) |
| Documentation updates | `task` | Implementation tasks | Agent (if docs changed) |
| Manual QA verification | `task` | All other tasks | **Human only** |

**Creating standard tasks:**
```bash
# After creating implementation tasks, add standard tasks:
bd create --title="Unit & integration tests" --type=task --priority=2 \
  --description="Write tests for new functionality. Target: unit tests for logic, integration tests for DB/API."
bd update <test-id> --parent=<epic-id>
bd dep add <test-id> <last-implementation-task>

bd create --title="E2E tests" --type=task --priority=2 \
  --description="Write E2E tests for user-facing flows. Skip if no UI changes."
bd update <e2e-id> --parent=<epic-id>
bd dep add <e2e-id> <unit-test-id>

bd create --title="Documentation updates" --type=task --priority=2 \
  --description="Update docs if API, schema, or user-facing behavior changed."
bd update <docs-id> --parent=<epic-id>
bd dep add <docs-id> <last-implementation-task>

bd create --title="Manual QA verification" --type=task --priority=3 \
  --description="Human verification of functionality. DO NOT close automatically."
bd update <qa-id> --parent=<epic-id>
bd dep add <qa-id> <e2e-id>  # Blocked by everything else
```

**Rules for standard tasks:**
- **Tests**: Must pass `npm run test` and achieve reasonable coverage for new code
- **E2E**: Required if feature has user-facing UI; skip with `--reason="No UI changes"` if not
- **Docs**: Update relevant docs in `docs/` or inline comments; skip if truly no doc changes
- **Manual QA**: **NEVER** close automatically - only a human can verify and close this task

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
   [ ] Manual QA verification task closed BY HUMAN
   ```
   **DO NOT proceed until all boxes are checked.** The Manual QA task requires human sign-off.

2. **Archive OpenSpec first** (if applicable) - `/openspec:archive <change-id>`
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

## Quick Reference

### Starting Work

```bash
# Beads-only workflow
bd create --title="Fix login bug" --type=bug --priority=1
bd update <id> --status=in_progress
# ... work ...
bd close <id> --reason="Fixed in commit abc123"

# Beads + OpenSpec (simple, 1-2 tasks)
/openspec:proposal <description>
bd create --title="<change-id>" --type=feature --priority=2
bd update <id> --status=in_progress
/openspec:apply <change-id>

# Beads + OpenSpec (epic, 3+ tasks)
/openspec:proposal <description>
bd create --title="<change-id>" --type=epic --priority=2 --description="OpenSpec: ..."
# For each task in tasks.md:
bd create --title="<task title>" --type=task --priority=2
bd update <task-id> --parent=<epic-id>
bd dep add <task-id> <blocking-task-id>  # Mirror dependencies
# Start first unblocked task:
bd ready
bd update <task-id> --status=in_progress
/openspec:apply <change-id>
```

### Completing Work

```bash
# Beads-only: just close
bd close <id> --reason="Completed"

# Beads + OpenSpec (simple): archive first, then close
/openspec:archive <change-id>
bd close <id> --reason="Archived: <change-id>"

# Beads + OpenSpec (epic): tasks closed during work, then archive, then close epic
/openspec:archive <change-id>
bd close <epic-id> --reason="Archived: <change-id>"
```

## Workflow Commands

| Command | Purpose |
|---------|---------|
| `/work <task-id>` | Execute one specific task, then stop |
| `/work <epic-id>` | Work through all ready tasks in the epic sequentially |
| `/status` | Show unified view of OpenSpec, beads, and git state |
| `/wrap` | End-of-session workflow - archive, close, push, verify |

Use `/work <id>` to implement tasks, `/status` for orientation, and `/wrap` to complete a session.

## Working Through Tasks

When implementing an OpenSpec change with multiple tasks:
- Use `/work <epic-id>` to work through all ready tasks in the epic automatically
- Or use `/work <task-id>` to work on one specific task and stop
- Epic mode continues until all tasks complete or a blocker is hit
- This prevents conflicts when multiple Claude sessions work in parallel

## Context Management (Hybrid Orchestrator Pattern)

> **Use `/work <id>` to execute this pattern.** Pass a task ID (one task) or epic ID (all ready tasks in epic).

**This pattern processes tasks sequentially, one at a time.** Each subagent gets a fresh 200k token context, preventing context exhaustion in the main conversation.

### Architecture

```
Main Orchestrator (this conversation - stays lean)
  │
  ├─ User runs: /work <id>
  ├─ If epic: find next ready child task
  ├─ bd update <task-id> --status=in_progress → claim
  ├─ Delegate to subagent (fresh context)
  ├─ Receive summary result
  ├─ Commit via gitbutler
  ├─ bd close <task-id>
  ├─ If epic: loop back to find next ready child
  └─ Done when no more ready tasks
```

### Branch Management for Epics

**For epics, create a single branch at the start and use it for all tasks:**

```bash
# Before first task
but branch new <epic-name>           # Descriptive name, no prefixes like feat/, perf/
```

**Branch naming rules:**
- Use descriptive kebab-case: `server-action-optimizations`, `user-notifications`
- NO conventional prefixes: not `perf/...`, `feat/...`, `fix/...`
- Prefixes are for commit messages, not branch names

### Default Task Execution Pattern

**For the specified task, delegate to the task-implementer agent:**

```
Use the task-implementer agent to implement this task:

Target Branch: <branch-name>
Task ID: <bead-id>
Task: <title from bd show>
Description: <description from bd show>
```

The task-implementer agent has CLAUDE.md and all rules pre-loaded via file inclusion. No need to repeat project conventions in the prompt.

**CRITICAL: Pass the target branch to every task-implementer invocation.** This ensures all commits go to the same branch.

**After subagent completes:**
1. Tick the task in tasks.md (if applicable) - update checkboxes before committing
2. Verify commit landed on correct branch with `but status`
3. Close the bead: `bd close <id> --reason="<summary>"`
4. If epic mode: find next ready child and continue
5. If task mode: stop (user runs `/work <next-id>` to continue)

**CRITICAL: Commit after every task completion.** Never batch multiple tasks into a single commit. Each closed bead should have a corresponding commit. Include tasks.md updates in the same commit as the implementation.

### When to Use This Pattern

| Situation | Use Subagent Delegation |
|-----------|-------------------------|
| 3+ tasks to complete | Always |
| Context getting heavy (many file reads) | Yes |
| Independent tasks | Yes |
| Task requires deep code exploration | Yes |

| Situation | Work Directly (no subagent) |
|-----------|------------------------------|
| Single quick fix | Yes |
| Task needs context from previous task | Yes |
| Debugging with back-and-forth | Yes |

### Benefits

- **No context pollution**: Main conversation stays lean
- **Fresh perspective**: Each task starts with clean 200k context
- **No conflicts**: One task at a time prevents merge conflicts and maintains commit order
- **Resilient**: If session ends, `bd ready` picks up exactly where you left off

### Across-Session Handoff

When ending a session mid-workflow:
1. Commit all in-progress work
2. `bd sync` to push issue state
3. End session

When starting new session:
1. `bd ready` shows exactly what's next
2. Run `/work <epic-id>` to continue the epic, or `/work <task-id>` for a specific task
3. No context from previous session needed—beads tracks state

### Syncing Task Completion

When closing a bead task, also tick off the corresponding task in `tasks.md`:

```markdown
- [x] Task description  <!-- Tick when bead closed -->
```

**Exception - never tick tasks requiring manual testing:**
- Tasks with "manual test", "verify manually", "user confirms" language
- UI/UX tasks requiring human visual verification
- Integration tasks requiring real environment testing

These must remain unticked until a human confirms completion. This applies to both beads and OpenSpec task tracking.

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
| Create epic without standard tasks | Missing tests, docs, QA - incomplete delivery |
| Close Manual QA task automatically | Only humans can verify - this task is human-only |
| Close epic before Manual QA sign-off | Feature not verified by human, bugs slip through |
