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

| File | Package Manager |
|------|-----------------|
| `package.json` | npm/pnpm/yarn/bun |
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
3. Check peer dependencies: `npm ls {package}`
4. Identify standalone packages (no ecosystem)

## Phase 3: Security Audit

| Package Manager | Command |
|-----------------|---------|
| npm | `npm audit` |
| pnpm | `pnpm audit` |
| yarn | `yarn audit` |
| cargo | `cargo audit` |
| pip | `pip-audit` |
| go | `govulncheck ./...` |

**Critical/high vulnerabilities:** Recommend immediate fix before other updates.

## Phase 4: Check for Updates

| Package Manager | Command |
|-----------------|---------|
| npm | `npm outdated` |
| pnpm | `pnpm outdated` |
| cargo | `cargo outdated` |
| pip | `pip list --outdated` |

Categorize: Security > Major > Minor > Patch

## Phase 5: Research Major Updates

For each ecosystem with major updates:

### 1. Analyze Transitive Dependencies

```bash
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
```bash
npm audit fix
```

### Minor/Patch Ecosystem
```bash
npm install react@latest react-dom@latest @types/react@latest @types/react-dom@latest
```

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
```bash
npm ls {package}           # See conflicts
npm install --legacy-peer-deps  # Force (use with caution)
```

### Lock File Issues
```bash
rm package-lock.json && npm install
```
