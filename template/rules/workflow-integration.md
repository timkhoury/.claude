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

### At Creation Time

1. Create OpenSpec proposal first (`/openspec:proposal`)
2. Create tracking bead with title matching the change-id
3. **For 3+ tasks**: Use epic structure
4. **For 1-2 tasks**: Simple bead is sufficient

### During Implementation

| OpenSpec State | Beads State |
|----------------|-------------|
| Proposal created | Bead created (open) |
| Implementation started | Bead in_progress |
| Tasks being completed | Keep bead in_progress |
| All tasks done | Keep bead in_progress (not closed yet) |

### At Completion Time

**CRITICAL: Follow this order exactly:**

1. **Archive OpenSpec first** - `/openspec:archive <change-id>`
2. **Then close the bead** - `bd close <bead-id> --reason="Archived: <change-id>"`
3. **Run quality gates** - code-reviewer then pr-check
4. **Then land the plane** - Push, sync, verify

## Workflow Commands

| Command | Purpose |
|---------|---------|
| `/work <task-id>` | Execute one specific task, then stop |
| `/work <epic-id>` | Work through all ready tasks in the epic sequentially |
| `/status` | Show unified view of OpenSpec, beads, and git state |
| `/wrap` | End-of-session workflow - archive, close, push, verify |

## Context Management (Hybrid Orchestrator Pattern)

> **Use `/work <id>` to execute this pattern.**

For complex work with 3+ tasks, delegate to subagents:

```
Main Orchestrator (this conversation - stays lean)
  │
  ├─ User runs: /work <id>
  ├─ If epic: find next ready child task
  ├─ bd update <task-id> --status=in_progress → claim
  ├─ Delegate to task-implementer subagent (fresh context)
  ├─ Receive summary result
  ├─ Commit via gitbutler
  ├─ bd close <task-id>
  ├─ If epic: loop back to find next ready child
  └─ Done when no more ready tasks
```

**Benefits:**
- No context pollution: Main conversation stays lean
- Fresh perspective: Each task starts with clean context
- No conflicts: One task at a time prevents merge conflicts
- Resilient: If session ends, `bd ready` picks up exactly where you left off

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Close bead before archiving OpenSpec | Loses traceability, spec may not be updated |
| Archive OpenSpec without closing bead | Orphaned issue, unclear completion status |
| Create OpenSpec without tracking bead | No visibility into work in progress |
| Forget to sync at session end | Changes stranded locally |
| Work 3+ tasks directly in main context | Context exhaustion, session ends prematurely |
| Skip commit after task completion | Work lost, can't attribute commits to tasks |
