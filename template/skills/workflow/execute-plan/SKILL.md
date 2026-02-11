---
name: execute-plan
description: >
  Execute an approved plan via OpenSpec or direct tasks.
  Use when plan is approved, "go ahead", "implement this", or after ExitPlanMode.
---

# Execute Plan

Orchestrates plan implementation via OpenSpec or direct task workflow.

## Usage

```
/execute-plan              # Read plan from conversation context (default)
/execute-plan <file-path>  # Read plan from specified file
```

## Quick Reference

| Plan Type | Workflow |
|-----------|----------|
| New feature, breaking change, cross-cutting | OpenSpec → tasks from tasks.md |
| Bug fix, refactor, config, single-component | Direct tasks from plan |

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

Read the provided file and extract:
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

### Direct Task Signals (use tasks only)

| Signal | Examples |
|--------|----------|
| Bug fix | "Fix...", "Resolve...", "Correct..." |
| Refactor | "Refactor...", "Cleanup...", "Simplify..." |
| Config/dependency | "Update deps...", "Configure...", "Add package..." |
| Single component | Changes isolated to one file or small area |
| Documentation | "Update docs...", "Add README..." |

**When unclear:** Default to direct tasks. Can upgrade to OpenSpec if complexity emerges.

## Step 3: Route to Workflow

### OpenSpec Path (Complex Features)

1. **Create OpenSpec change:**
   ```
   /opsx:ff <summary from plan>
   ```
   This generates `openspec/changes/<change-id>/tasks.md` with the task breakdown.

2. **Parse tasks.md and create tasks:**

   Read `openspec/changes/<change-id>/tasks.md` and for each unchecked task (`- [ ]`):
   ```
   TaskCreate({
     subject: "<task description>",
     description: "<section context + task details>",
     activeForm: "<-ing form of task>",
     metadata: { specId: "<change-id>" }
   })
   ```

   **Task grouping:** If tasks.md has section headers (## Section), include section context in task description.

   **Skip creating tasks for:**
   - Already checked tasks (`- [x]`)
   - Manual testing tasks (leave for humans)

3. **Set dependencies between tasks:**

   If tasks have natural ordering (e.g., "Create migration" before "Run migration"):
   ```
   TaskUpdate({ taskId: "<later>", addBlockedBy: ["<earlier>"] })
   ```

4. **Add standard tasks** (same as direct path):
   - Unit & integration tests (blocked by implementation tasks)
   - E2E tests (if user-facing)
   - Documentation updates

### Direct Task Path (Simpler Work)

1. **Create tasks from plan steps:**
   For each implementation step:
   ```
   TaskCreate({
     subject: "<step title>",
     description: "<step details>",
     activeForm: "<-ing form of step>"
   })
   ```

2. **Set dependencies between tasks** (if steps depend on each other):
   ```
   TaskUpdate({ taskId: "<later>", addBlockedBy: ["<earlier>"] })
   ```

3. **Add standard tasks:**
   ```
   TaskCreate({
     subject: "Unit & integration tests",
     description: "Write tests for implementation tasks",
     activeForm: "Writing tests"
   })
   # Block tests on all implementation tasks
   TaskUpdate({ taskId: "<test>", addBlockedBy: ["<impl-1>", "<impl-2>"] })
   ```

## Step 4: Create Branch

Create a single branch for all implementation work:

| Path | Branch Name | Command |
|------|-------------|---------|
| OpenSpec | `<change-id>` | `but branch new <change-id>` |
| Direct tasks | `<plan-name>` (kebab-case) | `but branch new <plan-name>` |

**Examples:**
- OpenSpec change `add-user-notifications` → `but branch new add-user-notifications`
- Plan "Fix auth middleware bugs" → `but branch new fix-auth-middleware-bugs`

## Step 5: Hand Off to /work

Hand off with the branch name:

```
/work
Branch: <branch-name>
```

The `/work` skill will:
- Find next ready task (pending + no blockers)
- Delegate to task-implementer
- Complete task when done
- Loop until all tasks done

**OpenSpec note:** When completing tasks, also tick the corresponding checkbox in tasks.md to keep them in sync.

## Standard Tasks

**Every session MUST include these tasks** (created after implementation tasks):

| Task | Blocked By |
|------|------------|
| Unit & integration tests | All implementation tasks |
| E2E tests (if user-facing) | Unit tests |
| Documentation updates | Implementation tasks |

**Rules:**
- **Tests**: Must pass and achieve reasonable coverage (detect runner from lockfile: `bun.lock` → bun, `pnpm-lock.yaml` → pnpm, `package-lock.json` → npm)
- **E2E**: Required if feature has user-facing UI; skip if no UI changes
- **Docs**: Update relevant docs in `docs/`; skip if no doc changes needed

## Why This Pattern

- **Context preservation**: Each task gets fresh subagent context
- **Dependency ordering**: Tasks unblock in the right sequence
- **Commit granularity**: One commit per task, clear attribution

## After Setup

Once tasks and branch are created, the `/work` skill handles execution:
- Finds next ready task (pending + no blockers via TaskList)
- Claims it (marking in_progress)
- Delegates to task-implementer with branch name
- Commits via gitbutler to the specified branch
- Completes the task
- Loops to next ready task
