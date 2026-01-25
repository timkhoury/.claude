---
name: supabase-advisors
description: >
  Fetch and fix Supabase security and performance advisories.
  Use when user says "check advisories", "supabase audit",
  "fix security issues", or "address performance problems".
---

# Supabase Advisors

Audit Supabase project for security and performance issues, then generate fixes.

## Critical Rules

1. **Load MCP tools first**: Use `ToolSearch` to load `mcp__supabase__list_projects` and `mcp__supabase__get_advisors`
2. **Never apply migrations directly**: Create files in `supabase/migrations/`, use `npm run db:push`
3. **Always regenerate types**: Run `npm run db:types` after schema changes
4. **Include rollback SQL**: Add rollback commands in migration comments

## Workflow

### Step 1: Get Project ID

```typescript
// Load and call
ToolSearch({ query: "select:mcp__supabase__list_projects" })
mcp__supabase__list_projects({})
```

- If single project, use that ID
- If multiple projects, ask user to confirm which one
- If no projects, inform user and exit

### Step 2: Fetch Advisories

Fetch both types in parallel:

```typescript
ToolSearch({ query: "select:mcp__supabase__get_advisors" })

// Run both:
mcp__supabase__get_advisors({ project_id: "<id>", type: "security" })
mcp__supabase__get_advisors({ project_id: "<id>", type: "performance" })
```

### Step 3: Analyze & Display

Group advisories by severity:

```
## Supabase Audit: [PROJECT_NAME]

### Security Issues
| Severity | Issue | Table/Object | Remediation |
|----------|-------|--------------|-------------|
| critical | No RLS on users table | users | Enable RLS, add policies |
| high | Missing auth check | api_keys | Add RLS policy |

### Performance Issues
| Severity | Issue | Table/Object | Remediation |
|----------|-------|--------------|-------------|
| medium | Missing index | orders.user_id | CREATE INDEX |
| low | Unused index | products.old_idx | DROP INDEX |
```

If no issues found, report clean audit and exit.

### Step 4: Generate Fixes

For each advisory, generate appropriate fix:

| Advisory Type | Fix Approach |
|---------------|--------------|
| Missing RLS | Enable RLS + generate policy SQL |
| Missing index | Generate CREATE INDEX statement |
| Exposed table | Add restrictive RLS policies |
| Unused index | Generate DROP INDEX statement |
| Slow query | Suggest index or query rewrite |

### Step 5: Create Migration

Create a single migration file for all fixes:

```bash
npx supabase migration new fix_advisories_$(date +%Y%m%d)
```

Migration file pattern:

```sql
-- Fix security and performance advisories
-- Generated: YYYY-MM-DD
-- Advisories addressed:
--   - [security] Missing RLS on users table
--   - [performance] Missing index on orders.user_id

-- Enable RLS on tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Add RLS policies
CREATE POLICY "Users can view own data"
ON users FOR SELECT
USING (auth.uid() = id);

-- Add missing indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Rollback:
-- DROP INDEX IF EXISTS idx_orders_user_id;
-- DROP POLICY IF EXISTS "Users can view own data" ON users;
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
```

### Step 6: Apply & Verify

```bash
npm run db:push     # Apply migration
npm run db:types    # Regenerate types
```

Then re-run advisors check to verify fixes:

```typescript
mcp__supabase__get_advisors({ project_id: "<id>", type: "security" })
mcp__supabase__get_advisors({ project_id: "<id>", type: "performance" })
```

Report remaining issues if any.

## Common Advisory Patterns

### Missing RLS

```sql
-- Enable RLS
ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;

-- Multi-tenant pattern (adapt to your membership table)
-- Common patterns: organization_members, team_members, workspace_members
CREATE POLICY "Users can view scoped data"
ON {table} FOR SELECT
USING (
  {scope_column} IN (
    SELECT {scope_column} FROM {membership_table}
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert scoped data"
ON {table} FOR INSERT
WITH CHECK (
  {scope_column} IN (
    SELECT {scope_column} FROM {membership_table}
    WHERE user_id = auth.uid()
  )
);
```

### Missing Index

```sql
-- Simple index
CREATE INDEX idx_{table}_{column} ON {table}({column});

-- Partial index for soft-delete pattern
CREATE INDEX idx_{table}_{column}_active
ON {table}({column})
WHERE deleted_at IS NULL;

-- Composite index
CREATE INDEX idx_{table}_{col1}_{col2} ON {table}({col1}, {col2});
```

### System Tables (Deny-All RLS)

Some tables use webhook-only writes:

```sql
-- Deny all user writes (webhook-managed)
CREATE POLICY "No direct inserts"
ON {table} FOR INSERT
WITH CHECK (false);

-- Allow reads for members (adapt to your membership table)
CREATE POLICY "Members can view"
ON {table} FOR SELECT
USING (
  {scope_column} IN (
    SELECT {scope_column} FROM {membership_table}
    WHERE user_id = auth.uid()
  )
);
```

## Output Format

```
## Supabase Audit Complete

**Project:** project-name
**Issues Found:** X security, Y performance

### Fixes Applied
- [security] Enabled RLS on `users` table with scoped policies
- [performance] Added index on `orders.user_id`

### Migration Created
`supabase/migrations/YYYYMMDDHHMMSS_fix_advisories_20240115.sql`

### Verification
- [x] Migration applied successfully
- [x] Types regenerated
- [x] Re-audit shows 0 remaining issues

### Next Steps
1. Test the changes locally
2. Commit migration file
3. Deploy to production
```

## Reference

- Supabase patterns: See project's tech/supabase.md rule
- Data retention patterns: See project's patterns/data-retention.md rule
- Project-specific docs: Check docs/ folder for migration workflows
