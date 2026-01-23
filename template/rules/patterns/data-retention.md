# Data Retention & Deletion Patterns

> Never hard-delete entities with historical/audit value. Use soft-delete.

## When to Soft-Delete

| Soft-Delete | Hard-Delete |
|-------------|-------------|
| User accounts | Security tokens (API keys, OAuth) |
| Organizations/teams | Session data |
| Billing-related entities | Temporary/cache data |
| Audit-relevant records | |

## Implementation

1. **Column**: `deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL`
2. **Index**: Partial index on `deleted_at IS NULL`
3. **RLS**: All policies must filter `deleted_at IS NULL`
4. **Queries**: All application queries must exclude soft-deleted records
5. **Admin access**: Use admin client for historical data queries

**Migration pattern:**
```sql
ALTER TABLE {table} ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
CREATE INDEX idx_{table}_active ON {table}(id) WHERE deleted_at IS NULL;
```

**RLS pattern:**
```sql
CREATE POLICY "..." ON {table} FOR SELECT
  USING (deleted_at IS NULL AND {other_conditions});
```

## User Deletion

1. Set `deleted_at` on user profile table
2. Anonymize email: `deleted-{uuid}@anonymized.local`
3. Hard purge after retention period

**Why anonymize:** Preserves FK references, audit trail shows "a user" acted, original email available for re-registration.

## GDPR Compliance

- Soft delete = default for user-facing "delete"
- Hard purge after retention period via admin function
- Data export must include soft-deleted records user owns

## Retention Periods (Typical)

| Data Type | Retention | Reason |
|-----------|-----------|--------|
| Billing/financial | 7 years | Tax compliance |
| Audit events | 7 years | Legal holds |
| User profiles | 30 days | Account recovery |
| Organizations | 90 days | Dispute resolution |

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Hard-delete entities with audit value | Loses history, compliance issues |
| Forget `deleted_at IS NULL` in RLS | Exposes soft-deleted data |
| Skip soft-delete for users | GDPR non-compliance |
| Soft-delete security tokens | Tokens remain valid |
