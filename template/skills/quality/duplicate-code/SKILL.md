---
name: duplicate-code
description: >
  Find and analyze duplicated code using jscpd.
  Use when "duplicate code", "copy paste", "jscpd", "DRY",
  "find duplicates", or auditing codebase for redundancy.
---

# Duplicate Code Detection

Find copy-pasted code blocks using jscpd.

## Critical Rules

1. **Analyze before acting** - Report findings grouped by area before proposing changes
2. **Not all duplication is bad** - Some repetition is intentional (error boundaries, test fixtures)
3. **Verify after cleanup** - Run lint + typecheck after any refactoring

## Workflow

### 1. Run Analysis

```bash
npx jscpd src/ \
  --ignore "**/*.test.*,**/*.spec.*,**/node_modules/**,**/*.d.ts" \
  --min-lines 5 --min-tokens 50 \
  --reporters console 2>&1
```

Tune thresholds if needed:

| Flag | Default | When to Adjust |
|------|---------|----------------|
| `--min-lines 5` | 5 | Raise to reduce noise from small patterns |
| `--min-tokens 50` | 50 | Raise to focus on significant clones |
| `--threshold 0` | 0 | Set 1-100 to fail on duplication percentage |

### 2. Categorize Findings

| Category | Criteria | Action |
|----------|----------|--------|
| **Identical copies** | 100% same code, different files | Extract shared component/utility |
| **Structural clones** | Same pattern, minor value differences | Consider parameterized abstraction |
| **Boilerplate** | Repeated setup/teardown across files | Extract helper or wrapper |
| **Intentional** | Test fixtures, error boundaries, config | Leave as-is or extract minimally |

### 3. Present Findings

Group by area, not by file. Prioritize by impact:

```markdown
## Duplication Report

### Area 1: [Name] (N clones, ~M lines)
| File A | File B | Lines | Type |
|--------|--------|-------|------|
| path/a.tsx | path/b.tsx | 67 | Identical copy |

**Root cause:** [Why this happened]
**Recommendation:** [Extract to shared location / parameterize / leave as-is]

### Area 2: ...
```

### 4. Propose DRY Strategy (if requested)

For each area, recommend one of:

| Strategy | When |
|----------|------|
| **Move to shared** | 100% identical, used by multiple routes |
| **Parameterize** | Same structure, different values/props |
| **Extract hook** | Shared stateful logic across components |
| **Extract utility** | Pure functions duplicated across files |
| **Wrapper/factory** | Repeated boilerplate with unique core logic |
| **Leave as-is** | Coupling cost exceeds duplication cost |

### 5. Execute Cleanup (if requested)

For each extraction:
1. Create the shared abstraction
2. Update all consumers to use it
3. Delete the duplicated code
4. Run lint + typecheck to verify

## When NOT to DRY

| Situation | Why |
|-----------|-----|
| 2-3 similar lines | Abstraction costs more than repetition |
| Different domains sharing structure | Coupling unrelated features is worse |
| Test fixtures | Isolation matters more than DRY |
| Likely to diverge | Premature abstraction creates coupling |

## Quick Reference

```bash
npx jscpd src/                          # Full report
npx jscpd src/server/actions/           # Specific directory
npx jscpd src/ --reporters json         # JSON output
npx jscpd src/ --min-lines 10           # Larger clones only
npx jscpd src/ --format "typescript"    # Single language
```
