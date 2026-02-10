# Supabase Patterns

> PostgreSQL + Auth + RLS + Realtime.

## Client Types

| Client | Purpose | RLS |
|--------|---------|-----|
| Regular client | User operations | Enforced |
| Admin client | Webhooks, system operations | Bypassed |

## Migrations & Type Generation Workflow

When modifying the database schema, follow this workflow to keep types in sync:

```bash
# 1. Create/modify migration files in supabase/migrations/

# 2. Reset local database to apply migrations
npx supabase db reset --local

# 3. Regenerate types from LOCAL database
npx supabase gen types typescript --local 2>/dev/null > src/types/supabase.ts
```

**Why this order matters:**
- `db reset --local` applies all migrations from scratch, ensuring clean state
- Types must be generated from the local database that has the new schema
- The `2>/dev/null` suppresses CLI upgrade messages that can corrupt the output file

**When to regenerate types:**
- After creating or modifying any migration
- After pulling migrations from remote (`supabase db pull`)
- After switching branches with different migrations

### Local vs Remote Type Generation

| Flag | When to Use |
|------|-------------|
| `--local` | Development - types match your local migrations |
| `--linked` | Only when intentionally syncing with remote/production |

**Default to `--local` during development.** Using `--linked` can pull stale types from remote if you haven't pushed your migrations yet, causing type mismatches.

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

## RLS Security Hardening

Patterns from security audit. Complement the basic RLS section above.

**Admin-only tables** need explicit read denies, not just write denies:

```sql
-- Write deny alone is insufficient - authenticated users can still SELECT
CREATE POLICY "Deny all access" ON sensitive_table
  FOR ALL USING (false) WITH CHECK (false);
```

Without a `USING(false)` SELECT policy, any authenticated user can read all rows.

**SECURITY DEFINER functions** that accept user ID parameters must validate ownership:

```sql
CREATE OR REPLACE FUNCTION my_function(p_user_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Validate caller owns this user ID
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  -- ...
END;
$$;
```

**RLS/app logic consistency:** Server action authorization and RLS policies must agree. If a server action checks org membership, the RLS policy must also scope to that org. Mismatches cause silent data leaks or confusing empty results.

**Anon role privileges:** Revoke all access on sensitive tables. RLS protects authenticated users; `GRANT` controls unauthenticated:

```sql
REVOKE ALL ON api_keys, oauth_tokens, subscriptions, payment_methods FROM anon;
```

**Soft-delete in policies:** Every RLS policy on tables with `deleted_at` must include the filter. See `data-retention.md` for the full pattern.

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

**Applying migrations:**

| Command | Purpose |
|---------|---------|
| `npx supabase db reset --local` | Reset local DB and apply all migrations (dev workflow) |
| `npx supabase db push` | Push migrations to remote (deployment) |

After applying migrations locally, always regenerate types (see workflow above).

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
| Admin-only table without `USING(false)` SELECT policy | Authenticated users can read all rows |
| SECURITY DEFINER function trusting `p_user_id` parameter | Caller can impersonate other users |
| RLS policy missing `deleted_at IS NULL` filter | Soft-deleted data exposed |
| Sensitive table accessible to `anon` role | Unauthenticated access to secrets |
| RLS policy disagrees with server action auth check | Silent data leaks or empty results |
| Skip signature verification in webhooks | Security vulnerability |
| Use regular client in webhooks | RLS blocks operations |
| Forget `ENABLE ROW LEVEL SECURITY` | Data exposed to all users |
| Skip cleanup in real-time | Memory leaks |
| Query without considering RLS | Empty results, confusion |
| Generate types without `db reset` after migration changes | Types don't match schema |
| Use `--linked` for types during local development | Pulls stale remote types |
| Omit `2>/dev/null` in type generation | CLI messages corrupt output file |
