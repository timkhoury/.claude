---
name: execute-plan
description: >
  Execute an approved plan using the appropriate workflow. Analyzes plan
  complexity and routes to OpenSpec (complex features) or direct beads
  (simpler work). Auto-invoked after ExitPlanMode or use /execute-plan.
---

# Execute Plan

Orchestrates plan implementation via OpenSpec or direct beads workflow.

## Quick Reference

| Plan Type | Workflow |
|-----------|----------|
| New feature, breaking change, cross-cutting | OpenSpec → tracking bead |
| Bug fix, refactor, config, single-component | Direct beads epic |

## Step 1: Find the Plan File

Check for the most recently modified plan in the plans directory:

```bash
ls -t plans/*.md | head -1
```

Read the plan file and extract:
- **Title**: From the `# Plan:` header
- **Summary**: From the `## Summary` section
- **Steps**: From numbered lists or `## Implementation` sections

## Step 2: Analyze Complexity

Look for these signals in the plan content:

### OpenSpec Signals (use `/opsx:ff`)

| Signal | Examples |
|--------|----------|
| New feature/capability | "Add new...", "Implement...", "Create feature..." |
| Breaking change | "Change API...", "Migrate schema...", "Update contract..." |
| Cross-cutting | Multiple services, systems, or major components affected |
| Schema migration | Database changes, new tables, column modifications |
| Architectural change | "Refactor architecture...", "Introduce pattern..." |

### Direct Beads Signals (use epic + tasks)

| Signal | Examples |
|--------|----------|
| Bug fix | "Fix...", "Resolve...", "Correct..." |
| Refactor | "Refactor...", "Cleanup...", "Simplify..." |
| Config/dependency | "Update deps...", "Configure...", "Add package..." |
| Single component | Changes isolated to one file or small area |
| Documentation | "Update docs...", "Add README..." |

**When unclear:** Default to direct beads. Can upgrade to OpenSpec if complexity emerges.

## Step 3: Route to Workflow

### OpenSpec Path (Complex Features)

1. **Create OpenSpec change:**
   ```
   /opsx:ff <summary from plan>
   ```

2. **Create tracking bead** (after change-id is generated):
   ```bash
   bd create --title="<change-id>" --type=feature --priority=2
   bd update <bead-id> --status=in_progress
   ```

3. **Guide user:**
   - If OpenSpec generated tasks, use `/opsx:apply <change-id>` or `/work <bead-id>`
   - The OpenSpec tasks.md provides the task breakdown

### Direct Beads Path (Simpler Work)

1. **Create epic from plan title:**
   ```bash
   bd create --title="<plan-title>" --type=epic --priority=2
   ```

2. **Create task beads from plan steps:**
   For each implementation step:
   ```bash
   bd create --title="<step title>" --type=task --priority=2 \
     --description="<step details>"
   bd update <task-id> --parent=<epic-id>
   ```

3. **Set dependencies** (if steps depend on each other):
   ```bash
   bd dep add <later-task-id> <earlier-task-id>
   ```

4. **Add standard tasks:**
   ```bash
   bd create --title="Unit & integration tests" --type=task --priority=2
   bd update <test-task-id> --parent=<epic-id>
   # Block tests on all implementation tasks
   bd dep add <test-task-id> <impl-task-1-id>
   bd dep add <test-task-id> <impl-task-2-id>
   ```

5. **Guide user:**
   ```
   /work <epic-id>
   ```

## Standard Epic Tasks

**Every epic MUST include these tasks** (created after implementation tasks):

| Task | Type | Blocked By |
|------|------|------------|
| Unit & integration tests | `task` | All implementation tasks |
| E2E tests | `task` | Unit tests (if user-facing) |
| Documentation updates | `task` | Implementation tasks |

**Rules:**
- **Tests**: Must pass `npm run test` and achieve reasonable coverage
- **E2E**: Required if feature has user-facing UI; skip if no UI changes
- **Docs**: Update relevant docs in `docs/`; skip if no doc changes needed

## Why This Pattern

- **Context preservation**: Each task gets fresh subagent context
- **Crash recovery**: `bd ready` shows exactly where to resume
- **Parallel safety**: Multiple sessions can't conflict on claimed tasks
- **Commit granularity**: One commit per task, clear attribution

## After Setup

Once beads are created, the `/work` skill handles execution:
- Finds next ready child task
- Claims it (marking in_progress)
- Delegates to task-implementer
- Commits via gitbutler
- Closes the task
- Loops to next ready task
