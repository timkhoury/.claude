# Rules Review Patterns

## Cross-Technology Red Flags

Content that indicates a rule should be split:

| Red Flag | Example | Should Be |
|----------|---------|-----------|
| "Use Server Component instead of X" | Tanstack Query mentioning Next.js RSC | `nextjs-tanstack-query.md` |
| Framework-specific imports in examples | Supabase examples with Next.js cookies | `nextjs-supabase.md` |
| "When using X with Y" sections | Testing patterns for Supabase | `supabase-testing.md` |
| Middleware/context-specific patterns | Supabase client selection by context | `nextjs-supabase.md` |

## Common Violations

| Violation | Often Found In | Fix |
|-----------|----------------|-----|
| "Use Server Component instead" | Data fetching libs | Extract to `nextjs-{lib}.md` |
| Cookie/middleware patterns | Auth/database libs | Extract to `nextjs-{lib}.md` |
| Component library specifics | CSS framework rules | Extract to `{css}-{component}.md` |
| Test setup with real DB | Database rules | Extract to `{db}-testing.md` |

## Signs of Misplaced Project Content

| Found In | Red Flag | Move To |
|----------|----------|---------|
| `tech/*.md` | References to "our database schema" | `project/architecture.md` |
| `patterns/*.md` | "In this project we..." | `project/overview.md` |
| `meta/*.md` | Project URLs, credentials | `project/environment.md` |

## Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Pure technology | `{technology}.md` | `react.md`, `postgres.md` |
| Integration | `{tech-a}-{tech-b}.md` | `react-redux.md`, `express-postgres.md` |
