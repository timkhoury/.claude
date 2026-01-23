# Component Organization

> Colocate components with their routes. Only globalize if reused.

## Core Principle

Components should live as close as possible to where they're used. This reduces context switching and keeps related logic together.

## Decision Tree

```
Where should my component go?

├─ Used by ONE page only?
│  └─ app/{route}/_components/
│
├─ Used by SIBLING routes (same parent)?
│  └─ app/{parent}/_components/
│
├─ Used across MULTIPLE features?
│  └─ components/shared/
│
└─ Reusable UI primitive?
   └─ components/ui/
```

## Folder Structure (Next.js App Router)

```
src/
├── app/
│   ├── (group)/
│   │   ├── route-a/
│   │   │   ├── page.tsx              # Server Component
│   │   │   ├── page.client.tsx       # Client Component
│   │   │   └── _components/          # Route-specific components
│   │   └── route-b/
│   │       ├── _components/          # Shared across route-b pages
│   │       ├── sub-route/
│   │       │   ├── page.tsx
│   │       │   └── _components/      # Sub-route specific
│
├── components/
│   ├── ui/                           # UI primitives (shadcn/ui)
│   └── shared/                       # Cross-feature components
│
└── lib/                              # Utilities, helpers
```

## Private Folders (`_components/`)

Prefix with underscore to opt out of routing:
- Prevents accidental route creation
- Improves editor file sorting (groups with parent)
- Follows Next.js convention for private implementation details

## When to Colocate vs Globalize

| Situation | Location |
|-----------|----------|
| Form only on one page | `app/{route}/_components/` |
| Buttons shared across auth pages | `app/auth/_components/` |
| Header used by many pages | `components/shared/` |
| Button, Card, Input | `components/ui/` |

## Colocated Files

Beyond components, colocate related logic:

| File | Purpose | When to Globalize |
|------|---------|-------------------|
| `schema.ts` | Zod validation | When reused across routes |
| `actions.ts` | Server actions | When shared between features |
| `hooks.ts` | Route-specific hooks | When reused elsewhere |
| `types.ts` | Route-specific types | When shared |

## Benefits

- **Reduced context switching** - work entirely within one folder
- **Better discoverability** - find related code together
- **Prevents bloat** - global `components/` stays lean
- **Clear ownership** - each route owns its UI
- **Parallel development** - teams work in isolated folders

## Reference

Based on [Next.js Colocation Template](https://next-colocation-template.vercel.app/) patterns.
