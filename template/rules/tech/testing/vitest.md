# Vitest Patterns

> Fast unit testing with native ESM and TypeScript support.

## Test Structure

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

describe('MyFunction', () => {
  beforeEach(() => {
    // Setup before each test
  });

  afterEach(() => {
    // Cleanup after each test - ALWAYS clean up
  });

  it('should do something', () => {
    const result = myFunction();
    expect(result).toBe(expected);
  });
});
```

## Mocking

```typescript
// Mock a module
vi.mock('@/lib/something', () => ({
  someFunction: vi.fn().mockReturnValue('mocked'),
}));

// Mock a single function
const mockFn = vi.fn();
mockFn.mockResolvedValue({ data: 'test' });

// Spy on existing function
const spy = vi.spyOn(object, 'method');
```

## Test Casts

Use single `as T` casts for mocks in tests:

```typescript
// Good - single cast
const mockClient = { query: vi.fn() } as DatabaseClient;

// Bad - double cast
const mockClient = { query: vi.fn() } as unknown as DatabaseClient;
```

## Async Testing

```typescript
it('handles async operations', async () => {
  const result = await asyncFunction();
  expect(result).toBeDefined();
});

it('handles errors', async () => {
  await expect(failingFunction()).rejects.toThrow('Error message');
});
```

## Common Commands

```bash
npm run test              # Run all tests
npm run test:coverage     # With coverage report
npm run test:ui           # Interactive UI
npm run test -- path/file # Run specific file
npm run test -- -t "name" # Run by test name
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Skip afterEach cleanup | Data pollution between tests |
| Double cast (`as unknown as T`) | Anti-pattern, hides issues |
| Mock too much | Tests pass but code breaks |
| Forget to await async assertions | False positives |
