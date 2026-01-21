---
name: Fix Tests
description: Run all tests, fix failures, and commit fixes to appropriate branches
category: Quality
tags: [test, fix, commit, debug]
---

# Fix Tests Command

Run all tests, identify failures, fix them, and commit fixes to the appropriate branches.

## Usage

```
/fix-tests
```

No arguments required - runs the full test suite.

## Workflow

### Step 1: Run All Tests

```bash
npm run test -- --reporter=verbose 2>&1
```

Capture and parse the output to identify:
- Total tests run
- Passing tests
- Failing tests (with file paths and test names)

### Step 2: Analyze Failures

For each failing test:

1. **Read the test file** to understand what's being tested
2. **Read the implementation** being tested
3. **Identify the cause**:
   - Test is outdated (implementation changed)
   - Implementation has a bug
   - Test setup/teardown issue
   - Missing mock or fixture

### Step 3: Categorize Fixes

Group fixes by their logical branch:

| Fix Type | Branch Assignment |
|----------|-------------------|
| Test for feature X | Branch where feature X was implemented |
| Test infrastructure | New branch `fix-test-infrastructure` |
| Multiple unrelated fixes | Separate commits per branch |
| Unknown origin | New branch `fix-failing-tests` |

**To identify the right branch:**

1. Check `but status -f` to see committed files per branch
2. Match test file to feature file in the same branch
3. If no match, check git blame for the implementation file

### Step 4: Fix Each Failure

For each failing test:

1. **Understand the failure** - Read error message and stack trace
2. **Determine fix location**:
   - If test is wrong → fix the test
   - If implementation is wrong → fix the implementation
3. **Make the fix** following project patterns
4. **Verify the fix** by running the specific test:
   ```bash
   npm run test -- <test-file> -t "<test-name>"
   ```

### Step 5: Commit Fixes

Use GitButler to commit fixes to appropriate branches:

```bash
but status                              # See file IDs
but rub <file-id> <target-branch>       # Assign to correct branch
but commit <branch> --only -m "..."     # Commit
```

**Commit message format:**
```
Fix failing test: <test description>

- <Brief explanation of what was wrong>
- <What the fix does>
```

### Step 6: Verify All Tests Pass

After all fixes are committed:

```bash
npm run test
```

Confirm all tests pass before completing.

## Output Format

```markdown
## Test Results

**Total**: X tests
**Passing**: Y tests
**Failing**: Z tests

---

## Failure Analysis

### 1. [Test Name] in `path/to/test.ts`

**Error**: [Error message summary]

**Cause**: [Analysis of why it's failing]

**Fix**: [What needs to be changed]

**Branch**: [Target branch for the fix]

---

## Fixes Applied

| Test | File Changed | Branch | Commit |
|------|--------------|--------|--------|
| Test name 1 | `file.ts` | feature-branch | abc123 |
| Test name 2 | `other.ts` | fix-failing-tests | def456 |

---

## Final Verification

✅ All X tests passing
```

## Branch Assignment Rules

1. **Feature tests** → Same branch as the feature
2. **Shared test utilities** → `fix-test-infrastructure` or existing infra branch
3. **Multiple features affected** → One commit per branch
4. **Can't determine origin** → New `fix-failing-tests` branch

## Important Notes

- **Run tests first** - Don't assume what's failing
- **Fix root cause** - Don't just make tests pass with hacks
- **Verify individually** - Run each fixed test before moving on
- **Commit logically** - Keep related fixes together
- **Use GitButler** - Assign files to correct branches before committing
- **Final verification** - Run full suite after all fixes

## Edge Cases

### Test Depends on External Service

If a test fails due to external dependency:
1. Check if test should be mocked
2. Add appropriate mock/stub
3. Document in test file why mock is needed

### Flaky Test

If a test passes sometimes and fails others:
1. Identify race condition or timing issue
2. Add proper async handling or retries
3. Consider `vi.waitFor()` for async assertions

### Database State Issue

If test fails due to leftover data:
1. Check `afterEach` cleanup is comprehensive
2. Add missing cleanup for new tables/data
3. Ensure test isolation

## Related Commands

- `/test` - Run tests and analyze coverage (no fixes)
- `/fix <feedback>` - Fix specific review feedback
- `/review` - Run code review (may identify test issues)
