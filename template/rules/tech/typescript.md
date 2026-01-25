# TypeScript Conventions

> Type safety without ceremony.

## Type Safety Rules

**Never use:**
- `as any` - defeats TypeScript, hides bugs
- `as unknown as T` double casts - anti-pattern, use single `as T` in tests

**Valid alternatives to `as any`:**

| Instead of `as any` | Use |
|---------------------|-----|
| Unknown response types | Define interfaces or use library type helpers |
| Test mocks | Single `as T` cast |
| Runtime type checking | Type guards (`typeof`, `instanceof`, custom guards) |

## Type Guards

```typescript
// typeof guard
if (typeof value === 'string') {
  value.toUpperCase();  // TypeScript knows it's string
}

// instanceof guard
if (error instanceof Error) {
  console.log(error.message);
}

// Custom guard
function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'id' in obj;
}
```

## Variable Naming Conventions

| Pattern | Rule | Example |
|---------|------|---------|
| Booleans | Prefix with `is`/`has`/`was`/`should`/`can` | `isLoading`, `hasError` |
| Terminology | Consistent within feature | Use "polling" everywhere, not mixed with "detection" |
| Type transforms | Name reveals type change | `idString` → `parsedId` |
| Collections | Describe structure | `userList`, `itemMap` |

**General:** Intention-revealing, searchable, pronounceable. Avoid abbreviations (`organizationId` not `orgId`).

## Utility Types

```typescript
// Partial - all properties optional
type PartialUser = Partial<User>;

// Required - all properties required
type RequiredUser = Required<User>;

// Pick - subset of properties
type UserName = Pick<User, 'firstName' | 'lastName'>;

// Omit - exclude properties
type UserWithoutId = Omit<User, 'id'>;

// Record - object with known key type
type UserMap = Record<string, User>;
```

## Enums vs Union Types

Prefer union types over enums:

```typescript
// Good - union type
type Status = 'pending' | 'active' | 'cancelled';

// Avoid - enum
enum Status {
  Pending = 'pending',
  Active = 'active',
  Cancelled = 'cancelled',
}
```

Unions are simpler, have better tree-shaking, and work better with type inference.

## Edge Runtime Compatibility

For Cloudflare Workers / Edge runtime:

**Never use:**
- `unescape()` / `escape()` - Deprecated
- Node.js `fs`, `path` modules - Use Web APIs
- `process.env` in client code - Use environment helpers
- Long `setTimeout`/`setInterval` - Workers have execution limits

**Safe alternatives:**
- Base64: `btoa()` / `atob()` or `Buffer.from()`
- Random: `crypto.getRandomValues()`
- Environment: Use framework's env helpers

## Danger Zone

| Never | Consequence |
|-------|-------------|
| `as any` | Defeats TypeScript, bugs slip through |
| `as unknown as T` | Anti-pattern, use single cast |
| Enums for simple unions | Over-engineering, worse tree-shaking |
| Abbreviations in names | Hard to search, unclear intent |
