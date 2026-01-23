# Next.js + Tanstack Query Integration

> When and how to use Tanstack Query with Next.js App Router.

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
