---
name: deps-update
description: >
  Update dependencies and audit for security issues across any language/package manager.
  Use when user says "update deps", "upgrade dependencies", "security audit",
  "check for updates", "update packages", or "npm audit" / "cargo update" etc.
---

# Dependency Update Guide

Audit security vulnerabilities and guide through dependency updates with migration research.

## Critical Rules

1. **Security first** - Always run security audit before updates
2. **Ecosystem awareness** - Group related packages and update them together
3. **Analyze transitive dependencies** - Before major upgrades, check peer/regular dependencies of the target version
4. **Detect cascading upgrades** - If a transitive dep needs upgrading, check if that triggers more upgrades
5. **Research major updates** - Use WebSearch for breaking changes and migration guides
6. **Present choices** - Use AskUserQuestion to let user select which updates to apply
7. **One ecosystem at a time** - Update major versions by ecosystem with testing between
8. **Commit incrementally** - Separate commits for security fixes, major updates, minor/patch updates

## Phase 1: Detect Package Manager

Check for these files to identify the project's package manager(s):

| File | Package Manager | Language |
|------|-----------------|----------|
| `package.json` | npm/pnpm/yarn/bun | JavaScript/TypeScript |
| `Cargo.toml` | cargo | Rust |
| `go.mod` | go mod | Go |
| `requirements.txt` | pip | Python |
| `pyproject.toml` | pip/poetry/uv | Python |
| `Gemfile` | bundler | Ruby |
| `composer.json` | composer | PHP |
| `build.gradle` / `pom.xml` | gradle/maven | Java |
| `Package.swift` | swift | Swift |
| `pubspec.yaml` | pub | Dart/Flutter |

A project may have multiple package managers. Process each one.

## Phase 2: Identify Package Ecosystems

Framework packages come in groups that should be updated together. Identify these ecosystems before proceeding.

### Common JavaScript/TypeScript Ecosystems

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

### Common Rust Ecosystems

| Ecosystem | Packages | Notes |
|-----------|----------|-------|
| **Tokio** | `tokio`, `tokio-*` | Runtime and extensions |
| **Serde** | `serde`, `serde_json`, `serde_*` | Serialization family |
| **Axum/Tower** | `axum`, `tower`, `tower-http` | Web framework stack |

### Common Python Ecosystems

| Ecosystem | Packages | Notes |
|-----------|----------|-------|
| **FastAPI** | `fastapi`, `uvicorn`, `starlette` | ASGI stack |
| **Django** | `django`, `django-*` | Framework and extensions |
| **SQLAlchemy** | `sqlalchemy`, `alembic` | ORM and migrations |

### Detecting Ecosystems

When analyzing `npm outdated` output:

1. **Group by ecosystem** - Cluster related packages together
2. **Flag partial updates** - Warn if only some packages in an ecosystem have updates
3. **Check peer dependencies** - Use `npm ls {package}` to verify compatibility
4. **Identify orphaned packages** - Packages not in any ecosystem can be updated independently

### Ecosystem Analysis Output Format

Present findings grouped by ecosystem:

```markdown
## Package Ecosystems

| Ecosystem | Packages | Current | Latest | Update Type |
|-----------|----------|---------|--------|-------------|
| React | react, react-dom, @types/react, @types/react-dom | 18.2.x | 18.3.x | Minor |
| Next.js | next, eslint-config-next | 14.x | 15.x | Major |
| Vitest | vitest, @vitest/ui, @vitejs/plugin-react | 1.x | 2.x | Major |

### Standalone Packages (no ecosystem)
| Package | Current | Latest | Update Type |
|---------|---------|--------|-------------|
| date-fns | 2.30.0 | 3.0.0 | Major |
```

### Partial Update Warnings

If some packages in an ecosystem have updates but others don't, or versions would mismatch:

```markdown
⚠️ **Partial ecosystem update detected:**
- `@tanstack/react-query` has update 5.50.0 → 5.51.0
- `@tanstack/react-query-devtools` is at 5.50.0 (no update shown)
- **Recommendation:** Update both to 5.51.0 together
```

## Phase 3: Security Audit

Run the appropriate audit command:

| Package Manager | Audit Command |
|-----------------|---------------|
| npm | `npm audit` |
| pnpm | `pnpm audit` |
| yarn | `yarn audit` |
| bun | `bun pm audit` (if available) or check npm audit |
| cargo | `cargo audit` (requires cargo-audit) |
| pip | `pip-audit` or `safety check` |
| bundler | `bundle audit` |
| composer | `composer audit` |
| go | `govulncheck ./...` |

### Security Audit Output

Present findings in this format:

```
## Security Audit Results

| Severity | Package | Vulnerability | Fix Available |
|----------|---------|---------------|---------------|
| Critical | lodash | Prototype Pollution (CVE-XXX) | 4.17.21 |
| High | axios | SSRF (CVE-YYY) | 1.6.0 |
```

**If critical/high vulnerabilities exist:** Recommend immediate update before proceeding.

## Phase 4: Check for Updates

Run the appropriate outdated command:

| Package Manager | Outdated Command |
|-----------------|------------------|
| npm | `npm outdated` |
| pnpm | `pnpm outdated` |
| yarn | `yarn outdated` |
| bun | `bun outdated` |
| cargo | `cargo outdated` (requires cargo-outdated) |
| pip | `pip list --outdated` |
| bundler | `bundle outdated` |
| composer | `composer outdated` |
| go | `go list -u -m all` |

### Categorize Updates

Group updates by type AND ecosystem:

| Category | Definition | Risk Level |
|----------|------------|------------|
| Security | Fixes known vulnerabilities | Apply immediately |
| Major | Breaking changes (e.g., 1.x → 2.x) | Research required |
| Minor | New features, backwards compatible | Low risk |
| Patch | Bug fixes only | Minimal risk |

After categorizing, group packages by their ecosystem (from Phase 2) and present as:

```markdown
## Ecosystem Updates Summary

### Major Updates (research required)
| Ecosystem | Packages | Current | Latest |
|-----------|----------|---------|--------|
| Next.js | next, eslint-config-next | 15.x | 16.x |
| Vitest | vitest, @vitest/ui | 3.x | 4.x |

### Minor/Patch Updates (low risk)
| Ecosystem | Packages | Current | Latest |
|-----------|----------|---------|--------|
| React | react, react-dom | 19.1.x | 19.2.x |
| Tailwind | tailwindcss, @tailwindcss/postcss | 4.1.14 | 4.1.18 |

### Standalone Updates
| Package | Current | Latest | Type |
|---------|---------|--------|------|
| date-fns | 3.6.0 | 4.1.0 | Major |
| clsx | 2.1.0 | 2.1.1 | Patch |
```

## Phase 5: Research Major Updates

**For each ecosystem with major updates**, perform dependency analysis and web research.

### Step 1: Analyze Transitive Dependencies

Before researching online, check what the new version requires:

```bash
# Check peer dependencies of the target version
npm info {package}@{target_version} peerDependencies

# Check regular dependencies
npm info {package}@{target_version} dependencies

# Check what version ranges are acceptable
npm info {package}@{target_version} peerDependenciesMeta
```

**For each peer/regular dependency found:**

1. **Check if it's installed** - Is this dependency in our package.json?
2. **Check version compatibility** - Does our installed version satisfy the new requirement?
3. **Check if it needs upgrading** - If not compatible, what version do we need?
4. **Check cascading requirements** - Does upgrading that dependency trigger more upgrades?

### Transitive Dependency Analysis Format

```markdown
### {Package}: Dependency Requirements for v{version}

**Peer Dependencies:**
| Dependency | Required | Installed | Status |
|------------|----------|-----------|--------|
| react | ^19.0.0 | 18.2.0 | ⚠️ Upgrade needed |
| react-dom | ^19.0.0 | 18.2.0 | ⚠️ Upgrade needed |

**Regular Dependencies (bundled, but check for conflicts):**
| Dependency | Version | Notes |
|------------|---------|-------|
| scheduler | 0.25.0 | Internal, no action needed |

**Cascading Upgrades Required:**
- Upgrading to `next@16` requires `react@19`
- `react@19` is compatible with current `@types/react` (check: `npm info @types/react peerDependencies`)
- No further cascading upgrades detected

**Blockers:** None / List any blocking issues
```

### Detecting Cascading Upgrades

When a transitive dependency also needs a major upgrade:

```bash
# Check if the required dependency version supports our other packages
npm info {required_dep}@{required_version} peerDependencies

# Example: next@16 requires react@19, check if react@19 works with our other react-dependent packages
npm info @tanstack/react-query peerDependencies  # Does it support react@19?
```

**Flag blockers when:**
- A required dependency version doesn't exist yet
- A required dependency conflicts with another package's requirements
- Upgrading one package forces incompatible upgrades elsewhere

### Step 2: Web Research

Use WebSearch to find:

1. **Changelog/Release notes** - Search: `{primary_package} {version} changelog`
2. **Migration guide** - Search: `{primary_package} migrate {old_version} to {new_version}`
3. **Breaking changes** - Search: `{primary_package} {version} breaking changes`
4. **Ecosystem compatibility** - Search: `{package_a} {package_b} compatibility {version}`

### Research Summary Format

For each ecosystem major update, document:

```markdown
### {Ecosystem}: {old_version} → {new_version}

**Packages:** {list of packages in ecosystem}

**Transitive Dependency Analysis:**
| Dependency | Required | Installed | Action |
|------------|----------|-----------|--------|
| react | ^19.0.0 | 19.0.0 | ✅ Compatible |
| typescript | ^5.0.0 | 5.3.0 | ✅ Compatible |
| node | >=18.17.0 | 20.x | ✅ Compatible |

**Cascading Upgrades:** None required / List packages that must also upgrade

**Breaking Changes:**
- List key breaking changes affecting this ecosystem

**Migration Steps:**
1. Step-by-step migration instructions
2. Include any ecosystem-specific coordination steps
3. Include cascading upgrade steps if applicable

**Blockers:** None / List any blocking dependency conflicts

**Effort Estimate:** Low / Medium / High

**Sources:**
- [Changelog](url)
- [Migration Guide](url)
```

### Ecosystem-Specific Research Tips

| Ecosystem | What to Check | Transitive Dependency Commands |
|-----------|---------------|-------------------------------|
| Next.js | Check if eslint-config-next has matching major release | `npm info next@{ver} peerDependencies` - check react version requirement |
| React | Verify @types/react matches react version | `npm info react@{ver} peerDependencies` - usually none, but check scheduler |
| Vitest | Check vite compatibility, @vitejs/plugin-react compatibility | `npm info vitest@{ver} peerDependencies` - check vite version requirement |
| Supabase | Check @supabase/ssr and @supabase/supabase-js compatibility matrix | `npm info @supabase/ssr@{ver} peerDependencies` - check supabase-js requirement |
| Stripe | Verify server SDK (stripe) and client SDK (@stripe/stripe-js) are compatible | Check both packages have compatible API versions |
| Tailwind | Check PostCSS plugin compatibility | `npm info tailwindcss@{ver} peerDependencies` - check postcss version |
| TypeScript | Check @types/node matches Node.js target | `npm info typescript@{ver} engines` - check node requirement |

### Cross-Ecosystem Dependency Checks

When upgrading affects multiple ecosystems, verify compatibility:

```bash
# Example: Upgrading React affects many packages
# Check if Tanstack Query supports the new React version
npm info @tanstack/react-query peerDependencies

# Check if Testing Library supports the new React version
npm info @testing-library/react peerDependencies

# Check if Radix UI components support the new React version
npm info @radix-ui/react-dialog peerDependencies
```

**Present cross-ecosystem conflicts clearly:**

```markdown
⚠️ **Cross-Ecosystem Dependency Conflict:**
- `next@16` requires `react@^19.0.0`
- `@tanstack/react-query@5.50.0` requires `react@^18.0.0`
- **Resolution:** Upgrade @tanstack/react-query to 5.60.0+ (supports React 19)
```

## Phase 6: Present Update Plan

Use AskUserQuestion to present ecosystem-aware choices:

```
Which updates would you like to apply?
```

**Standard Options:**
1. **Security fixes only** - Apply all security patches (recommended first)
2. **Security + minor/patch ecosystems** - Low-risk ecosystem updates
3. **All updates including major ecosystems** - Full update with migration
4. **Select specific ecosystems** - Choose which ecosystems to update

**When "Select specific ecosystems" is chosen**, present a follow-up question:

```
Which ecosystems would you like to update?
```

Options (example based on detected ecosystems):
- React ecosystem (minor: 19.1.x → 19.2.x)
- Next.js ecosystem (major: 15.x → 16.x)
- Vitest ecosystem (major: 3.x → 4.x)
- Tailwind ecosystem (patch: 4.1.14 → 4.1.18)
- Standalone packages (mixed)

**Important:** When an ecosystem is selected, ALL packages in that ecosystem are updated together.

## Phase 7: Apply Updates

### Security Fixes

```bash
# npm
npm audit fix

# pnpm
pnpm audit --fix

# cargo
cargo update  # Then manually update vulnerable crates

# pip
pip install --upgrade {package}=={safe_version}
```

### Minor/Patch Updates

```bash
# npm - update within semver range
npm update

# npm - update to latest minor (use npm-check-updates)
npx npm-check-updates -u --target minor
npm install

# cargo
cargo update

# pip
pip install --upgrade {packages}
```

### Ecosystem Updates (minor/patch)

Update all packages in an ecosystem together:

```bash
# Example: Update React ecosystem
npm install react@latest react-dom@latest @types/react@latest @types/react-dom@latest

# Example: Update Tailwind ecosystem
npm install tailwindcss@latest @tailwindcss/postcss@latest prettier-plugin-tailwindcss@latest
```

### Major Ecosystem Updates (one ecosystem at a time)

For each ecosystem with major updates:

1. **Update all packages in the ecosystem together**
   ```bash
   # Example: Vitest ecosystem major update
   npm install vitest@latest @vitest/ui@latest @vitejs/plugin-react@latest
   ```
2. **Run the build** - Ensure project compiles
3. **Run tests** - Catch regressions
4. **Fix any breaking changes** - Apply migration steps from research
5. **Commit with message:** `chore(deps): upgrade {ecosystem} to v{version}`
6. **Proceed to next ecosystem**

**Never update packages from different major-version ecosystems in the same commit.** This makes rollback easier if issues are discovered.

## Phase 8: Verify and Commit

After applying updates:

1. **Run build** - Ensure project compiles
2. **Run tests** - Catch regressions
3. **Run lint** - Check for deprecation warnings
4. **Commit changes** - Use conventional commit format

### Commit Message Format

| Update Type | Commit Message |
|-------------|----------------|
| Security | `fix(deps): security patches for {packages}` |
| Major ecosystem | `chore(deps): upgrade {ecosystem} to v{version}` |
| Minor/Patch ecosystems | `chore(deps): update {ecosystem} dependencies` |
| Mixed minor/patch | `chore(deps): update dependencies` |

**Examples:**
- `fix(deps): security patches for next, undici, tar`
- `chore(deps): upgrade vitest ecosystem to v4`
- `chore(deps): update react ecosystem dependencies`
- `chore(deps): update tailwind, radix-ui dependencies`

## Handling Common Issues

### Peer Dependency Conflicts (npm)

```bash
# See what's conflicting
npm ls {package}

# Force install (use with caution)
npm install --legacy-peer-deps
```

### Lock File Conflicts

```bash
# npm - regenerate lock file
rm package-lock.json && npm install

# pnpm
rm pnpm-lock.yaml && pnpm install
```

### Breaking Type Changes (TypeScript)

Search for updated type definitions:
```bash
npm outdated @types/*
```

## Interactive Workflow Example

```
User: update deps

Claude: I'll check your dependencies. Let me start with a security audit.
[Runs npm audit]

Claude: Found 2 vulnerabilities:
| Severity | Package | Fix |
|----------|---------|-----|
| High | next | 15.5.9 |
| Moderate | js-yaml | npm audit fix |

Now checking for outdated packages and grouping by ecosystem...
[Runs npm outdated]

## Ecosystem Updates Summary

### Major Updates (research required)
| Ecosystem | Packages | Current | Latest |
|-----------|----------|---------|--------|
| Next.js | next, eslint-config-next | 15.x | 16.x |
| Vitest | vitest, @vitest/ui, @vitejs/plugin-react | 3.x | 4.x |
| Zod | zod | 3.x | 4.x |

### Minor/Patch Updates (low risk)
| Ecosystem | Packages | Current | Latest |
|-----------|----------|---------|--------|
| React | react, react-dom, @types/react, @types/react-dom | 19.1.x | 19.2.x |
| Tailwind | tailwindcss, @tailwindcss/postcss | 4.1.14 | 4.1.18 |
| Tanstack Query | @tanstack/react-query, @tanstack/react-query-devtools | 5.90.x | 5.91.x |

### Standalone Updates
| Package | Current | Latest | Type |
|---------|---------|--------|------|
| motion | 12.23.x | 12.27.x | Minor |
| lucide-react | 0.544.0 | 0.562.0 | Minor |

Let me analyze transitive dependencies for major updates...
[Runs npm info next@16 peerDependencies]
[Runs npm info vitest@4 peerDependencies]
[Runs npm info zod@4 peerDependencies]

### Transitive Dependency Analysis

**next@16 requires:**
| Dependency | Required | Installed | Status |
|------------|----------|-----------|--------|
| react | ^19.0.0 | 19.0.0 | ✅ Compatible |
| react-dom | ^19.0.0 | 19.0.0 | ✅ Compatible |

**vitest@4 requires:**
| Dependency | Required | Installed | Status |
|------------|----------|-----------|--------|
| vite | ^6.0.0 | 5.4.0 | ⚠️ Upgrade needed |

**Cascading check:** Does vite@6 affect other packages?
[Runs npm info @vitejs/plugin-react peerDependencies]
- @vitejs/plugin-react needs update to support vite@6

Now researching breaking changes...
[WebSearch for Next.js 16 migration, Vitest 4 migration, Zod 4 migration]

### Next.js Ecosystem: 15.x → 16.x
**Packages:** next, eslint-config-next

**Transitive Dependency Analysis:**
| Dependency | Required | Installed | Action |
|------------|----------|-----------|--------|
| react | ^19.0.0 | 19.0.0 | ✅ Compatible |
| react-dom | ^19.0.0 | 19.0.0 | ✅ Compatible |

**Cascading Upgrades:** None required

**Breaking Changes:**
- New turbopack defaults
- Middleware changes

**Blockers:** None

**Effort Estimate:** Medium

### Vitest Ecosystem: 3.x → 4.x
**Packages:** vitest, @vitest/ui, @vitejs/plugin-react, vite

**Transitive Dependency Analysis:**
| Dependency | Required | Installed | Action |
|------------|----------|-----------|--------|
| vite | ^6.0.0 | 5.4.0 | ⚠️ Upgrade to 6.x |

**Cascading Upgrades:** vite must upgrade to 6.x (included in ecosystem)

**Breaking Changes:**
- New configuration format
- Browser mode changes
- Vite 6 migration required

**Blockers:** None - vite@6 is available

**Effort Estimate:** Medium (was Low, increased due to vite upgrade)

[AskUserQuestion: Which updates would you like to apply?]
Options:
1. Security fixes only (Recommended) - Fix next, js-yaml vulnerabilities
2. Security + minor/patch ecosystems - React, Tailwind, Tanstack Query, standalone
3. All updates including major ecosystems - Full update with migration
4. Select specific ecosystems - Choose which to update
```