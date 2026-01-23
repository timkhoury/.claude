# Supabase Patterns

> PostgreSQL + Auth + RLS + Realtime.

## Client Types

| Client | Purpose | RLS |
|--------|---------|-----|
| Regular client | User operations | Enforced |
| Admin client | Webhooks, system operations | Bypassed |

## Type Generation

```bash
npx supabase gen types typescript --local > src/types/supabase.ts
```

Re-run after any schema changes.

## TypeScript Helper Types

```typescript
import { QueryData } from '@supabase/supabase-js';
import { Tables, TablesInsert, TablesUpdate } from '@/types/supabase';

// Row types
type User = Tables<'users'>;
type NewUser = TablesInsert<'users'>;
type UserUpdate = TablesUpdate<'users'>;

// Query result types (with joins)
const userWithOrg = supabase.from('users').select('*, organizations(*)');
type UserWithOrg = QueryData<typeof userWithOrg>;
```

**Never use:** `Database['public']['Tables']['x']['Row']` - use `Tables<'x'>` instead.

## Row-Level Security (RLS)

All tables must have RLS enabled. Policies use `auth.uid()` to restrict access.

**Policy pattern:**
```sql
CREATE POLICY "Users can view own data"
ON users FOR SELECT
USING (id = auth.uid());

CREATE POLICY "Users can update own data"
ON users FOR UPDATE
USING (id = auth.uid());
```

**With soft-delete:**
```sql
CREATE POLICY "Active users only"
ON users FOR SELECT
USING (deleted_at IS NULL AND id = auth.uid());
```

## Webhook Handlers

External webhooks (Stripe, GitHub) have no user session. Use admin client:

```typescript
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(request: Request) {
  // 1. Verify webhook signature FIRST
  if (!verifySignature(body, signature)) {
    return new Response('Invalid signature', { status: 401 });
  }

  // 2. Use admin client (bypasses RLS)
  const supabase = createAdminClient();

  // 3. Perform database operations
  await supabase.from('events').insert(data);
}
```

**Why admin for webhooks:**
- No authenticated user session exists
- `auth.uid()` returns null
- RLS would block all operations
- Signature verification provides authenticity

## System-Only Tables

Some tables deny all user writes via RLS:

```sql
CREATE POLICY "Deny all writes"
ON webhook_events FOR INSERT
WITH CHECK (false);
```

Only admin client can write to these tables.

## Real-time Subscriptions

```typescript
const channel = supabase
  .channel('room')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'messages' },
    (payload) => console.log(payload)
  )
  .subscribe();

// Cleanup
supabase.removeChannel(channel);
```

## Migrations

Create migration files in `supabase/migrations/`:

```sql
-- supabase/migrations/20240101000000_add_users_table.sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

Apply with: `npx supabase db push`

## MCP Diagnostic Tools

When debugging Supabase issues, use MCP tools (if available):

```typescript
// Security advisories (missing RLS, exposed columns)
mcp__supabase__get_advisors({ project_id: 'xxx', type: 'security' })

// Performance advisories (missing indexes, slow queries)
mcp__supabase__get_advisors({ project_id: 'xxx', type: 'performance' })

// Service logs
mcp__supabase__get_logs({ project_id: 'xxx', service: 'api' })      // PostgREST
mcp__supabase__get_logs({ project_id: 'xxx', service: 'postgres' }) // Database
mcp__supabase__get_logs({ project_id: 'xxx', service: 'auth' })     // Auth

// Search official docs
mcp__supabase__search_docs({ query: "RLS policies" })
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Skip signature verification in webhooks | Security vulnerability |
| Use regular client in webhooks | RLS blocks operations |
| Forget `ENABLE ROW LEVEL SECURITY` | Data exposed to all users |
| Skip cleanup in real-time | Memory leaks |
| Query without considering RLS | Empty results, confusion |
