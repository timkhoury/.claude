# Security Audit Checklist

Detailed search patterns for each audit category. Agents use these to systematically find vulnerabilities.

## Auth & Access Control (A01, A07)

### Search Patterns

| Pattern | Looking For |
|---------|------------|
| Server actions without auth checks | Functions missing `getCurrentUser`/`getUser`/auth verification before mutations |
| Role verification gaps | Mutations that check auth but not role (owner/admin) before sensitive operations |
| IDOR vulnerabilities | Functions that take an entity ID and don't verify the caller owns/can access it |
| Session management | Missing session invalidation on password change, sign-out not clearing all tokens |
| MFA bypass | Sensitive operations not checking AAL2 when MFA is enabled |
| Cookie configuration | Missing httpOnly, secure, sameSite attributes |
| Auth header spoofing | Middleware not clearing incoming auth headers before setting them |

### Files to Check

- Server actions (`server/actions/`, `app/**/actions.ts`)
- Middleware (`middleware.ts`)
- Auth utilities (`lib/auth*`)
- API routes (`app/api/**`)

## Injection & Input Validation (A03, A04)

### Search Patterns

| Pattern | Looking For |
|---------|------------|
| Raw SQL queries | String interpolation in SQL, missing parameterized queries |
| Missing Zod/schema validation | Server actions accepting raw input without validation |
| Unsafe HTML rendering | React's dangerous innerHTML prop, unescaped user input in templates |
| URL construction from user input | Redirects, fetches, or links built from query params without validation |
| Command injection | User input passed to `exec`, `spawn`, or shell commands |
| Regex DoS | Complex regex patterns on user-controlled input |

### Files to Check

- Server actions (all)
- API routes (all)
- Components rendering user-generated content
- Database queries and migrations

## Data Exposure (A09)

### Search Patterns

| Pattern | Looking For |
|---------|------------|
| Verbose error messages | Supabase/DB errors returned directly to client |
| Console.log with sensitive data | Logging tokens, passwords, keys, PII |
| API response over-fetching | `select('*')` returning sensitive columns to client |
| Error messages enabling enumeration | "User already registered", "Email not found" patterns |
| Source maps in production | Config enabling source maps in prod builds |
| Sensitive data in URL params | Tokens, keys, or PII in query strings (logged by default) |

### Files to Check

- Server actions (error handling paths)
- API routes (error responses)
- Client components (error display)
- Logging utilities

## Security Headers & Config (A05)

### Search Patterns

| Pattern | Looking For |
|---------|------------|
| Missing security headers | No CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy |
| Permissive CORS | `Access-Control-Allow-Origin: *` or overly broad origins |
| Missing env var validation | Required secrets not validated at startup |
| Debug mode in production | Development flags, verbose logging enabled unconditionally |
| Exposed internal endpoints | Internal APIs accessible without authentication |

### Files to Check

- Next.js/framework config (`next.config.*`, `vite.config.*`)
- Middleware (CORS, headers)
- Environment configuration
- API route handlers

## Database Security (Supabase/PostgreSQL)

### Search Patterns

| Pattern | Looking For |
|---------|------------|
| Tables without RLS | `ENABLE ROW LEVEL SECURITY` missing |
| SECURITY DEFINER without auth.uid() check | Functions that accept user IDs without verifying caller identity |
| Overly permissive GRANTs | `GRANT ALL` to `anon` on sensitive tables |
| Missing soft-delete filters | RLS policies not filtering `deleted_at IS NULL` |
| RLS policy/app logic mismatch | App allows action but RLS blocks (or vice versa) |
| Missing FK constraints | Data integrity gaps |
| Admin client misuse | Admin client used where regular client should be (bypassing RLS unnecessarily) |

### Files to Check

- Migration files (`supabase/migrations/`)
- Database type definitions
- Admin client usage (`createAdminClient`)

## Webhook & API Security (A08)

### Search Patterns

| Pattern | Looking For |
|---------|------------|
| Missing signature verification | Webhook handlers not verifying request authenticity |
| Non-timing-safe comparisons | Using `===` instead of `timingSafeEqual` for secrets |
| Missing idempotency guards | Webhooks processed multiple times on retry |
| Error swallowing | Returning 200 on processing errors (prevents retry) |
| Missing rate limiting | Endpoints without throttling |
| Shared secrets in request body | Secrets should be in Authorization header, not body |

### Files to Check

- Webhook handlers (`app/api/webhooks/**`)
- Internal API endpoints (`app/api/internal/**`)
- Authentication middleware for API routes

## Cryptographic Practices (A02)

### Search Patterns

| Pattern | Looking For |
|---------|------------|
| Plaintext token storage | OAuth tokens, API keys stored unencrypted |
| Weak hashing | MD5/SHA1 for passwords, missing salt |
| Hardcoded secrets | API keys, passwords in source code |
| Insecure randomness | `Math.random()` for security-sensitive operations |
| Missing key rotation | No mechanism to rotate secrets |

### Files to Check

- Token/key storage modules
- Authentication utilities
- Environment configuration
- Database columns storing secrets

## Dependencies (A06)

### Commands to Run

| Tool | Command |
|------|---------|
| npm | `npm audit --json` |
| pip | `pip-audit` or `safety check` |
| cargo | `cargo audit` |
| go | `govulncheck ./...` |

Report: total vulnerabilities, critical/high count, any with known exploits.
