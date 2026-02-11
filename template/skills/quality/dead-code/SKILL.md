---
name: dead-code
description: >
  Find and remove unused files, dependencies, and exports using knip.
  Use when "dead code", "unused code", "knip", "cleanup dependencies",
  "find unused", or auditing codebase for cruft.
---

# Dead Code Detection

Find unused files, dependencies, and exports using knip.

## Critical Rules

1. **Always verify** - Knip has many false positives; check each finding
2. **Report first** - Run analysis and categorize before removing anything
3. **Verify after cleanup** - Run lint + typecheck after removing code

## Workflow

### 1. Run Analysis

```bash
npx knip 2>&1
```

Categories reported:
- Unused files
- Unused dependencies / devDependencies
- Unlisted dependencies (missing from package.json)
- Unused exports / types

### 2. Verify Findings

| Category | How to Verify |
|----------|---------------|
| Dependencies | `grep -r "pkg-name" --include="*.{js,ts,mjs,cjs}" .` |
| DevDependencies | Check package.json scripts, config files |
| Files | Check for imports, dynamic requires |

**Common false positives:**

| Pattern | Check |
|---------|-------|
| `eslint-config-*` | `eslint.config.*` for `extends()` |
| `prettier-plugin-*` | `.prettierrc` or `prettier.config.*` |
| `@types/*` | TypeScript uses implicitly |
| `tsx` | npm scripts in package.json |
| `*-reporter` | Conditionally loaded in test configs |
| Config files | Entry points, deployment configs |
| E2E utilities | Dynamic imports, manual use |

### 3. Categorize Results

| Category | Criteria |
|----------|----------|
| **Safe to remove** | Verified no references anywhere |
| **False positive** | Actually used, knip missed it |
| **Investigate** | Unclear, ask user |

### 4. Present Findings

```markdown
## Verified Unused - Safe to Remove

### Dependencies (N)
| Package | Reason |
|---------|--------|
| pkg-name | No imports found |

### Files (N)
| File | Reason |
|------|--------|
| path/file.ts | Superseded by newer version |

## False Positives - Keep
| Item | Reason |
|------|--------|
| eslint-config-next | Used via compat.extends() |

## Needs Investigation
| Item | Question |
|------|----------|
| util.ts | Manual use only? |
```

### 5. Execute Cleanup (if requested)

**Use the project's package manager** (check for `bun.lock`, `pnpm-lock.yaml`, or `package-lock.json`):

| Lockfile | Remove Command | Add Command |
|----------|----------------|-------------|
| `bun.lock` | `bun remove <pkg>` | `bun add -D <pkg>` |
| `pnpm-lock.yaml` | `pnpm remove <pkg>` | `pnpm add -D <pkg>` |
| `package-lock.json` | `npm uninstall <pkg>` | `npm install -D <pkg>` |

```bash
# Delete files
rm <files>

# Verify
npm run lint && npm run typecheck
```

**Peer dependency warning:** Removing packages can break peer dependency chains. After cleanup, run typecheck to catch missing peer deps (e.g., `@testing-library/dom` is a peer dep of `@testing-library/react`). Add any missing peer deps explicitly.

### 6. Configure knip (optional)

For recurring false positives, suggest `knip.json`:

```json
{
  "$schema": "https://unpkg.com/knip@latest/schema.json",
  "ignore": ["scripts/**"],
  "ignoreDependencies": ["eslint-config-*"]
}
```

## Quick Reference

```bash
npx knip                    # Full report
npx knip --fix              # Auto-fix deps only
npx knip --include deps     # Deps only
npx knip --reporter json    # JSON output
```
