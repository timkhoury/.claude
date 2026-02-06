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

## Navigation-Aware Caching

TQ cache enables instant navigation between pages:

1. **First visit**: TQ fetches and caches data
2. **Navigation away**: Cache persists in memory
3. **Return visit**: Cached data displays instantly, refetch triggers in background
4. **Background refresh**: Data updates silently when refetch completes

**Key setting:** Use `staleTime: 0` to always refetch on mount while displaying cached data.

```typescript
useQuery({
  queryKey: queryKeys.items.all,
  queryFn: fetchItems,
  staleTime: 0, // Always refetch, show cached data while loading
});
```

**Note on `gcTime`:** Default is 5 minutes - inactive query data is garbage collected after 5 min. This is usually fine. Only increase if users might not visit a page for extended periods.

For this to work, data fetching must happen client-side through TQ.
Server-side data fetching (SSR, server components) bypasses the client-side TQ cache entirely.

## staleTime Recommendations

| Data Type | staleTime | Rationale |
|-----------|-----------|-----------|
| App pages (instant nav) | 0 | Always refetch, show cache while loading |
| Static/config | 30-60 min | Rarely changes |
| User profile | 5-10 min | Changes infrequently |
| Real-time/polling | 0 | Need latest always |

**Default for app pages:** Use `staleTime: 0` to ensure fresh data on every navigation. Cached data still displays instantly - the refetch happens silently in the background.

## Background Refresh UX

Background refetches should be **silent by default**. Spinners during refetch add visual noise without user benefit.

| Scenario | UX Pattern |
|----------|------------|
| Initial load | Show skeleton |
| Background refetch (success) | Silent - data just updates |
| Background refetch (error) | Silent if cached data exists |
| No cached data + error | Show error state |
| User-triggered refresh | Show indicator |

**Why silent?**
- If cached data is valid, users don't need to know about background activity
- Spinners create anxiety ("is something wrong?")
- Stale data (30 seconds old) is acceptable for dashboards, settings, etc.

**When to show indicators:**
- Real-time critical data (stock prices, live scores)
- User explicitly triggered refresh (pull-to-refresh)
- Long-running operations with uncertain completion

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
| High `staleTime` for app pages | Users see stale data after mutations on other pages |
| Forget `enabled` for conditional queries | Wasted requests |
