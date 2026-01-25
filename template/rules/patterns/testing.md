# Testing Principles

> Universal testing philosophy. Framework-specific patterns in tech/*.md.

## Core Principles

| Principle | Description |
|-----------|-------------|
| Test isolation | Each test independent, no shared mutable state |
| Real dependencies | Prefer real implementations over mocks at boundaries |
| Fast feedback | Unit tests run in seconds, E2E reserved for critical paths |
| Cleanup always | Clean up test data in afterEach/afterAll blocks |

## Arrange-Act-Assert

Structure tests clearly:

```typescript
it('should do something', async () => {
  // Arrange - set up test data and dependencies
  const input = { name: 'test' };

  // Act - execute the code under test
  const result = await doSomething(input);

  // Assert - verify expected outcomes
  expect(result.success).toBe(true);
});
```

## When to Mock

| Mock | Don't Mock |
|------|------------|
| External APIs, third-party services | Your own code, internal modules |
| Time/randomness for determinism | Database (use real with cleanup) |
| Expensive operations in unit tests | Framework code (trust it works) |

## Test Naming

Describe behavior, not implementation:

| Good | Bad |
|------|-----|
| `should return error when email is invalid` | `test validateEmail function` |
| `prevents access to other org data` | `test RLS policy` |
| `displays loading state while fetching` | `test useQuery hook` |

## Coverage Philosophy

- Aim for meaningful coverage, not 100%
- Focus on critical paths: auth, billing, data mutations
- Don't test implementation details
- Integration tests > many unit tests for I/O code
- Edge cases and error handling should be tested

## Test Hierarchy

| Level | Speed | Scope | When to Use |
|-------|-------|-------|-------------|
| Unit | Fast | Single function/component | Business logic, utilities |
| Integration | Medium | Multiple components | API routes, database operations |
| E2E | Slow | Full user flows | Critical paths, smoke tests |

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Tests depend on execution order | Flaky in parallel, CI failures |
| Share mutable state between tests | Unpredictable failures |
| Mock what you don't own | Tests pass, production fails |
| Skip cleanup in DB tests | Data pollution, cascading failures |
| Use arbitrary timeouts | Flaky tests, slow CI |
| Test implementation details | Tests break on refactor |
