---
name: spec-coverage
description: >
  Analyze implementation coverage against OpenSpec functional requirements.
  Maps each spec scenario to code implementation, identifies gaps, reports coverage.
  Use when auditing implementation completeness, before releases, or planning work.
model: claude-opus-4-5
allowed-tools: [Read, Glob, Grep, Bash, Task, Write, TodoWrite]
---

# Spec Coverage Analysis

Systematically analyze whether OpenSpec functional requirements are implemented in the codebase. This skill maps scenarios to implementation code, identifies coverage gaps, and reports on implementation completeness.

## Core Philosophy

**Requirements-driven implementation tracking**

Instead of asking "is the code complete?", we ask:
- Does every OpenSpec scenario have corresponding implementation?
- Where are the gaps between specs and code?
- What's our implementation coverage of *requirements*?

## Critical Rules

1. **Check for OpenSpec** - If no `openspec/specs/` directory exists, report and exit
2. **Check progress file first** - Resume from `.spec-coverage/progress.json` if it exists
3. **Use subtasks for each spec** - Spawn a subagent to analyze each spec to preserve context
4. **JSON-first output** - Generate JSON results, then create markdown report from JSON
5. **Report gaps only** - Do not auto-create beads issues; let user decide what to track

## Output Files

| File | Purpose |
|------|---------|
| `.spec-coverage/progress.json` | Pause/resume state |
| `.spec-coverage/specs/*.json` | Per-spec analysis results |
| `.spec-coverage/results.json` | Aggregated results (source of truth) |
| `SPEC_COVERAGE_REPORT.md` | Human-readable report (generated from JSON) |

**Note:** Add `.spec-coverage/` to `.gitignore` before running.

## Before Starting

### 1. Check for OpenSpec Directory

```bash
ls openspec/specs/ 2>/dev/null || echo "NO_OPENSPEC"
```

If no OpenSpec directory exists, report: "No OpenSpec specs found. This skill requires OpenSpec specifications." and exit.

### 2. Check for Existing Progress

```bash
cat .spec-coverage/progress.json 2>/dev/null
```

If exists and status is `in_progress`, resume from `specs.inProgress`. Otherwise, start fresh.

### 3. Create Output Directory

```bash
mkdir -p .spec-coverage/specs
```

### 4. Enumerate All Specs

```bash
ls openspec/specs/*/spec.md | wc -l
```

Record total count for progress tracking.

## Subtask-Based Analysis (REQUIRED)

**Each spec analysis MUST be delegated to a subtask** to preserve the main context window.

### Spawning Spec Analysis Subtasks

Use the Task tool with `subagent_type: "Explore"` and `model: "sonnet"` for each spec:

```
Task tool call:
  description: "Analyze <spec-name> implementation"
  subagent_type: "Explore"
  model: "sonnet"
  prompt: |
    Analyze implementation coverage for the `<spec-name>` spec.

    ## Instructions
    1. Read `openspec/specs/<spec-name>/spec.md`
    2. Extract ALL scenarios (lines starting with `#### Scenario:`)
    3. For EACH scenario:
       a. Extract the scenario name and WHEN/THEN conditions
       b. Search for implementation evidence:
          - Server actions: `src/server/actions/*.ts`
          - Components: `src/components/**/*.tsx`, `src/app/**/*.tsx`
          - API routes: `src/app/api/**/*.ts`
          - Database: `supabase/migrations/*.sql`
          - Hooks/utilities: `src/lib/**/*.ts`, `src/hooks/**/*.ts`
       c. Verify the WHEN conditions trigger the expected behavior
       d. Verify the THEN outcomes are produced
    4. Assign status to each scenario:
       - "implemented" = Code exists that fulfills the scenario
       - "partial" = Some conditions implemented, others missing
       - "unimplemented" = No implementation found
       - "outdated" = Implementation differs from spec (spec drift)

    ## Output Format (JSON)
    Return ONLY valid JSON in this exact structure:

    ```json
    {
      "spec": "<spec-name>",
      "analyzedAt": "<ISO timestamp>",
      "scenarios": {
        "total": <number>,
        "implemented": <number>,
        "partial": <number>,
        "unimplemented": <number>,
        "outdated": <number>
      },
      "details": [
        {
          "scenario": "<scenario name from spec>",
          "status": "implemented|partial|unimplemented|outdated",
          "evidence": [
            { "file": "<path>", "line": <number>, "description": "<what it implements>" }
          ],
          "missingConditions": ["<WHEN/THEN condition not found>"],
          "notes": "<explanation if partial/outdated>"
        }
      ]
    }
    ```

    Be thorough in searching. Check server actions, components, routes, and database migrations.
```

### Main Agent Workflow

1. **Initialize**: Create output directory, read progress file, enumerate specs
2. **For each unanalyzed spec**: Spawn subtask using Task tool
3. **Collect results**: Parse subtask JSON output
4. **Save per-spec JSON**: Write to `.spec-coverage/specs/<spec-name>.json`
5. **Update progress file**: Track completion status
6. **Continue**: Spawn next subtask

### Parallel Subtasks (Optional)

For faster analysis, spawn multiple subtasks in parallel (2-3 at a time):

```
// Single message with multiple Task tool calls
Task: Analyze oauth-authentication implementation (subagent_type: Explore, model: sonnet)
Task: Analyze repository-linking implementation (subagent_type: Explore, model: sonnet)
Task: Analyze billing-management-ui implementation (subagent_type: Explore, model: sonnet)
```

## Progress File Format

Location: `.spec-coverage/progress.json`

```json
{
  "startedAt": "2026-01-20T15:30:00Z",
  "lastUpdated": "2026-01-20T16:00:00Z",
  "status": "in_progress|complete",
  "specs": {
    "total": 37,
    "completed": 12,
    "inProgress": "billing-management-ui",
    "pending": ["dashboard-view", "..."]
  },
  "completedSpecs": ["oauth-authentication", "repository-linking", "..."]
}
```

**Resume behavior:** Read progress.json, skip specs in `completedSpecs`, continue from `inProgress`.

## Per-Spec Result Format

Location: `.spec-coverage/specs/<spec-name>.json`

```json
{
  "spec": "oauth-authentication",
  "analyzedAt": "2026-01-20T15:30:00Z",
  "scenarios": {
    "total": 4,
    "implemented": 3,
    "partial": 0,
    "unimplemented": 1,
    "outdated": 0
  },
  "details": [
    {
      "scenario": "GitHub OAuth available",
      "status": "implemented",
      "evidence": [
        { "file": "src/components/auth/oauth-buttons.tsx", "line": 45, "description": "GitHub OAuth button component" },
        { "file": "src/server/actions/auth.ts", "line": 120, "description": "signInWithOAuth action" }
      ],
      "missingConditions": [],
      "notes": null
    },
    {
      "scenario": "OAuth error handling",
      "status": "unimplemented",
      "evidence": [],
      "missingConditions": ["Error message display", "Retry mechanism"],
      "notes": "Callback exists but no error UI"
    }
  ]
}
```

## Aggregated Results Format

Location: `.spec-coverage/results.json`

```json
{
  "generatedAt": "2026-01-20T16:00:00Z",
  "summary": {
    "specsAnalyzed": 37,
    "totalScenarios": 180,
    "implementedScenarios": 150,
    "partialScenarios": 15,
    "unimplementedScenarios": 12,
    "outdatedScenarios": 3,
    "coveragePercent": 83.3
  },
  "byCategory": {
    "auth": { "specs": 6, "scenarios": 28, "implemented": 25, "partial": 2, "unimplemented": 1, "outdated": 0 },
    "billing": { "specs": 5, "scenarios": 35, "implemented": 30, "partial": 3, "unimplemented": 1, "outdated": 1 }
  },
  "gaps": [
    { "spec": "oauth-authentication", "scenario": "OAuth error handling", "priority": "high", "missingConditions": ["Error UI"] },
    { "spec": "billing-management-ui", "scenario": "Invoice download", "priority": "medium", "missingConditions": ["Download endpoint"] }
  ],
  "drift": [
    { "spec": "repository-linking", "scenario": "Repository rename", "notes": "Spec says X, code does Y" }
  ],
  "specs": ["oauth-authentication", "repository-linking", "..."]
}
```

## Generating Aggregated Results

After all specs are analyzed:

1. Read all `.spec-coverage/specs/*.json` files
2. Aggregate counts and build `byCategory` from spec name prefixes
3. Collect unimplemented scenarios into `gaps` list with priority:
   - High: Core functionality, auth, security
   - Medium: Standard features
   - Low: Edge cases, polish
4. Collect outdated scenarios into `drift` list
5. Write to `.spec-coverage/results.json`

## Markdown Report Generation

Generate `SPEC_COVERAGE_REPORT.md` from `.spec-coverage/results.json`:

```markdown
# Spec Coverage Report

**Generated:** 2026-01-20
**Implementation Coverage:** 150/180 scenarios (83%)

## Summary

| Metric | Value |
|--------|-------|
| Specs Analyzed | 37 |
| Total Scenarios | 180 |
| Implemented | 150 (83%) |
| Partial | 15 (8%) |
| Unimplemented | 12 (7%) |
| Outdated (Drift) | 3 (2%) |

## Coverage by Category

| Category | Specs | Scenarios | Implemented | Partial | Unimplemented | Outdated |
|----------|-------|-----------|-------------|---------|---------------|----------|
| auth | 6 | 28 | 25 | 2 | 1 | 0 |
| billing | 5 | 35 | 30 | 3 | 1 | 1 |
| ... | ... | ... | ... | ... | ... | ... |

## Unimplemented Scenarios (Gaps)

These scenarios have no implementation:

| Spec | Scenario | Priority | Missing |
|------|----------|----------|---------|
| oauth-authentication | OAuth error handling | High | Error UI |
| billing-management-ui | Invoice download | Medium | Download endpoint |

## Spec Drift (Code differs from Spec)

These scenarios have implementation that differs from the spec:

| Spec | Scenario | Issue |
|------|----------|-------|
| repository-linking | Repository rename | Spec says X, code does Y |

**Action Required:** Update spec to match code, or fix code to match spec.

## Per-Spec Details

### oauth-authentication (95%)

| Scenario | Status | Evidence |
|----------|--------|----------|
| GitHub OAuth available | Implemented | `oauth-buttons.tsx:45`, `auth.ts:120` |
| OAuth error handling | Unimplemented | - |

---
*Source: .spec-coverage/results.json*
```

## Evidence Search Locations

| Requirement Type | Search Locations |
|------------------|------------------|
| Server Actions | `src/server/actions/*.ts` |
| UI Components | `src/components/**/*.tsx`, `src/app/(application)/**/*.tsx` |
| Page Routes | `src/app/(application)/**/page.tsx` |
| API Routes | `src/app/api/**/*.ts` |
| Database Schema | `supabase/migrations/*.sql` |
| RLS Policies | `supabase/migrations/*.sql` |
| Hooks | `src/hooks/**/*.ts` |
| Utilities | `src/lib/**/*.ts` |

## Status Definitions

| Status | Meaning | Action |
|--------|---------|--------|
| **Implemented** | All WHEN/THEN conditions have code | None |
| **Partial** | Some conditions implemented | Complete missing conditions |
| **Unimplemented** | No implementation found | Implement the scenario |
| **Outdated** | Code differs from spec | Update spec or fix code |

## Gap Priority Assignment

Assign priority based on scenario content:

| Priority | Scenario Contains |
|----------|-------------------|
| High | auth, security, permission, payment, error handling, core flow |
| Medium | create, update, delete, standard features |
| Low | display, UI polish, edge cases, optional features |

## Pause/Resume Instructions

### When to Pause

- After completing a spec analysis (natural checkpoint)
- When approaching context limits
- When finding critical drift needing immediate attention

### Before Pausing

1. Save current spec result to `.spec-coverage/specs/<spec>.json`
2. Update progress file with `inProgress` set to current spec
3. Ensure `completedSpecs` array is current

### When Resuming

1. Read `.spec-coverage/progress.json`
2. Skip specs in `completedSpecs` array
3. Continue from `inProgress` if set, otherwise next pending spec

## Quick Commands Reference

```bash
# === Setup ===
mkdir -p .spec-coverage/specs
echo ".spec-coverage/" >> .gitignore

# === Spec Discovery ===
ls openspec/specs/*/spec.md                    # List all specs
rg "^#### Scenario:" openspec/specs            # List all scenarios
rg "^### Requirement:" openspec/specs          # List all requirements

# === Implementation Search ===
rg "<keywords>" src/server/actions/            # Search server actions
rg "<keywords>" src/components/                # Search components
rg "<keywords>" src/app/                       # Search routes
rg "<keywords>" supabase/migrations/           # Search database

# === Progress Check ===
cat .spec-coverage/progress.json               # Check progress
ls .spec-coverage/specs/ | wc -l               # Count completed specs
```

## Completion Workflow

**After ALL specs have been analyzed:**

1. Generate aggregated results: `.spec-coverage/results.json`
2. Generate markdown report: `SPEC_COVERAGE_REPORT.md`
3. Update progress file with `status: "complete"`
4. Report summary to user

## Beads Integration (Optional)

The skill does NOT auto-create beads issues. After reviewing gaps, user can manually create beads:

```bash
# Example: Create bead for unimplemented scenario
bd create --title="Implement OAuth error handling" --type=task --priority=2 \
  --description="Missing implementation for oauth-authentication > OAuth error handling scenario"

# Example: Create bead for spec drift
bd create --title="Fix repository rename spec drift" --type=bug --priority=1 \
  --description="Code differs from spec for repository-linking > Repository rename"
```

## Relationship to test-quality

These skills complement each other:

| Skill | Question | Output |
|-------|----------|--------|
| `spec-coverage` | Is the spec **implemented**? | Implementation evidence |
| `test-quality` | Is the spec **tested**? | Test coverage |

Run both for a complete quality picture:
1. `spec-coverage` - Verify specs are implemented
2. `test-quality` - Verify implementations are tested

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Auto-create beads issues | Clutters issue tracker without user review |
| Skip progress file update | Lose resume capability |
| Mark scenario as implemented without evidence | False sense of coverage |
| Ignore spec drift | Specs become unreliable documentation |
| Confuse with test-quality | Different purpose - implementation vs testing |
