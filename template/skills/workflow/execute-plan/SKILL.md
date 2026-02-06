---
name: execute-plan
description: >
  Execute an approved plan using the appropriate workflow. Analyzes plan
  complexity and routes to OpenSpec (complex features) or direct beads
  (simpler work). MUST be invoked after plan mode approval, before writing
  any code. Triggers: plan approved, "go ahead", "looks good", "implement this",
  user approves ExitPlanMode, starting implementation.
---

# Execute Plan

Orchestrates plan implementation via OpenSpec or direct beads workflow.

## Usage

```
/execute-plan              # Read plan from conversation context (default)
/execute-plan <file-path>  # Read plan from specified file
```

## Quick Reference

| Plan Type | Workflow |
|-----------|----------|
| New feature, breaking change, cross-cutting | OpenSpec → epic + task beads from tasks.md |
| Bug fix, refactor, config, single-component | Direct beads epic + task beads from plan |

## Step 1: Get the Plan

**Default:** Read the plan from the current conversation context (the approved plan discussed above).

**With file argument:** If a path is passed (e.g., `/execute-plan plans/my-plan.md`), read from that file instead.

### From Context (Default)

Look for the most recent plan in the conversation history. Plans typically have:
- A clear title or goal statement
- Implementation steps (numbered or bulleted)
- Context about what needs to change

Extract:
- **Title**: The main goal or feature name
- **Summary**: One-line description of what the plan accomplishes
- **Steps**: The implementation tasks to perform

### From File (When Path Provided)

```bash
# Only if a file path was passed as argument
cat <provided-path>
```

Extract:
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
   This generates `openspec/changes/<change-id>/tasks.md` with the task breakdown.

2. **Create epic to track the change:**
   ```bash
   bd create --title="<change-id>" --type=epic --priority=2
   ```

3. **Parse tasks.md and create child beads:**

   Read `openspec/changes/<change-id>/tasks.md` and for each unchecked task (`- [ ]`):
   ```bash
   bd create --title="<task description>" --type=task --priority=2
   bd update <task-id> --parent=<epic-id>
   ```

   **Task grouping:** If tasks.md has section headers (## Section), include section context in task description.

   **Skip creating beads for:**
   - Already checked tasks (`- [x]`)
   - Manual testing tasks (leave for humans)

4. **Set dependencies between sibling tasks only:**

   If tasks have natural ordering (e.g., "Create migration" before "Run migration"):
   ```bash
   bd dep add <later-task-id> <earlier-task-id>
   ```

   **Never add a dependency between a child task and its parent epic.** Use `--parent` for structural grouping, `bd dep add` for ordering between siblings.

5. **Add standard tasks** (same as direct beads path):
   - Unit & integration tests (blocked by implementation tasks)
   - E2E tests (if user-facing)
   - Documentation updates

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

3. **Set dependencies between sibling tasks** (if steps depend on each other):
   ```bash
   bd dep add <later-task-id> <earlier-task-id>
   ```
   Only between siblings - never between a child and its parent epic.

4. **Add standard tasks:**
   ```bash
   bd create --title="Unit & integration tests" --type=task --priority=2
   bd update <test-task-id> --parent=<epic-id>
   # Block tests on all implementation tasks
   bd dep add <test-task-id> <impl-task-1-id>
   bd dep add <test-task-id> <impl-task-2-id>
   ```

## Step 4: Create Branch

Create a single branch for all implementation work:

| Path | Branch Name | Command |
|------|-------------|---------|
| OpenSpec | `<change-id>` | `but branch new <change-id>` |
| Direct beads | `<epic-name>` (kebab-case) | `but branch new <epic-name>` |

**Examples:**
- OpenSpec change `add-user-notifications` → `but branch new add-user-notifications`
- Epic "Fix auth middleware bugs" → `but branch new fix-auth-middleware-bugs`

## Step 5: Hand Off to /work

Both paths create an epic with child beads. Hand off the same way:

```
/work <epic-id>
Branch: <branch-name>
```

The `/work` skill will:
- Find next ready child task
- Delegate to task-implementer
- Close bead when task completes
- Loop until all tasks done

**OpenSpec note:** When closing task beads, also tick the corresponding checkbox in tasks.md to keep them in sync.

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

Once beads and branch are created, the `/work` skill handles execution:
- Receives branch name from this skill
- Finds next ready child task
- Claims it (marking in_progress)
- Delegates to task-implementer with branch name
- Commits via gitbutler to the specified branch
- Closes the task
- Loops to next ready task
