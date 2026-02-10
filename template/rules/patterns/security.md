# Security Patterns

> Never trust client input. Never expose internal errors. Always scope to caller's context.

## Error Sanitization

Return generic messages to clients. Log full details server-side.

| Environment | Client sees | Server logs |
|-------------|------------|-------------|
| Development | Full error details | Full error details |
| Production | Generic fallback message | Full error with stack trace |

**Pattern:** Use `sanitizeError(error, fallbackMessage)` in every server action catch path.

```typescript
// Good - generic message to client, full details logged
log.error('Failed to create item:', error);
return { error: 'Failed to create item' };

// Bad - leaks internal details
return { error: error.message };
return { error: result.message };
```

**Toast messages:** Use static strings. Never interpolate error objects or database messages into user-facing toasts.

## Structured Logging

Use `createLogger` from `@/lib/logger`. Never raw `console.log/warn/error`.

```typescript
import { createLogger } from '@/lib/logger';
const log = createLogger('FeatureName');

log.error('Operation failed:', error);    // Always logged, schema details redacted in prod
log.warn('Unexpected state:', { id });     // Always logged
log.debug('Processing:', { step: 1 });     // Dev/DEBUG only
```

The logger handles:
- Log injection prevention (OWASP A09) via control character sanitization
- Schema detail redaction in production (table names, constraint names)
- Namespace-based filtering via `DEBUG` env var

## Authorization

| Principle | Implementation |
|-----------|---------------|
| Verify ownership | Every mutation checks caller owns the resource |
| Scope to context | All entity queries include `.eq('organization_id', callerOrgId)` |
| Verified auth for mutations | Use `getCurrentUserVerified()` for writes, not cached tokens |
| Fail closed | Missing auth context = reject, never assume |

## IDOR Prevention

Never trust client-supplied entity IDs alone. Cross-reference with ownership:

```typescript
// Good - scoped to caller's organization
const { data } = await supabase
  .from('repositories')
  .select()
  .eq('id', repositoryId)
  .eq('organization_id', organization.id)  // IDOR prevention
  .single();

// Bad - trusts client-supplied ID
const { data } = await supabase
  .from('repositories')
  .select()
  .eq('id', repositoryId)
  .single();
```

## Input Validation

Validate all server action inputs with Zod before processing:

```typescript
const schema = z.object({
  name: z.string().min(1).max(100),
});

export async function myAction(data: unknown) {
  const validation = schema.safeParse(data);
  if (!validation.success) {
    return { error: validation.error.errors[0].message };
  }
  // Proceed with validated data
}
```

## Webhook Security

| Step | Requirement |
|------|-------------|
| 1. Verify signature | Before any processing |
| 2. Use admin client | No user session exists (see `supabase.md`) |
| 3. Idempotency | Handle duplicate deliveries gracefully |
| 4. Return 200 early | Prevent provider retries after processing |

## Danger Zone

| Never | Consequence |
|-------|-------------|
| `return { error: error.message }` | Leaks DB schema, provider details to client |
| `console.log()` / `console.error()` | No namespace, no redaction, no level filtering |
| Query entity by ID without org scope | IDOR - users access other orgs' data |
| Skip input validation in server actions | Injection, type confusion, unexpected behavior |
| Use `getCurrentUser()` for mutations | Cached token may be stale; use `getCurrentUserVerified()` |
| Interpolate errors into toast messages | Internal details shown in UI |
