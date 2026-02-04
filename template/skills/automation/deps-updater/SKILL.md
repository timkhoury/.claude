---
name: deps-updater
description: >
  Update dependencies and audit for security issues across any language/package manager.
  Use when user says "update deps", "security audit", or "check for updates".
---

# Dependency Update Guide

Audit security vulnerabilities and guide through dependency updates with migration research.

## Critical Rules

1. **Security first** - Always run security audit before updates
2. **Ecosystem awareness** - Group related packages (see ECOSYSTEMS.md)
3. **Analyze transitive deps** - Check peer dependencies before major upgrades
4. **Research major updates** - Use WebSearch for breaking changes
5. **Present choices** - Use AskUserQuestion for update selection
6. **One ecosystem at a time** - Major updates with testing between
7. **Commit incrementally** - Separate commits by update type

## Phase 1: Detect Package Manager

**Detection order for JS/TS projects (check lock files first):**

| Lock File | Package Manager |
|-----------|-----------------|
| `bun.lockb` | bun |
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| `package-lock.json` | npm |

**If no lock file exists, check `package.json`:**
- `engines.bun` field → bun
- `packageManager` field → specified manager
- Scripts using `bun` → bun
- Default → npm

**Other languages:**

| File | Package Manager |
|------|-----------------|
| `Cargo.toml` | cargo |
| `go.mod` | go mod |
| `requirements.txt` / `pyproject.toml` | pip/poetry/uv |
| `Gemfile` | bundler |
| `composer.json` | composer |

## Phase 2: Identify Ecosystems

**See `ECOSYSTEMS.md` in this skill folder for complete ecosystem tables.**

Key concept: Framework packages must be updated together to avoid version conflicts.

When analyzing outdated packages:
1. Group by ecosystem
2. Flag partial updates (some packages in ecosystem have updates, others don't)
3. Check peer dependencies: `bun pm ls {package}` (or `npm ls {package}`)
4. Identify standalone packages (no ecosystem)

## Phase 3: Security Audit

| Package Manager | Command |
|-----------------|---------|
| bun | `bun audit` |
| npm | `npm audit` |
| pnpm | `pnpm audit` |
| yarn | `yarn audit` |
| cargo | `cargo audit` |
| pip | `pip-audit` |
| go | `govulncheck ./...` |

**Bun audit options:**
- `--audit-level=<low|moderate|high|critical>` - Filter by severity
- `--prod` - Production deps only
- `--ignore <CVE>` - Skip specific CVEs
- `--json` - Raw JSON output

**Critical/high vulnerabilities:** Recommend immediate fix before other updates.

## Phase 4: Check for Updates

| Package Manager | Command |
|-----------------|---------|
| bun | `bun outdated` |
| npm | `npm outdated` |
| pnpm | `pnpm outdated` |
| cargo | `cargo outdated` |
| pip | `pip list --outdated` |

Categorize: Security > Major > Minor > Patch

## Phase 5: Research Major Updates

For each ecosystem with major updates:

### 1. Analyze Transitive Dependencies

```bash
# bun (uses npm registry)
bunx npm info {package}@{version} peerDependencies
bunx npm info {package}@{version} dependencies

# npm
npm info {package}@{version} peerDependencies
npm info {package}@{version} dependencies
```

Check: Is it installed? Compatible? Cascading upgrades needed?

### 2. Web Research

Search for:
- `{package} {version} changelog`
- `{package} migrate {old} to {new}`
- `{package} {version} breaking changes`

### 3. Document Findings

```markdown
### {Ecosystem}: {old} → {new}
**Packages:** {list}
**Cascading Upgrades:** {list or "None"}
**Breaking Changes:** {list}
**Blockers:** {list or "None"}
**Effort:** Low / Medium / High
```

## Phase 6: Present Update Plan

Use AskUserQuestion:

1. **Security fixes only** (recommended first)
2. **Security + minor/patch** (low risk)
3. **All including major** (full migration)
4. **Select specific ecosystems**

## Phase 7: Apply Updates

### Security

| Package Manager | Command |
|-----------------|---------|
| bun | `bun update` (compatible) or `bun update --latest` (breaking) |
| npm | `npm audit fix` |

**Note:** Bun doesn't have `audit fix`. Use `bun update` for compatible fixes or `bun add {package}@{version}` for specific versions.

### Minor/Patch Ecosystem

| Package Manager | Command |
|-----------------|---------|
| bun | `bun add react@latest react-dom@latest @types/react@latest @types/react-dom@latest` |
| npm | `npm install react@latest react-dom@latest @types/react@latest @types/react-dom@latest` |

### Major Ecosystem (one at a time)
1. Update all ecosystem packages together
2. Run build
3. Run tests
4. Fix breaking changes
5. Commit: `chore(deps): upgrade {ecosystem} to v{version}`
6. Proceed to next ecosystem

## Phase 8: Verify and Commit

1. Run build, tests, lint
2. Commit with conventional format

| Type | Message |
|------|---------|
| Security | `fix(deps): security patches for {packages}` |
| Major | `chore(deps): upgrade {ecosystem} to v{version}` |
| Minor/Patch | `chore(deps): update dependencies` |

## Common Issues

### Peer Dependency Conflicts

| Package Manager | Commands |
|-----------------|----------|
| bun | `bun pm ls {package}` to see conflicts |
| npm | `npm ls {package}` / `npm install --legacy-peer-deps` |

### Lock File Issues

| Package Manager | Command |
|-----------------|---------|
| bun | `rm bun.lockb && bun install` |
| npm | `rm package-lock.json && npm install` |

### Bun-Specific Notes

- Bun uses `bun.lockb` (binary) - convert with `bun bun.lockb` to view as text
- `bun add` = `npm install` for adding packages
- `bun install` = `npm install` for installing from lockfile
- `bun pm ls` = `npm ls` for listing installed packages
- `bun audit` = `npm audit` for security scanning
- `bun update` = update to compatible versions
- `bun update --latest` = update to latest (including breaking changes)

## Completion

After completing dependency updates, record for systems-check tracking:

```bash
.claude/scripts/systems-tracker.sh record deps-updater
```
