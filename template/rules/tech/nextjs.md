# Next.js App Router Patterns

> React Server Components by default. Add 'use client' only for interactivity.

## Server vs Client Components

| Component Type | Characteristics |
|----------------|-----------------|
| Server (default) | `async`, can fetch data, no useState/useEffect, smaller bundles |
| Client (`'use client'`) | Interactivity, state, events, browser APIs |

## Decision Tree

```
Does this component need...
├─ useState, useEffect, event handlers?
│  └─ Client Component ('use client')
├─ Browser APIs (window, localStorage)?
│  └─ Client Component
├─ Only fetch and render data?
│  └─ Server Component (default)
└─ Both data fetching AND interactivity?
   └─ Split: Server wrapper + Client child
```

## Server/Client Split Pattern

```typescript
// page.tsx - Server Component (data fetching)
import { getData } from './actions';
import { PageClient } from './page.client';

export default async function Page() {
  const data = await getData();
  return <PageClient data={data} />;
}

// page.client.tsx - Client Component (interactivity)
'use client';
import { useState } from 'react';

export function PageClient({ data }: Props) {
  const [open, setOpen] = useState(false);
  // Interactive UI here
}
```

## Hooks and Early Returns

**All hooks must be called before any early returns.** React requires hooks to run in the same order on every render.

```typescript
// WRONG - hook after early return causes "Rendered more hooks" error
function PageClient({ data }) {
  const { isLoading } = useQuery({ ... });

  if (isLoading) {
    return <Skeleton />;  // Early return
  }

  useCustomHook();  // ❌ Only runs when !isLoading
}

// CORRECT - all hooks before early returns
function PageClient({ data }) {
  const { isLoading } = useQuery({ ... });
  useCustomHook();  // ✅ Always runs

  if (isLoading) {
    return <Skeleton />;
  }
}
```

**Why this matters:** When `isLoading` changes from `true` to `false`, React sees a different number of hooks, causing the error: "Rendered more hooks than during the previous render."

## Naming Conventions

| Pattern | Example |
|---------|---------|
| Server→Client wrapper pairs | `page.tsx` → `page.client.tsx` |
| Function naming | `DashboardPage` (server) → `DashboardPageClient` (client) |
| Standalone client components | `-form`, `-dialog`, `-modal` suffix |

## Server Actions

**Location:** `src/server/actions/` (or colocated `actions.ts`)

**Always:**
- Use `'use server'` directive at top of file
- Validate inputs with Zod before processing
- Return error states instead of throwing
- Sanitize errors before returning to client (see `patterns/security.md`)
- Revalidate paths after mutations

```typescript
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';

const createItemSchema = z.object({
  name: z.string().min(1).max(100),
});

export async function createItem(data: unknown) {
  const validation = createItemSchema.safeParse(data);
  if (!validation.success) {
    return { error: validation.error.errors[0].message };
  }

  const result = await doSomething(validation.data);

  if (!result.success) {
    // Log full details server-side, return generic message to client
    log.error('Action failed:', result.error);
    return { error: 'Failed to create item' };
  }

  revalidatePath('/affected-path');
  return { success: true };
}
```

## Data Fetching Strategy

| Approach | When to Use |
|----------|-------------|
| Server Components | Initial page data, SEO content |
| Server Actions | Mutations, form submissions, on-demand fetches |
| Client-side fetch | Real-time subscriptions, polling |
| Tanstack Query + Server Action | Polling, infinite scroll, optimistic updates |

## Route Groups

Use `(groupName)` folders for shared layouts without affecting URL:

```
app/
├── (marketing)/     # Landing pages, pricing
│   └── layout.tsx   # Header + Footer
├── (application)/   # Authenticated app
│   └── layout.tsx   # App shell + sidebar
└── auth/            # Auth pages (no group)
    └── layout.tsx   # Minimal layout
```

## Private Folders

Prefix with underscore (`_components/`) to:
- Opt out of routing
- Colocate with route
- Follow Next.js convention

## Middleware

Keep middleware lean. Handle:
- Auth redirects
- Session refresh
- Locale detection

Avoid heavy computation or database queries in middleware.

## Danger Zone

| Never | Consequence |
|-------|-------------|
| useState/useEffect in Server Component | Build error |
| Hooks after early returns (loading/error checks) | "Rendered more hooks" error |
| Call server action during SSR render | Cookie modification error |
| Heavy logic in middleware | Slow every request |
| Forget revalidatePath after mutation | Stale data shown |
| Return `error.message` to client in server actions | Leaks internal details (see `patterns/security.md`) |
