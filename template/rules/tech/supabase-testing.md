# Testing with Supabase

> Test against real database. Clean up after yourself.

## Core Principle

Use real Supabase database for Server Action tests. Mocking Supabase loses the value of testing RLS and query behavior.

## Test Setup Pattern

```typescript
import { createAdminClient, signInAsTestUser } from '@/test/utils/supabase-test-helpers';
import { setupTestUsers } from '@/test/utils/test-lifecycle';

const adminClient = createAdminClient();
const [testUser] = setupTestUsers([{ fullName: 'Test User' }]);

let orgId: string;

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
    .from('organizations')
    .insert({ name: 'Test Org' })
    .select()
    .single();
  orgId = data!.id;
});

afterEach(async () => {
  // ALWAYS clean up - this is critical
  await adminClient.from('organizations').delete().eq('id', orgId);
});
```

## Cleanup Pattern

**Order matters** - delete in reverse FK order:

```typescript
afterEach(async () => {
  // Children first
  await adminClient.from('team_members').delete().eq('organization_id', orgId);
  await adminClient.from('repositories').delete().eq('organization_id', orgId);
  // Parent last
  await adminClient.from('organizations').delete().eq('id', orgId);
});
```

## Testing RLS Policies

Use two users to verify RLS:

```typescript
const [owner, other] = setupTestUsers([
  { fullName: 'Owner' },
  { fullName: 'Other User' },
]);

it('prevents access to other org data', async () => {
  // Sign in as other user
  const otherClient = await signInAsTestUser(other.getEmail(), other.getPassword());

  // Should not see owner's data
  const { data } = await otherClient
    .from('organizations')
    .select()
    .eq('id', ownerOrgId);

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

```typescript
// setupTestUsers creates users before tests and cleans up after
const [owner, member] = setupTestUsers([
  { fullName: 'Owner', email: 'owner@test.com' },
  { fullName: 'Member' },  // Auto-generates email if not specified
]);

// Access credentials
const email = owner.getEmail();
const password = owner.getPassword();
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Skip afterEach cleanup | Data pollution breaks other tests |
| Mock Supabase for Server Action tests | Misses RLS bugs, false confidence |
| Hardcode test user credentials | Breaks in CI, flaky tests |
| Delete in wrong FK order | FK constraint violations |
| Use production data in tests | Data corruption risk |
