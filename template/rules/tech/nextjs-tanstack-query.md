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
    staleTime: 2 * 60 * 1000, // 2 minutes
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
  const ctx = await requireAuthContext(); // Fast - cookie read only
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

  return (
    <>
      <RefetchIndicator isRefetching={isRefetching} />
      <PageContent data={data} />
    </>
  );
}
```

### Why staleTime: 0?

With `staleTime: 0`, data is immediately considered stale:
- **Cached data displays instantly** on navigation (no loading skeleton)
- **Background refetch triggers** automatically (`isRefetching = true`)
- **Spinner shows** while fresh data loads
- **Data updates** when refetch completes

This ensures users always see the latest data while enjoying instant navigation.

### When to Use Each Pattern

| Use Case | Pattern |
|----------|---------|
| Public pages needing SEO | `initialData` (Server fetch) |
| Authenticated app pages | Client-side fetch (TQ only) |
| Real-time data | Client-side fetch with polling |

### Remove loading.tsx

With client-side fetch, `loading.tsx` is redundant:
- Server Component completes instantly (no async data fetch)
- TQ handles loading states in client components
- Cache provides instant navigation on return visits

## Cache Invalidation with router.refresh()

When external events (webhooks, polling, other tabs) change server data, you must invalidate BOTH caches:

```typescript
// After detecting data changed (e.g., webhook processed, polling success)
const router = useRouter();
const queryClient = useQueryClient();

// 1. Invalidate Tanstack Query cache - makes queries refetch
queryClient.invalidateQueries({ queryKey: queryKeys.items.all });

// 2. Refresh server component data - updates initialData props
router.refresh();
```

**Why both?**
- `router.refresh()` alone: Server props update, but TQ cache stays stale until `staleTime` expires
- `invalidateQueries()` alone: TQ refetches, but server-rendered content stays stale

## Prefetch on Hover

Pre-fetch query data when users hover over navigation links for instant page loads:

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

export function PrefetchLink({ href, organizationId, children, ...props }) {
  const queryClient = useQueryClient();

  const handleMouseEnter = () => {
    if (organizationId && typeof href === 'string') {
      prefetchRouteData(queryClient, href, organizationId);
    }
  };

  return <Link href={href} onMouseEnter={handleMouseEnter} {...props}>{children}</Link>;
}
```

## Refetch Indicators

Show subtle feedback during background data refresh:

```tsx
export function RefetchIndicator({ isRefetching }: { isRefetching: boolean }) {
  if (!isRefetching) return null;
  return <Loader2 className="size-4 animate-spin text-muted-text" aria-label="Refreshing" />;
}

// Usage in page headers
const { data, isRefetching } = useQuery({ ... });

<div className="flex items-center gap-2">
  <h1>Page Title</h1>
  <RefetchIndicator isRefetching={isRefetching} />
</div>
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
