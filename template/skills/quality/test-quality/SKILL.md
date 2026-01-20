---
name: quality:test-quality
description: >
  Analyze test coverage against OpenSpec functional requirements.
  Maps each spec scenario to tests, identifies gaps, reports on test health.
  Use when auditing test quality, before releases, or tracking test debt.
model: claude-opus-4-5
allowed-tools: [Read, Glob, Grep, Bash, Task, Write, TodoWrite]
---

# Test Quality Analysis

Systematically analyze test coverage against OpenSpec functional requirements. This skill maps scenarios to tests, identifies coverage gaps, and reports on test health.

## Core Philosophy

**Requirements-driven testing > Code coverage metrics**

Instead of asking "what % of code is tested?", we ask:
- Does every OpenSpec scenario have a test?
- Are our tests verifying the right behaviors?
- Where are the gaps in test coverage of *requirements*?

## Critical Rules

1. **Check for OpenSpec** - If no `openspec/specs/` directory exists, run test health check only
2. **Check progress file first** - Resume from `.test-quality/progress.json` if it exists
3. **Use subtasks for each spec** - Spawn a subagent to analyze each spec to preserve context
4. **JSON-first output** - Generate JSON results, then create markdown report from JSON
5. **Report gaps only** - Do not auto-create beads issues; let user decide what to track

## Output Files

| File | Purpose |
|------|---------|
| `.test-quality/progress.json` | Pause/resume state |
| `.test-quality/specs/*.json` | Per-spec analysis results |
| `.test-quality/results.json` | Aggregated results (source of truth) |
| `TEST_QUALITY_REPORT.md` | Human-readable report (generated from JSON) |

**Note:** Add `.test-quality/` to `.gitignore` before running.

## Before Starting

### 1. Check for OpenSpec Directory

```bash
ls openspec/specs/ 2>/dev/null || echo "NO_OPENSPEC"
```

If no OpenSpec directory exists, skip to **Test Health Check Only** section.

### 2. Check for Existing Progress

```bash
cat .test-quality/progress.json 2>/dev/null
```

If exists and status is `in_progress`, resume from `specs.inProgress`. Otherwise, start fresh.

### 3. Create Output Directory

```bash
mkdir -p .test-quality/specs
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
  description: "Analyze <spec-name> test coverage"
  subagent_type: "Explore"
  model: "sonnet"
  prompt: |
    Analyze test coverage for the `<spec-name>` spec.

    ## Instructions
    1. Read `openspec/specs/<spec-name>/spec.md`
    2. Extract ALL scenarios (lines starting with `#### Scenario:`)
    3. For EACH scenario:
       a. Extract the scenario name and WHEN/THEN conditions
       b. Search for matching tests using these strategies:
          - Explicit match: Test name/description contains scenario keywords
          - Semantic match: Test verifies WHEN/THEN conditions
          - File proximity: Test file in same feature area
          - Look for: `// Covers: <spec-name> > <scenario-name>` annotations
       c. Search locations:
          - Unit tests: `src/**/*.test.ts`
          - E2E tests: `e2e/tests/**/*.spec.ts`
    4. Assign status to each scenario:
       - "covered" = Test exists that verifies the scenario
       - "partial" = Test exists but doesn't cover all conditions
       - "missing" = No test found for this scenario

    ## Output Format (JSON)
    Return ONLY valid JSON in this exact structure:

    ```json
    {
      "spec": "<spec-name>",
      "analyzedAt": "<ISO timestamp>",
      "scenarios": {
        "total": <number>,
        "covered": <number>,
        "partial": <number>,
        "missing": <number>
      },
      "details": [
        {
          "scenario": "<scenario name from spec>",
          "status": "covered|partial|missing",
          "tests": [
            { "file": "<path>", "line": <number>, "name": "<test description>" }
          ],
          "suggestion": "<what test to add if missing>"
        }
      ]
    }
    ```

    Be thorough in searching for tests. Check both unit tests (*.test.ts) and E2E tests (*.spec.ts).
```

### Main Agent Workflow

1. **Initialize**: Create output directory, read progress file, enumerate specs
2. **For each unanalyzed spec**: Spawn subtask using Task tool
3. **Collect results**: Parse subtask JSON output
4. **Save per-spec JSON**: Write to `.test-quality/specs/<spec-name>.json`
5. **Update progress file**: Track completion status
6. **Continue**: Spawn next subtask

### Parallel Subtasks (Optional)

For faster analysis, spawn multiple subtasks in parallel (2-3 at a time):

```
// Single message with multiple Task tool calls
Task: Analyze oauth-authentication test coverage (subagent_type: Explore, model: sonnet)
Task: Analyze repository-linking test coverage (subagent_type: Explore, model: sonnet)
Task: Analyze billing-management-ui test coverage (subagent_type: Explore, model: sonnet)
```

## Progress File Format

Location: `.test-quality/progress.json`

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

Location: `.test-quality/specs/<spec-name>.json`

```json
{
  "spec": "oauth-authentication",
  "analyzedAt": "2026-01-20T15:30:00Z",
  "scenarios": {
    "total": 4,
    "covered": 3,
    "partial": 0,
    "missing": 1
  },
  "details": [
    {
      "scenario": "GitHub OAuth available",
      "status": "covered",
      "tests": [
        { "file": "e2e/tests/auth/oauth.spec.ts", "line": 15, "name": "displays GitHub OAuth button" }
      ]
    },
    {
      "scenario": "OAuth error handling",
      "status": "missing",
      "tests": [],
      "suggestion": "Add test for OAuth callback error states"
    }
  ]
}
```

## Aggregated Results Format

Location: `.test-quality/results.json`

```json
{
  "generatedAt": "2026-01-20T16:00:00Z",
  "summary": {
    "specsAnalyzed": 37,
    "totalScenarios": 180,
    "coveredScenarios": 142,
    "partialScenarios": 10,
    "missingScenarios": 28,
    "coveragePercent": 78.9
  },
  "byCategory": {
    "auth": { "specs": 6, "scenarios": 28, "covered": 24, "partial": 2, "missing": 2 },
    "billing": { "specs": 5, "scenarios": 35, "covered": 30, "partial": 3, "missing": 2 }
  },
  "gaps": [
    { "spec": "oauth-authentication", "scenario": "OAuth error handling", "priority": "high" },
    { "spec": "billing-management-ui", "scenario": "Invoice download failure", "priority": "high" }
  ],
  "testHealth": {
    "unitTests": { "passed": 145, "failed": 0, "skipped": 3 },
    "e2eTests": { "passed": 42, "failed": 0, "skipped": 0 },
    "flakyTests": []
  },
  "specs": ["oauth-authentication", "repository-linking", "..."]
}
```

## Generating Aggregated Results

After all specs are analyzed:

1. Read all `.test-quality/specs/*.json` files
2. Aggregate counts and build `byCategory` from spec name prefixes
3. Collect all missing scenarios into `gaps` list with priority:
   - High: Error handling, security, auth scenarios
   - Medium: Core functionality
   - Low: Edge cases, UI polish
4. Run test health check (see below)
5. Write to `.test-quality/results.json`

## Test Health Check

Run after spec analysis (or as the only step for non-OpenSpec projects):

### Unit Tests

```bash
npm run test 2>&1 | tail -20
```

Parse output for: passed count, failed count, skipped count.

### E2E Tests

```bash
npm run test:e2e 2>&1 | tail -30
```

Parse output for: passed count, failed count.

### Flaky Test Detection

Look for tests that have been skipped with `it.skip` or `test.skip`:

```bash
rg -l "(it|test)\.skip\(" src/**/*.test.ts e2e/**/*.spec.ts 2>/dev/null
```

## Markdown Report Generation

Generate `TEST_QUALITY_REPORT.md` from `.test-quality/results.json`:

```markdown
# Test Quality Report

**Generated:** 2026-01-20
**Spec Coverage:** 142/180 scenarios (79%)

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
| auth | 6 | 28 | 24 | 2 | 2 |
| billing | 5 | 35 | 30 | 3 | 2 |
| ... | ... | ... | ... | ... | ... |

## High Priority Gaps (Missing Tests)

These scenarios have no test coverage:

| Spec | Scenario | Suggestion |
|------|----------|------------|
| oauth-authentication | OAuth error handling | Add test for OAuth callback error states |
| billing-management-ui | Invoice download failure | Test download error and retry |

## Test Health

| Suite | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| Unit | 145 | 0 | 3 |
| E2E | 42 | 0 | 0 |

### Skipped Tests

- `src/test/auth.test.ts` - Contains skipped tests
- (list files with skipped tests)

---
*Source: .test-quality/results.json*
```

## Test Health Check Only (Non-OpenSpec Projects)

If `openspec/specs/` directory does not exist:

1. Report: "No OpenSpec specs found. Running test health check only."
2. Run test health check (unit tests, e2e tests, flaky detection)
3. Generate minimal report:

```markdown
# Test Health Report

**Generated:** 2026-01-20

**Note:** No OpenSpec specs found in this project. This report covers test health only.

## Test Health

| Suite | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| Unit | 145 | 0 | 3 |
| E2E | 42 | 0 | 0 |

### Skipped Tests
(list)

### Recommendations
- Consider adding OpenSpec functional specifications for requirements-driven testing
```

## Matching Strategies

When searching for tests that cover a scenario:

### 1. Explicit Mapping

Look for test files/names that directly match scenario keywords:

```typescript
// Scenario: "GitHub OAuth available"
// Look for: test('GitHub OAuth', ...) or describe('OAuth', ...)
```

### 2. Semantic Search

Search for WHEN/THEN keywords in test descriptions:

```typescript
// Scenario: "WHEN user clicks Continue with GitHub THEN redirected to OAuth"
// Look for: 'Continue with GitHub', 'redirect', 'OAuth'
```

### 3. File Proximity

Tests in the same feature folder as the spec:

```
openspec/specs/oauth-authentication/spec.md
-> e2e/tests/auth/**/*.spec.ts
-> src/server/actions/__tests__/auth.test.ts
```

### 4. Manual Annotation

Look for explicit coverage comments:

```typescript
// Covers: oauth-authentication > GitHub OAuth available
test('displays GitHub OAuth button', ...)
```

## Gap Priority Assignment

Assign priority based on scenario content:

| Priority | Scenario Contains |
|----------|-------------------|
| High | error, fail, security, auth, permission, deny, invalid |
| Medium | create, update, delete, save, submit, core functionality |
| Low | display, show, view, UI, edge case, optional |

## Pause/Resume Instructions

### When to Pause

- After completing a spec analysis (natural checkpoint)
- When approaching context limits
- When finding critical test failures needing immediate attention

### Before Pausing

1. Save current spec result to `.test-quality/specs/<spec>.json`
2. Update progress file with `inProgress` set to current spec
3. Ensure `completedSpecs` array is current

### When Resuming

1. Read `.test-quality/progress.json`
2. Skip specs in `completedSpecs` array
3. Continue from `inProgress` if set, otherwise next pending spec

## Quick Commands Reference

```bash
# === Setup ===
mkdir -p .test-quality/specs
echo ".test-quality/" >> .gitignore

# === Spec Discovery ===
ls openspec/specs/*/spec.md                    # List all specs
wc -l openspec/specs/*/spec.md                 # Count scenarios per spec
rg "^#### Scenario:" openspec/specs            # List all scenarios

# === Test Discovery ===
ls src/**/*.test.ts e2e/**/*.spec.ts           # List all test files
rg "describe\(|test\(|it\(" src/**/*.test.ts   # Find test definitions
rg "<scenario keywords>" src/**/*.test.ts      # Search for coverage

# === Test Health ===
npm run test                                    # Run unit tests
npm run test:e2e                               # Run E2E tests
rg "(it|test)\.skip\(" src e2e                 # Find skipped tests

# === Progress Check ===
cat .test-quality/progress.json                # Check progress
ls .test-quality/specs/ | wc -l                # Count completed specs
```

## Completion Workflow

**After ALL specs have been analyzed:**

1. Generate aggregated results: `.test-quality/results.json`
2. Run test health check
3. Generate markdown report: `TEST_QUALITY_REPORT.md`
4. Update progress file with `status: "complete"`
5. Report summary to user

## Beads Integration (Optional)

The skill does NOT auto-create beads issues. After reviewing gaps, user can manually create beads:

```bash
# Example: Create bead for high-priority gap
bd create --title="Add OAuth error handling tests" --type=task --priority=2 \
  --description="Missing test coverage for oauth-authentication > OAuth error handling scenario"
```

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Auto-create beads issues | Clutters issue tracker without user review |
| Skip progress file update | Lose resume capability |
| Run without checking for OpenSpec first | Confusing output for non-OpenSpec projects |
| Mark scenario as covered without evidence | False sense of test coverage |
