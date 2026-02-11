# Security Patterns

> Never trust client input. Never expose internal errors. Always scope to caller's context.

## Error Sanitization

Return generic messages to clients in all environments. Log full details server-side.

| Layer | Shows |
|-------|-------|
| Client (all environments) | Generic, static error message |
| Server logs | Full error with stack trace |

```
// Good - generic message to client, full details logged
logger.error('Failed to create item:', error);
return { error: 'Failed to create item' };

// Bad - leaks internal details
return { error: error.message };
return { error: result.message };

// Bad - environment-conditional error display
if (isDev) return { error: error.message };
return { error: 'Something went wrong' };
```

**Toast messages:** Use static strings. Never interpolate error objects or database messages into user-facing toasts.

## Authorization

| Principle | Implementation |
|-----------|---------------|
| Verify ownership | Every mutation checks caller owns the resource |
| Scope to context | All queries include caller's tenant/org scope |
| Verified auth for mutations | Use fresh auth validation for writes, not cached tokens |
| Fail closed | Missing auth context = reject, never assume |

## IDOR Prevention

Never trust client-supplied entity IDs alone. Cross-reference with ownership:

```
// Good - scoped to caller's tenant
SELECT * FROM items WHERE id = :itemId AND organization_id = :callerOrgId;

// Bad - trusts client-supplied ID
SELECT * FROM items WHERE id = :itemId;
```

Every entity lookup by ID must also verify the caller has access through tenant scoping, ownership checks, or role-based access control.

## Input Validation

Validate all inputs at system boundaries before processing. Use schema validation (Zod, Joi, etc.) to enforce types, ranges, and required fields.

Framework-specific examples: see your tech rules (e.g., `nextjs.md` for server actions).

## Webhook Security

| Step | Requirement |
|------|-------------|
| 1. Verify signature | Before any processing |
| 2. Use elevated/admin client | No user session exists in webhook context |
| 3. Idempotency | Handle duplicate deliveries gracefully |
| 4. Return 200 early | Prevent provider retries after processing |

## Danger Zone

| Never | Consequence |
|-------|-------------|
| `return { error: error.message }` | Leaks DB schema, provider details to client |
| Show detailed errors in dev but not prod | Inconsistent behavior, masks bugs that only appear in production |
| Raw `console.log` / `console.error` | No structure, no redaction, no level filtering |
| Query entity by ID without tenant scope | IDOR - users access other tenants' data |
| Skip input validation at system boundaries | Injection, type confusion, unexpected behavior |
| Use cached auth tokens for mutations | Token may be stale; verify freshly |
| Interpolate errors into toast messages | Internal details shown in UI |
