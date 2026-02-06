# Next.js + Tanstack Query Integration

> Next.js-specific patterns. See `tanstack-query.md` for core patterns (query keys, options, mutations).

## When to Use Each

| Use Case | Approach |
|----------|----------|
| Initial page load | Server Component |
| Refetch/polling/infinite scroll | Tanstack Query |
| Mutations | Server Actions |

**Rule:** Server Components for initial data. Query only when you need refetching.

## Hybrid Pattern (Server + Client) - initialData

Initial data from Server Component, refetching from Client:

```typescript
// page.tsx - Server Component
import { getData } from './actions';
import { PageClient } from './page.client';

export default async function Page() {
  const initialData = await getData();
  return <PageClient initialData={initialData} />;
}

// page.client.tsx - Client Component
'use client';

import { useQuery } from '@tanstack/react-query';
import { queryKeys } from '@/lib/query-keys';

export function PageClient({ initialData }) {
  const { data, isRefetching } = useQuery({
    queryKey: queryKeys.items.all,
    queryFn: getData,
    initialData, // No loading state on first render
    staleTime: 0, // Always refetch on mount, show cached data while loading
  });

  return <ItemList items={data} isRefetching={isRefetching} />;
}
```

## Client-Side Fetch for Instant Navigation

For authenticated app pages where instant navigation matters more than SSR SEO:

### The Problem
`loading.tsx` shows on every navigation because Server Components run async operations.
TQ cache is client-side only - servers can't access it. The `initialData` pattern
still triggers `loading.tsx` because the server fetches data on every request.

### The Solution
Move data fetching to Client Components. Server Components render shells only.

| Pattern | First Visit | Return Visit |
|---------|-------------|--------------|
| initialData (Server fetch) | Skeleton → Page | Skeleton → Page |
| Client fetch (TQ only) | Shell → TQ loading → Page | **Instant from cache** |

### Implementation

```typescript
// page.tsx - Server Component (NO data fetch)
export default async function Page() {
  const ctx = await requireAuthContext(); // Must be lightweight (e.g. cookie read, not DB lookup)
  return <PageClient organizationId={ctx.organization.id} />;
}

// page.client.tsx - Client Component (handles data)
export function PageClient({ organizationId }: Props) {
  const { data, isLoading, isRefetching } = useQuery({
    queryKey: queryKeys.items.all(organizationId),
    queryFn: fetchItems,
    staleTime: 0, // Always refetch on mount, show cached data while loading
  });

  if (isLoading) return <PageSkeleton />; // First visit only

  return <PageContent data={data} />;
}
```

### Why staleTime: 0?

With `staleTime: 0`, data is immediately considered stale:
- **Cached data displays instantly** on navigation (no loading skeleton)
- **Background refetch triggers** automatically
- **Data updates** when refetch completes

This ensures users always see the latest data while enjoying instant navigation.

### When to Use Each Pattern

| Use Case | Pattern |
|----------|---------|
| Public pages needing SEO | `initialData` (Server fetch) |
| Authenticated app pages | Client-side fetch (TQ only) |
| Real-time data | Client-side fetch with polling |

### Remove loading.tsx (when server component is lightweight)

If the server component has no slow async operations (auth is a fast cookie read, no DB queries), `loading.tsx` is redundant:
- Server Component resolves instantly, so the Suspense boundary never shows
- TQ handles loading states in client components
- Cache provides instant navigation on return visits

Keep `loading.tsx` if the server component does anything slow (DB lookups, external API calls) — without it, the user sees nothing until the server component resolves.

## Cache Invalidation

When external events (webhooks, polling, other tabs) change data, invalidation depends on which pattern you use:

**Client-side fetch (no initialData):** `invalidateQueries()` is sufficient.

```typescript
const queryClient = useQueryClient();
queryClient.invalidateQueries({ queryKey: queryKeys.items.all });
```

**initialData pattern (server + client):** invalidate both caches.

```typescript
const router = useRouter();
const queryClient = useQueryClient();

// 1. Invalidate TQ cache - makes queries refetch
queryClient.invalidateQueries({ queryKey: queryKeys.items.all });

// 2. Refresh server component data - updates initialData props
router.refresh();
```

`router.refresh()` alone: server props update, but TQ cache stays stale until `staleTime` expires. `invalidateQueries()` alone: TQ refetches, but server-rendered content stays stale.

## Prefetch on Hover

Pre-fetch query data when users hover over navigation links for instant page loads:

Note: this central map couples route strings to data logic. For larger apps, consider co-locating prefetch functions with route definitions to avoid drift.

```typescript
// lib/prefetch.ts - map routes to prefetch functions
type PrefetchFn = (queryClient: QueryClient, organizationId: string) => void;

const routePrefetchers: Record<string, PrefetchFn> = {
  '/dashboard': (qc, orgId) => {
    qc.prefetchQuery({
      queryKey: queryKeys.dashboard.summary(orgId),
      queryFn: () => getDashboardSummary(orgId),
    });
  },
};

export function prefetchRouteData(qc: QueryClient, route: string, orgId: string) {
  routePrefetchers[route]?.(qc, orgId);
}
```

```tsx
// components/navigation/prefetch-link.tsx
'use client';

type PrefetchLinkProps = ComponentProps<typeof Link> & { organizationId: string };

export function PrefetchLink({ href, organizationId, children, ...props }: PrefetchLinkProps) {
  const queryClient = useQueryClient();

  const handleMouseEnter = () => {
    if (organizationId && typeof href === 'string') {
      prefetchRouteData(queryClient, href, organizationId);
    }
  };

  return <Link href={href} onMouseEnter={handleMouseEnter} {...props}>{children}</Link>;
}
```

## Anti-Patterns

### Don't: useQuery for static data

```typescript
// Bad - Server Component is better
useQuery({ queryKey: ['user'], queryFn: getUser });

// Good - fetch once on server
export default async function Page() {
  const user = await getUser();
}
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Use Query when Server Component suffices | Extra complexity, larger bundle |
| Wrong pattern for use case | SEO pages need initialData; app pages benefit from client-only fetch |
| Forget hydration boundaries | Hydration mismatches |
| `router.refresh()` without `invalidateQueries()` | Tanstack Query shows stale data |
