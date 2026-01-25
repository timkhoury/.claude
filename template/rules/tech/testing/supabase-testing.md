# Testing with Supabase

> Test against real database. Clean up after yourself.

## Core Principle

Use real Supabase database for Server Action tests. Mocking Supabase loses the value of testing RLS and query behavior.

## Recommended Test Utilities

Create project-specific test helpers in a consistent location:

| Utility | Recommended Location | Purpose |
|---------|---------------------|---------|
| Admin client | `lib/supabase/admin.ts` | Bypasses RLS for setup/cleanup |
| Test user management | `test/utils/` | Create/cleanup test users |
| Auth helpers | `test/utils/` | Sign in as test user |

## Test Setup Pattern

```typescript
// Import your project's test utilities
import { createAdminClient } from '@/lib/supabase/admin';
import { signInAsTestUser, setupTestUsers } from '@/test/utils';

const adminClient = createAdminClient();
const [testUser] = setupTestUsers([{ fullName: 'Test User' }]);

let recordId: string;

beforeEach(async () => {
  // Sign in as test user
  const client = await signInAsTestUser(
    testUser.getEmail(),
    testUser.getPassword()
  );

  // Mock the createClient to return authenticated client
  vi.mocked(createClient).mockResolvedValue(client);

  // Create test data
  const { data } = await adminClient
    .from('your_table')
    .insert({ name: 'Test Record' })
    .select()
    .single();
  recordId = data!.id;
});

afterEach(async () => {
  // ALWAYS clean up - this is critical
  await adminClient.from('your_table').delete().eq('id', recordId);
});
```

## Cleanup Pattern

**Order matters** - delete in reverse FK order:

```typescript
afterEach(async () => {
  // Children first (tables with foreign keys)
  await adminClient.from('child_table').delete().eq('parent_id', parentId);
  // Parent last
  await adminClient.from('parent_table').delete().eq('id', parentId);
});
```

## Testing RLS Policies

Use two users to verify RLS:

```typescript
const [owner, other] = setupTestUsers([
  { fullName: 'Owner' },
  { fullName: 'Other User' },
]);

it('prevents access to other user data', async () => {
  // Sign in as other user
  const otherClient = await signInAsTestUser(other.getEmail(), other.getPassword());

  // Should not see owner's data
  const { data } = await otherClient
    .from('protected_table')
    .select()
    .eq('id', ownerRecordId);

  expect(data).toHaveLength(0);  // RLS blocks access
});
```

## Admin Client Usage

Use admin client (bypasses RLS) for:
- Test data setup
- Test data cleanup
- Verifying data exists without RLS interference

```typescript
const adminClient = createAdminClient();

// Setup - create data regardless of RLS
await adminClient.from('items').insert({ ... });

// Verify - check data exists even if user can't see it
const { data } = await adminClient.from('items').select().eq('id', itemId);
expect(data).toHaveLength(1);

// Cleanup - delete regardless of RLS
await adminClient.from('items').delete().eq('id', itemId);
```

## Test User Management

Create a utility that manages test user lifecycle:

```typescript
// Example API - implement based on your project's needs
const [owner, member] = setupTestUsers([
  { fullName: 'Owner', email: 'owner@test.com' },
  { fullName: 'Member' },  // Auto-generate email if not specified
]);

// Access credentials
const email = owner.getEmail();
const password = owner.getPassword();

// Users should auto-cleanup in afterAll()
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Skip afterEach cleanup | Data pollution breaks other tests |
| Mock Supabase for Server Action tests | Misses RLS bugs, false confidence |
| Hardcode test user credentials | Breaks in CI, flaky tests |
| Delete in wrong FK order | FK constraint violations |
| Use production data in tests | Data corruption risk |
