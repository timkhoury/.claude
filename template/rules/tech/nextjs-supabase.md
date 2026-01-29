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

## Auth in Server Components

```typescript
// Get current user
import { createClient } from '@/lib/supabase/server';

export default async function Page() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect('/auth/sign-in');
  }

  return <Dashboard user={user} />;
}
```

## Middleware Auth Refresh

The middleware must refresh the session to keep users logged in:

```typescript
// middleware.ts
import { createClient } from '@/lib/supabase/middleware';

export async function middleware(request: NextRequest) {
  const { supabaseResponse } = await createClient(request);

  // CRITICAL: Return the exact supabaseResponse
  return supabaseResponse;
}
```

**Never modify `supabaseResponse`** - it contains cookies that must be set exactly as returned.

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
