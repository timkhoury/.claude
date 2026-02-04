# Next.js + Tanstack Query Integration

> Next.js-specific patterns. See `tanstack-query.md` for core patterns (query keys, options, mutations).

## When to Use Each

| Use Case | Approach |
|----------|----------|
| Initial page load | Server Component |
| Refetch/polling/infinite scroll | Tanstack Query |
| Mutations | Server Actions |

**Rule:** Server Components for initial data. Query only when you need refetching.

## Hybrid Pattern (Server + Client)

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
| Skip `initialData` when SSR data available | Unnecessary loading states |
| Forget hydration boundaries | Hydration mismatches |
| `router.refresh()` without `invalidateQueries()` | Tanstack Query shows stale data |
