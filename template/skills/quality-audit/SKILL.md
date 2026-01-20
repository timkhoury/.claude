---
name: quality-audit
description: >
  Combined quality analysis: spec implementation coverage AND test coverage.
  Single pass through OpenSpec specs, produces both SPEC_COVERAGE_REPORT.md
  and TEST_QUALITY_REPORT.md. Use for comprehensive quality audits.
model: claude-opus-4-5
allowed-tools: [Read, Glob, Grep, Bash, Task, Write, TodoWrite]
---

# Quality Audit

Combined analysis that checks both implementation coverage and test coverage against OpenSpec functional requirements in a single pass.

## What This Does

For each OpenSpec spec, analyzes:
1. **Implementation Coverage** - Is the scenario implemented in code?
2. **Test Coverage** - Is the scenario covered by tests?

Produces two reports:
- `SPEC_COVERAGE_REPORT.md` - Implementation gaps
- `TEST_QUALITY_REPORT.md` - Test gaps

## Core Philosophy

**Requirements-driven quality tracking**

A complete quality picture requires both:
- Every spec scenario should be **implemented**
- Every spec scenario should be **tested**

This skill answers both questions in one efficient pass.

## Critical Rules

1. **Check for OpenSpec** - If no `openspec/specs/` directory exists, run test health check only
2. **Check progress file first** - Resume from `.quality-audit/progress.json` if it exists
3. **Use subtasks for each spec** - Spawn a subagent to analyze both implementation AND tests
4. **JSON-first output** - Generate JSON results, then create both markdown reports
5. **Report gaps only** - Do not auto-create beads issues

## Output Files

| File | Purpose |
|------|---------|
| `.quality-audit/progress.json` | Pause/resume state |
| `.quality-audit/specs/*.json` | Per-spec combined results |
| `.quality-audit/results.json` | Aggregated results (source of truth) |
| `SPEC_COVERAGE_REPORT.md` | Implementation coverage report |
| `TEST_QUALITY_REPORT.md` | Test coverage report |

**Note:** Add `.quality-audit/` to `.gitignore` before running.

## Before Starting

### 1. Check for OpenSpec Directory

```bash
ls openspec/specs/ 2>/dev/null || echo "NO_OPENSPEC"
```

If no OpenSpec directory exists, run test health check only and produce minimal `TEST_QUALITY_REPORT.md`.

### 2. Check for Existing Progress

```bash
cat .quality-audit/progress.json 2>/dev/null
```

If exists and status is `in_progress`, resume from `specs.inProgress`. Otherwise, start fresh.

### 3. Create Output Directory

```bash
mkdir -p .quality-audit/specs
```

### 4. Enumerate All Specs

```bash
ls openspec/specs/*/spec.md | wc -l
```

Record total count for progress tracking.

## Subtask-Based Analysis (REQUIRED)

**Each spec analysis MUST be delegated to a subtask** to preserve the main context window.

### Spawning Combined Analysis Subtasks

Use the Task tool with `subagent_type: "Explore"` and `model: "sonnet"` for each spec:

```
Task tool call:
  description: "Audit <spec-name> quality"
  subagent_type: "Explore"
  model: "sonnet"
  prompt: |
    Analyze BOTH implementation coverage AND test coverage for the `<spec-name>` spec.

    ## Instructions
    1. Read `openspec/specs/<spec-name>/spec.md`
    2. Extract ALL scenarios (lines starting with `#### Scenario:`)
    3. For EACH scenario, analyze TWO things:

    ### A. Implementation Coverage
    Search for implementation evidence in:
    - Server actions: `src/server/actions/*.ts`
    - Components: `src/components/**/*.tsx`, `src/app/**/*.tsx`
    - API routes: `src/app/api/**/*.ts`
    - Database: `supabase/migrations/*.sql`
    - Hooks/utilities: `src/lib/**/*.ts`, `src/hooks/**/*.ts`

    Assign implementation status:
    - "implemented" = Code fulfills the scenario
    - "partial" = Some conditions implemented
    - "unimplemented" = No implementation found
    - "outdated" = Implementation differs from spec

    ### B. Test Coverage
    Search for tests in:
    - Unit tests: `src/**/*.test.ts`
    - E2E tests: `e2e/tests/**/*.spec.ts`

    Assign test status:
    - "covered" = Test exists that verifies the scenario
    - "partial" = Test exists but incomplete
    - "missing" = No test found

    ## Output Format (JSON)
    Return ONLY valid JSON in this exact structure:

    ```json
    {
      "spec": "<spec-name>",
      "analyzedAt": "<ISO timestamp>",
      "implementation": {
        "total": <number>,
        "implemented": <number>,
        "partial": <number>,
        "unimplemented": <number>,
        "outdated": <number>
      },
      "testing": {
        "total": <number>,
        "covered": <number>,
        "partial": <number>,
        "missing": <number>
      },
      "scenarios": [
        {
          "name": "<scenario name>",
          "implementation": {
            "status": "implemented|partial|unimplemented|outdated",
            "evidence": [{ "file": "<path>", "line": <number>, "description": "<what>" }],
            "missingConditions": ["<condition>"],
            "notes": "<if partial/outdated>"
          },
          "testing": {
            "status": "covered|partial|missing",
            "tests": [{ "file": "<path>", "line": <number>, "name": "<test name>" }],
            "suggestion": "<what test to add if missing>"
          }
        }
      ]
    }
    ```

    Be thorough in searching both implementation and test files.
```

### Main Agent Workflow

1. **Initialize**: Create output directory, read progress file, enumerate specs
2. **For each unanalyzed spec**: Spawn subtask using Task tool
3. **Collect results**: Parse subtask JSON output
4. **Save per-spec JSON**: Write to `.quality-audit/specs/<spec-name>.json`
5. **Update progress file**: Track completion status
6. **Continue**: Spawn next subtask

### Parallel Subtasks (Optional)

For faster analysis, spawn multiple subtasks in parallel (2-3 at a time):

```
// Single message with multiple Task tool calls
Task: Audit oauth-authentication quality (subagent_type: Explore, model: sonnet)
Task: Audit repository-linking quality (subagent_type: Explore, model: sonnet)
Task: Audit billing-management-ui quality (subagent_type: Explore, model: sonnet)
```

## Progress File Format

Location: `.quality-audit/progress.json`

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

## Per-Spec Result Format

Location: `.quality-audit/specs/<spec-name>.json`

```json
{
  "spec": "oauth-authentication",
  "analyzedAt": "2026-01-20T15:30:00Z",
  "implementation": {
    "total": 4,
    "implemented": 3,
    "partial": 0,
    "unimplemented": 1,
    "outdated": 0
  },
  "testing": {
    "total": 4,
    "covered": 2,
    "partial": 1,
    "missing": 1
  },
  "scenarios": [
    {
      "name": "GitHub OAuth available",
      "implementation": {
        "status": "implemented",
        "evidence": [
          { "file": "src/components/auth/oauth-buttons.tsx", "line": 45, "description": "OAuth button" }
        ],
        "missingConditions": [],
        "notes": null
      },
      "testing": {
        "status": "covered",
        "tests": [
          { "file": "e2e/tests/auth/oauth.spec.ts", "line": 15, "name": "displays GitHub button" }
        ],
        "suggestion": null
      }
    },
    {
      "name": "OAuth error handling",
      "implementation": {
        "status": "unimplemented",
        "evidence": [],
        "missingConditions": ["Error UI", "Retry mechanism"],
        "notes": "Callback exists but no error handling"
      },
      "testing": {
        "status": "missing",
        "tests": [],
        "suggestion": "Add test for OAuth callback errors"
      }
    }
  ]
}
```

## Aggregated Results Format

Location: `.quality-audit/results.json`

```json
{
  "generatedAt": "2026-01-20T16:00:00Z",
  "implementation": {
    "specsAnalyzed": 37,
    "totalScenarios": 180,
    "implemented": 150,
    "partial": 15,
    "unimplemented": 12,
    "outdated": 3,
    "coveragePercent": 83.3
  },
  "testing": {
    "specsAnalyzed": 37,
    "totalScenarios": 180,
    "covered": 142,
    "partial": 10,
    "missing": 28,
    "coveragePercent": 78.9
  },
  "byCategory": {
    "auth": {
      "specs": 6,
      "scenarios": 28,
      "implementation": { "implemented": 25, "partial": 2, "unimplemented": 1, "outdated": 0 },
      "testing": { "covered": 22, "partial": 3, "missing": 3 }
    }
  },
  "implementationGaps": [
    { "spec": "oauth-authentication", "scenario": "OAuth error handling", "priority": "high" }
  ],
  "testGaps": [
    { "spec": "oauth-authentication", "scenario": "OAuth error handling", "priority": "high" }
  ],
  "drift": [
    { "spec": "repository-linking", "scenario": "Repository rename", "notes": "Spec says X, code does Y" }
  ],
  "testHealth": {
    "unitTests": { "passed": 145, "failed": 0, "skipped": 3 },
    "e2eTests": { "passed": 42, "failed": 0, "skipped": 0 }
  },
  "specs": ["oauth-authentication", "..."]
}
```

## Generating Reports

After all specs are analyzed, generate BOTH reports from the aggregated JSON.

### SPEC_COVERAGE_REPORT.md

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

## Unimplemented Scenarios

| Spec | Scenario | Priority | Missing |
|------|----------|----------|---------|
| oauth-authentication | OAuth error handling | High | Error UI |

## Spec Drift

| Spec | Scenario | Issue |
|------|----------|-------|
| repository-linking | Repository rename | Spec says X, code does Y |

---
*Source: .quality-audit/results.json*
```

### TEST_QUALITY_REPORT.md

```markdown
# Test Quality Report

**Generated:** 2026-01-20
**Test Coverage:** 142/180 scenarios (79%)

## Summary

| Metric | Value |
|--------|-------|
| Specs Analyzed | 37 |
| Total Scenarios | 180 |
| Covered | 142 (79%) |
| Partial | 10 (6%) |
| Missing | 28 (16%) |

## Coverage by Category

| Category | Specs | Scenarios | Covered | Partial | Missing |
|----------|-------|-----------|---------|---------|---------|
| auth | 6 | 28 | 22 | 3 | 3 |

## Missing Test Coverage

| Spec | Scenario | Priority | Suggestion |
|------|----------|----------|------------|
| oauth-authentication | OAuth error handling | High | Add test for callback errors |

## Test Health

| Suite | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| Unit | 145 | 0 | 3 |
| E2E | 42 | 0 | 0 |

---
*Source: .quality-audit/results.json*
```

## Test Health Check

Run after spec analysis:

### Unit Tests

```bash
npm run test 2>&1 | tail -20
```

### E2E Tests

```bash
npm run test:e2e 2>&1 | tail -30
```

### Flaky/Skipped Detection

```bash
rg -l "(it|test)\.skip\(" src/**/*.test.ts e2e/**/*.spec.ts 2>/dev/null
```

## Non-OpenSpec Fallback

If no `openspec/specs/` directory exists:

1. Report: "No OpenSpec specs found. Running test health check only."
2. Run test health check
3. Generate minimal `TEST_QUALITY_REPORT.md` with test health only
4. Do NOT generate `SPEC_COVERAGE_REPORT.md`

## Pause/Resume Instructions

### When to Pause

- After completing a spec analysis (natural checkpoint)
- When approaching context limits

### Before Pausing

1. Save current spec result to `.quality-audit/specs/<spec>.json`
2. Update progress file with `inProgress` set to current spec
3. Ensure `completedSpecs` array is current

### When Resuming

1. Read `.quality-audit/progress.json`
2. Skip specs in `completedSpecs` array
3. Continue from `inProgress` if set, otherwise next pending spec

## Quick Commands Reference

```bash
# === Setup ===
mkdir -p .quality-audit/specs
echo ".quality-audit/" >> .gitignore

# === Spec Discovery ===
ls openspec/specs/*/spec.md                    # List all specs
rg "^#### Scenario:" openspec/specs            # List all scenarios

# === Progress Check ===
cat .quality-audit/progress.json               # Check progress
ls .quality-audit/specs/ | wc -l               # Count completed specs

# === Test Health ===
npm run test                                   # Run unit tests
npm run test:e2e                              # Run E2E tests
```

## Completion Workflow

**After ALL specs have been analyzed:**

1. Read all `.quality-audit/specs/*.json` files
2. Generate aggregated results: `.quality-audit/results.json`
3. Run test health check
4. Generate `SPEC_COVERAGE_REPORT.md`
5. Generate `TEST_QUALITY_REPORT.md`
6. Update progress file with `status: "complete"`
7. Report summary to user

## When to Use Which Skill

| Skill | Use When |
|-------|----------|
| `quality-audit` | Full audit - both implementation and tests |
| `spec-coverage` | Only checking implementation coverage |
| `test-quality` | Only checking test coverage |

`quality-audit` is more efficient for full audits (one pass), but individual skills are useful for focused checks.

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Auto-create beads issues | Clutters issue tracker without user review |
| Skip progress file update | Lose resume capability |
| Generate reports before all specs analyzed | Incomplete/misleading data |
| Ignore spec drift | Specs become unreliable documentation |
