# Permission Patterns Reference

## Safety Classification

### ✅ Safe to Promote

| Pattern | Reason |
|---------|--------|
| `npm run test`, `npm test` | Standard, non-destructive |
| `npm run build`, `npm run dev` | Common dev workflow |
| `git status`, `git diff`, `git log` | Read-only git |
| `but status` | GitButler read |
| `npx *` | Package runners |
| `bd ready`, `bd list`, `bd show` | Beads read |
| Linting/formatting | Non-destructive |

### ⚠️ Requires Confirmation

| Pattern | Risk |
|---------|------|
| `git push`, `but push` | Sends to remote |
| `git commit`, `but commit` | Creates commits |
| `npm publish` | Publishes packages |
| `rm -rf`, `git clean` | Destructive |
| Deploy commands | Production impact |
| Database migrations | Schema changes |

### ❌ Never Promote

| Pattern | Reason |
|---------|--------|
| `/Users/...`, `./scripts/...` | Project paths |
| `ENV=prod ...` | Environment-specific |
| `--token=...` | Credentials |

## Category Patterns

| Category | Patterns | Safety |
|----------|----------|--------|
| Testing | `test`, `spec`, `coverage`, `vitest`, `playwright` | ✅ |
| Building | `build`, `dev`, `start`, `compile` | ✅ |
| Git (Read) | `git status/diff/log/show`, `but status` | ✅ |
| Git (Write) | `git commit/push`, `but commit/push` | ⚠️ |
| Issue Tracking | `bd ready/list/show` (✅), `bd close/update` (⚠️) | Mixed |
| Linting | `lint`, `eslint`, `prettier`, `typecheck` | ✅ |
| Packages | `npm install/ci`, `npx *` | ✅ |
| Database | `db:types` (✅), `db:migrate/seed/push` (⚠️) | Mixed |
| Deployment | `deploy`, `publish`, `release` | ⚠️ |
| Project-Specific | Absolute paths, custom scripts, ENV vars | ❌ |

## Pattern Matching Rules

| Check | Result |
|-------|--------|
| Exact match in global | 🔄 Skip |
| Covered by wildcard (`git *` covers `git status`) | 🔄 Skip |
| Contains `./` or `/Users/` | ❌ Keep local |
| Contains `ENV=` | ❌ Keep local |
| Not covered | Analyze and suggest |
