# Tanstack Query Patterns

> Client-side data fetching with caching, polling, and optimistic updates.

## When to Use Tanstack Query

| Use Case | Approach |
|----------|----------|
| Initial page load | Server Component (not Query) |
| Refetch/polling | Tanstack Query |
| Infinite scroll | Tanstack Query |
| Optimistic updates | Tanstack Query |
| Background refresh | Tanstack Query |
| Mutations | Server Actions (or Query mutations) |

**Rule:** Use Server Components for initial data. Add Query only when you need refetching.

## Query Keys

Centralize query keys for type safety:

```typescript
// lib/query-keys.ts
export const queryKeys = {
  users: {
    all: ['users'] as const,
    detail: (id: string) => ['users', id] as const,
  },
  items: {
    all: ['items'] as const,
    list: (filters: Filters) => ['items', 'list', filters] as const,
  },
} as const;
```

```typescript
// Usage
import { queryKeys } from '@/lib/query-keys';

useQuery({
  queryKey: queryKeys.users.detail(userId),
  queryFn: () => getUser(userId),
});
```

**Never hardcode keys** - leads to typos and cache invalidation bugs.

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

## Polling Pattern

Poll until a condition is met:

```typescript
const { data } = useQuery({
  queryKey: queryKeys.status.check(id),
  queryFn: () => checkStatus(id),
  enabled: isPolling,
  refetchInterval: (query) => {
    if (query.state.data?.complete) return false; // Stop polling
    return 2000; // Poll every 2 seconds
  },
  staleTime: 0, // Always fetch fresh
});
```

## Common Options

| Option | Purpose |
|--------|---------|
| `staleTime` | How long data stays fresh (default: 0) |
| `gcTime` | How long inactive data stays in cache (default: 5min) |
| `refetchInterval` | Auto-refetch interval (false to disable) |
| `enabled` | Conditional fetching |
| `initialData` | SSR/hydration data |
| `placeholderData` | Shown while loading (keeps previous data) |

## Mutations

```typescript
const mutation = useMutation({
  mutationFn: createItem,
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: queryKeys.items.all });
  },
});
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

### Don't: useState + useEffect for fetching

```typescript
// Bad
useEffect(() => { fetch('/api').then(setData) }, []);

// Good - use Server Component or Query
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Hardcode query keys | Cache invalidation bugs |
| Skip `staleTime` for stable data | Unnecessary refetches |
| Forget `enabled` for conditional queries | Wasted requests |
| Use Query when Server Component suffices | Extra complexity |
