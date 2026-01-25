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
- Return error states instead of throwing
- Revalidate paths after mutations

```typescript
'use server';

import { revalidatePath } from 'next/cache';

export async function myAction(data: FormData) {
  // Perform mutation
  const result = await doSomething(data);

  if (!result.success) {
    return { error: result.message };
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
| Call server action during SSR render | Cookie modification error |
| Heavy logic in middleware | Slow every request |
| Forget revalidatePath after mutation | Stale data shown |
