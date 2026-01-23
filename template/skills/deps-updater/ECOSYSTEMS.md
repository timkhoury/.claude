# Package Ecosystems Reference

Framework packages come in groups that should be updated together.

## JavaScript/TypeScript Ecosystems

| Ecosystem | Packages | Notes |
|-----------|----------|-------|
| **Next.js** | `next`, `eslint-config-next` | Must match major versions |
| **React** | `react`, `react-dom`, `@types/react`, `@types/react-dom` | Always update together |
| **Vitest/Vite** | `vitest`, `@vitest/ui`, `@vitejs/plugin-react`, `vite` | Share major versions |
| **Supabase** | `@supabase/supabase-js`, `@supabase/ssr`, `supabase` (CLI) | Check compatibility matrix |
| **Tailwind** | `tailwindcss`, `@tailwindcss/*`, `prettier-plugin-tailwindcss` | PostCSS plugins must match |
| **Tanstack Query** | `@tanstack/react-query`, `@tanstack/react-query-devtools` | Always update together |
| **Stripe** | `stripe`, `@stripe/stripe-js`, `@stripe/react-stripe-js` | Server and client SDKs |
| **Testing Library** | `@testing-library/react`, `@testing-library/jest-dom`, `@testing-library/user-event` | Framework adapters |
| **Radix UI** | All `@radix-ui/*` packages | Usually safe to update individually |
| **Playwright** | `@playwright/test`, `playwright` | Single package typically |
| **ESLint** | `eslint`, `eslint-config-*`, `eslint-plugin-*` | Config must support ESLint version |
| **TypeScript** | `typescript`, `@types/node` | Types should match Node target |

## Rust Ecosystems

| Ecosystem | Packages | Notes |
|-----------|----------|-------|
| **Tokio** | `tokio`, `tokio-*` | Runtime and extensions |
| **Serde** | `serde`, `serde_json`, `serde_*` | Serialization family |
| **Axum/Tower** | `axum`, `tower`, `tower-http` | Web framework stack |

## Python Ecosystems

| Ecosystem | Packages | Notes |
|-----------|----------|-------|
| **FastAPI** | `fastapi`, `uvicorn`, `starlette` | ASGI stack |
| **Django** | `django`, `django-*` | Framework and extensions |
| **SQLAlchemy** | `sqlalchemy`, `alembic` | ORM and migrations |

## Ecosystem-Specific Research Tips

| Ecosystem | What to Check | Commands |
|-----------|---------------|----------|
| Next.js | eslint-config-next matching major | `npm info next@{ver} peerDependencies` |
| React | @types/react matches react version | `npm info react@{ver} peerDependencies` |
| Vitest | vite compatibility | `npm info vitest@{ver} peerDependencies` |
| Supabase | @supabase/ssr and supabase-js matrix | `npm info @supabase/ssr@{ver} peerDependencies` |
| Stripe | Server and client SDK API versions | Check both packages |
| Tailwind | PostCSS plugin compatibility | `npm info tailwindcss@{ver} peerDependencies` |
| TypeScript | @types/node matches Node target | `npm info typescript@{ver} engines` |

## Cross-Ecosystem Checks

When upgrading affects multiple ecosystems:

```bash
# Check if dependent packages support new versions
npm info @tanstack/react-query peerDependencies
npm info @testing-library/react peerDependencies
npm info @radix-ui/react-dialog peerDependencies
```
