# Tanstack Query Patterns

> Client-side data fetching with caching, polling, and optimistic updates.

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

## Common Options

| Option | Purpose |
|--------|---------|
| `staleTime` | How long data stays fresh (default: 0) |
| `gcTime` | How long inactive data stays in cache (default: 5min) |
| `refetchInterval` | Auto-refetch interval (false to disable) |
| `enabled` | Conditional fetching |
| `initialData` | SSR/hydration data |
| `placeholderData` | Shown while loading (keeps previous data) |

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

### Don't: useState + useEffect for fetching

```typescript
// Bad
useEffect(() => { fetch('/api').then(setData) }, []);

// Good - use Tanstack Query
const { data } = useQuery({
  queryKey: queryKeys.items.all,
  queryFn: fetchItems,
});
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Hardcode query keys | Cache invalidation bugs |
| Skip `staleTime` for stable data | Unnecessary refetches |
| Forget `enabled` for conditional queries | Wasted requests |
