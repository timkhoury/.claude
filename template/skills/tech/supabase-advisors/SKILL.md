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

1. **Load MCP tools first** - Use `ToolSearch` to load `mcp__supabase__list_projects` and `mcp__supabase__get_advisors`
2. **Never apply migrations directly** - Create files in `supabase/migrations/`, use `npm run db:push`
3. **Always regenerate types** - Run `npm run db:types` after schema changes
4. **Include rollback SQL** - Add rollback commands in migration comments

## Workflow

### 1. Get Project ID

```typescript
ToolSearch({ query: "select:mcp__supabase__list_projects" })
mcp__supabase__list_projects({})
```

If multiple projects, ask user to confirm which one.

### 2. Fetch Advisories (parallel)

```typescript
ToolSearch({ query: "select:mcp__supabase__get_advisors" })
mcp__supabase__get_advisors({ project_id: "<id>", type: "security" })
mcp__supabase__get_advisors({ project_id: "<id>", type: "performance" })
```

### 3. Display Findings

Group by severity (critical → high → medium → low):

```
## Supabase Audit: [PROJECT_NAME]

### Security Issues
| Severity | Issue | Table | Remediation |
|----------|-------|-------|-------------|
| critical | No RLS | users | Enable RLS, add policies |

### Performance Issues
| Severity | Issue | Table | Remediation |
|----------|-------|-------|-------------|
| medium | Missing index | orders.user_id | CREATE INDEX |
```

If no issues, report clean audit and exit.

### 4. Generate Fixes

| Advisory Type | Fix Approach |
|---------------|--------------|
| Missing RLS | Enable RLS + policy (see `tech/supabase.md`) |
| Missing index | CREATE INDEX statement |
| Exposed table | Add restrictive RLS policies |
| Unused index | DROP INDEX statement |

**For SQL patterns:** Reference `tech/supabase.md` rule and `patterns/data-retention.md`.

### 5. Create Migration

```bash
npx supabase migration new fix_advisories_$(date +%Y%m%d)
```

Structure: header comment → RLS enables → policies → indexes → rollback section.

### 6. Apply & Verify

```bash
npm run db:push     # Apply migration
npm run db:types    # Regenerate types
```

Re-run advisors to verify fixes:
```typescript
mcp__supabase__get_advisors({ project_id: "<id>", type: "security" })
mcp__supabase__get_advisors({ project_id: "<id>", type: "performance" })
```

## Output Format

```
## Supabase Audit Complete

**Project:** project-name
**Issues Found:** X security, Y performance

### Fixes Applied
- [security] Enabled RLS on `users` with scoped policies
- [performance] Added index on `orders.user_id`

### Migration Created
`supabase/migrations/YYYYMMDDHHMMSS_fix_advisories.sql`

### Verification
- [x] Migration applied
- [x] Types regenerated
- [x] Re-audit: 0 remaining issues
```

## Reference

- **SQL patterns**: See `tech/supabase.md` rule (RLS, policies, admin client)
- **Data retention**: See `patterns/data-retention.md` (soft-delete patterns)
