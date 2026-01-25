# Test Analysis

Test coverage analysis - maps OpenSpec scenarios to tests.

## Test Search Locations

| Test Type | Locations |
|-----------|-----------|
| Unit tests | `src/**/*.test.ts` |
| E2E tests | `e2e/tests/**/*.spec.ts` |

## Status Definitions

| Status | Meaning |
|--------|---------|
| **Covered** | Test exists that verifies the scenario |
| **Partial** | Test exists but doesn't cover all conditions |
| **Missing** | No test found for this scenario |

## Matching Strategies

### 1. Explicit Match

Test name/description contains scenario keywords:

```typescript
// Scenario: "GitHub OAuth available"
// Look for: test('GitHub OAuth', ...) or describe('OAuth', ...)
```

### 2. Semantic Match

Search for WHEN/THEN keywords in test descriptions:

```typescript
// Scenario: "WHEN user clicks Continue with GitHub THEN redirected"
// Look for: 'Continue with GitHub', 'redirect', 'OAuth'
```

### 3. File Proximity

Tests in the same feature folder:

```
openspec/specs/oauth-authentication/spec.md
-> e2e/tests/auth/**/*.spec.ts
-> src/server/actions/__tests__/auth.test.ts
```

### 4. Annotation Match

Explicit coverage comments:

```typescript
// Covers: oauth-authentication > GitHub OAuth available
test('displays GitHub OAuth button', ...)
```

## Subtask Prompt Template

```
Analyze test coverage for the `<spec-name>` spec.

## Instructions
1. Read `openspec/specs/<spec-name>/spec.md`
2. Extract ALL scenarios (lines starting with `#### Scenario:`)
3. For EACH scenario:
   a. Extract the scenario name and WHEN/THEN conditions
   b. Search for matching tests using these strategies:
      - Explicit: Test name contains scenario keywords
      - Semantic: Test verifies WHEN/THEN conditions
      - Proximity: Test file in same feature area
      - Annotation: `// Covers: <spec-name> > <scenario-name>`
   c. Search locations:
      - Unit: `src/**/*.test.ts`
      - E2E: `e2e/tests/**/*.spec.ts`
4. Assign status: "covered", "partial", or "missing"

## Output Format (JSON)
Return ONLY valid JSON:

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
      "scenario": "<scenario name>",
      "status": "covered|partial|missing",
      "tests": [
        { "file": "<path>", "line": <number>, "name": "<test description>" }
      ],
      "suggestion": "<what test to add if missing>"
    }
  ]
}

Check both unit tests (*.test.ts) and E2E tests (*.spec.ts).
```

## Test Health Check

Run after spec analysis (or as fallback for non-OpenSpec projects):

### Unit Tests

```bash
npm run test 2>&1 | tail -20
```

Parse: passed count, failed count, skipped count.

### E2E Tests

```bash
npm run test:e2e 2>&1 | tail -30
```

Parse: passed count, failed count.

### Flaky Test Detection

Find skipped tests:

```bash
rg -l "(it|test)\.skip\(" src/**/*.test.ts e2e/**/*.spec.ts 2>/dev/null
```

## Non-OpenSpec Fallback

If no `openspec/specs/` exists, generate minimal report:

```markdown
# Test Health Report

**Generated:** <date>

**Note:** No OpenSpec specs found. This report covers test health only.

## Test Health

| Suite | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| Unit | 145 | 0 | 3 |
| E2E | 42 | 0 | 0 |

### Skipped Tests
(list files)

### Recommendations
- Consider adding OpenSpec specs for requirements-driven testing
```

## Gap Priority Rules

| Priority | Scenario Contains |
|----------|-------------------|
| High | error, fail, security, auth, permission, deny, invalid |
| Medium | create, update, delete, save, submit |
| Low | display, show, view, UI, edge case, optional |

## Quick Commands

```bash
# List all test files
ls src/**/*.test.ts e2e/**/*.spec.ts

# Find test definitions
rg "describe\(|test\(|it\(" src/**/*.test.ts

# Search for scenario keywords
rg "<keywords>" src/**/*.test.ts e2e/**/*.spec.ts

# Run tests
npm run test
npm run test:e2e

# Find skipped tests
rg "(it|test)\.skip\(" src e2e
```
