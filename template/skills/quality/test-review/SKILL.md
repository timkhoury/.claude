---
name: test-review
description: >
  Audit test suite health: slow tests, flaky patterns, isolation issues, missing cleanup.
  Use when CI is slow, tests are flaky, or periodically to maintain test quality.
---

# Test Review

Audit test suite for performance, reliability, and maintainability issues.

## Quick Start

```bash
/test-review           # Full audit
/test-review slow      # Slow test analysis only
/test-review flaky     # Flaky pattern detection only
```

## Thresholds

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Unit test | <500ms | >1s | >3s |
| Integration test | <2s | >5s | >10s |
| E2E test | <10s | >30s | >60s |
| Total suite | <2min | >5min | >10min |

## Review Categories

### 1. Slow Tests

Run tests with timing output and identify outliers:

```bash
# Vitest with timing
npm run test -- --reporter=verbose 2>&1 | grep -E "^\s*[✓✗].*\d+ms"

# Jest with timing
npm run test -- --verbose 2>&1 | grep -E "^\s*[✓✗].*\(\d+.*ms\)"

# Playwright
npm run test:e2e -- --reporter=list 2>&1 | grep -E "\d+(\.\d+)?s"
```

**Common causes:**
- Real network calls (should mock)
- Database without cleanup (data accumulates)
- Unnecessary waits (`setTimeout`, `waitForTimeout`)
- Missing test isolation (tests depend on order)

### 2. Flaky Patterns

Search for anti-patterns that cause intermittent failures:

```bash
# Arbitrary timeouts
grep -r "setTimeout\|waitForTimeout\|sleep" --include="*.spec.*" --include="*.test.*"

# Date/time sensitivity
grep -r "new Date()\|Date.now()" --include="*.spec.*" --include="*.test.*"

# Random values without seeds
grep -r "Math.random()" --include="*.spec.*" --include="*.test.*"

# Race conditions
grep -r "Promise.race\|setInterval" --include="*.spec.*" --include="*.test.*"
```

**Red flags:**
- Tests that pass locally but fail in CI
- Tests that fail when run in different order
- Tests with `retry` or `flaky` annotations

### 3. Isolation Issues

Check for shared state between tests:

```bash
# Module-level state
grep -r "^let \|^var \|^const.*= \[\]\|^const.*= {}" --include="*.spec.*" --include="*.test.*"

# Missing cleanup
grep -rL "afterEach\|afterAll" --include="*.spec.*" --include="*.test.*"

# Hardcoded IDs/emails (collision risk)
grep -rE "test@|user-1|id-1|12345" --include="*.spec.*" --include="*.test.*"
```

### 4. Cleanup Patterns

Verify proper test data cleanup:

```bash
# Tests with database operations but no cleanup
grep -l "supabase\|prisma\|database" --include="*.spec.*" -r | while read f; do
  grep -L "delete\|cleanup\|afterEach" "$f"
done
```

### 5. Test Duplication

Identify similar test logic that could be consolidated:

```bash
# Repeated setup patterns
grep -rh "beforeEach" --include="*.spec.*" | sort | uniq -c | sort -rn | head -10

# Similar test names (may indicate duplication)
grep -rh "it('\|test('" --include="*.spec.*" | sort | uniq -d
```

## Review Process

### Step 1: Run Full Suite with Timing

```bash
npm run test 2>&1 | tee /tmp/test-output.log
```

### Step 2: Analyze Output

Parse test output for:
- Tests exceeding thresholds
- Failed tests and error patterns
- Total execution time

### Step 3: Search for Anti-Patterns

Run the grep commands above to find:
- Flaky patterns
- Isolation issues
- Missing cleanup

### Step 4: Report Findings

```markdown
## Test Suite Health Report

### Summary
- **Total tests**: X
- **Total time**: Xm Xs
- **Slow tests**: N (>threshold)
- **Flaky patterns**: N files
- **Missing cleanup**: N files

### Slow Tests (>threshold)
| Test | Duration | File | Recommendation |
|------|----------|------|----------------|
| name | Xs | path | action |

### Flaky Patterns Found
1. **file:line** - [pattern] - [recommendation]

### Isolation Issues
1. **file** - [issue] - [fix]

### Recommendations
#### Critical (CI Impact)
1. [specific fix]

#### Suggested (Maintainability)
1. [improvement]
```

## Common Fixes

| Issue | Fix |
|-------|-----|
| Slow DB tests | Use transactions, truncate instead of delete |
| Network calls in unit tests | Mock external services |
| Arbitrary timeouts | Use proper async waits |
| Shared module state | Move to beforeEach/afterEach |
| Hardcoded test data | Use factories with unique IDs |
| Missing cleanup | Add afterEach with deletion |

## After Completion

```bash
.claude/scripts/systems-tracker.sh record test-review
```
