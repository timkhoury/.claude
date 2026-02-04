# Next.js + Supabase Integration

> Next.js-specific patterns. See `supabase.md` for core Supabase patterns (RLS, types, webhooks).

## Client Selection

| Context | Import | Notes |
|---------|--------|-------|
| Server Components | `@/lib/supabase/server` | Must `await createClient()` |
| Client Components | `@/lib/supabase/client` | No await needed |
| Middleware | `@/lib/supabase/middleware` | Handles session refresh |
| Webhooks | `@/lib/supabase/admin` | Bypasses RLS (see `supabase.md`) |

## Server Component Data Fetching

```typescript
// page.tsx - Server Component
import { createClient } from '@/lib/supabase/server';

export default async function Page() {
  const supabase = await createClient();  // MUST await

  const { data } = await supabase
    .from('items')
    .select('*');

  return <ItemList items={data ?? []} />;
}
```

## Server Actions with Supabase

```typescript
'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export async function createItem(formData: FormData) {
  const supabase = await createClient();

  const { error } = await supabase
    .from('items')
    .insert({ name: formData.get('name') });

  if (error) {
    return { error: error.message };
  }

  revalidatePath('/items');
  return { success: true };
}
```

## Auth: getClaims vs getUser

| Method | Mechanism | Latency | Use When |
|--------|-----------|---------|----------|
| `getClaims()` | Local JWT validation via cached JWKS | ~1-5ms | Redirects, read operations |
| `getUser()` | Network call to Supabase Auth | ~100-300ms | Mutations, security-sensitive ops |

**Key insight:** `getClaims()` still refreshes expired tokens before validating. Per Supabase docs: "If the user's access token is about to expire, the session will first be refreshed."

**Trade-off:** `getClaims()` won't detect server-side session revocation until token expires (~1hr). Use `getUser()` for mutations where this matters.

## Middleware with Fast Auth Headers

Middleware validates JWT via `getClaims()` and passes auth info to Server Components via headers:

```typescript
// src/lib/supabase/middleware.ts
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });
  const supabase = createServerClient(/* ... */);

  // Fast local JWT validation (refreshes if needed)
  const { data, error } = await supabase.auth.getClaims();

  // Pass auth info downstream via headers
  if (!error && data?.claims?.sub) {
    supabaseResponse.headers.set('x-user-id', data.claims.sub);
    supabaseResponse.headers.set('x-user-email', data.claims.email || '');
    supabaseResponse.headers.set('x-auth-validated', 'true');
  }

  return supabaseResponse;
}
```

**Security:** Clear incoming auth headers in main middleware to prevent client spoofing:

```typescript
// src/middleware.ts
export async function middleware(request: NextRequest) {
  request.headers.delete('x-user-id');
  request.headers.delete('x-user-email');
  request.headers.delete('x-auth-validated');

  return updateSession(request);
}
```

## Auth in Server Components

For redirects and read operations, use the fast path via auth helper:

```typescript
import { getCurrentUser } from '@/lib/auth';

export default async function Page() {
  const user = await getCurrentUser();  // Reads from headers (~0ms)

  if (!user) {
    redirect('/auth/sign-in');
  }

  return <Dashboard user={user} />;
}
```

For mutations or when full User object needed:

```typescript
import { getCurrentUserVerified } from '@/lib/auth';

export async function sensitiveAction() {
  const user = await getCurrentUserVerified();  // Network call (~100-300ms)
  // Full user object with fresh validation
}
```

## Cookie Modification Rules

| Context | Can Modify Cookies? | Pattern |
|---------|---------------------|---------|
| Server Action | Yes | Auth, session |
| Client Component → Server Action | Yes | Via action call |
| Server Component SSR | No | Return null, don't clear |

**Error you'll see:** "Cookies can only be modified in a Server Action"

**Solution:** Use client component to trigger server action for cookie operations.

## Client Component with Supabase

```typescript
'use client';

import { createClient } from '@/lib/supabase/client';

export function RealtimeComponent() {
  const supabase = createClient();  // No await for client

  useEffect(() => {
    const channel = supabase
      .channel('changes')
      .on('postgres_changes', { event: '*', schema: 'public' }, handler)
      .subscribe();

    return () => { supabase.removeChannel(channel) };
  }, []);
}
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Server client in Client Component | Auth breaks, cookies unavailable |
| `cookies()` in Client Component | Runtime error |
| Modify middleware `supabaseResponse` | Users logged out randomly |
| Forget `await createClient()` in Server Component | Type errors, undefined behavior |
| Call cookie-modifying action during SSR | "Cookies can only be modified" error |
