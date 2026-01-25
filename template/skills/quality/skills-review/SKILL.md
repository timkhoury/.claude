---
name: skills-review
description: >
  Analyze Claude Code skills for context efficiency. Checks description verbosity,
  file sizes, duplication, and extraction opportunities. Use when auditing skills
  or optimizing context usage.
---

# Skills Review

Audit `.claude/skills/` to optimize context consumption while maintaining effectiveness.

## Quick Start

```bash
# Run the analysis script
.claude/skills/skills-review/analyze-skills.sh --report

# Other output formats
.claude/skills/skills-review/analyze-skills.sh --json   # For scripting
.claude/skills/skills-review/analyze-skills.sh --csv    # For spreadsheets

# Analyze different locations
.claude/skills/skills-review/analyze-skills.sh --path ~/.claude/template/skills
```

## Thresholds

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| File size | <4k | >4k | >10k |
| Description | <200 chars | >200 | >300 |
| Table rows | <20 | >20 | - |

## Review Process

### Step 1: Run Analysis

```bash
.claude/skills/skills-review/analyze-skills.sh --report
```

The script identifies:
- **Critical** skills (>10k chars) needing immediate reduction
- **Warning** skills (>4k chars) worth optimizing
- Verbose descriptions (>200 chars)
- Large tables (>20 rows) that should be extracted

### Step 2: Analyze Flagged Skills

For each flagged skill, check:

1. **Reference tables** - Extract to `PATTERNS.md` or `REFERENCE.md`
2. **Code examples** - Remove redundant examples
3. **Duplicate content** - Compare with related skills

### Step 3: Apply Optimizations

**Extract tables:**
```markdown
<!-- Before: inline in SKILL.md -->
| Pattern | Example |
|---------|---------|
... 30 rows ...

<!-- After: reference file -->
**See `PATTERNS.md` for complete reference.**
```

**Trim descriptions:**
```yaml
# Before (verbose)
description: >
  This skill helps you detect changes in the project .claude/ directory
  and propagate any template-worthy improvements back to ~/.claude/template/.
  Use this when saying "update template"...

# After (lean)
description: >
  Propagate project .claude/ improvements to ~/.claude/template/.
  Auto-invokes after editing skills/rules in both locations.
```

**Use consolidated pattern** for related skills:
```markdown
## Workflow
/spec-review              # All analyses
/spec-review coverage     # Implementation coverage only
/spec-review tests        # Test coverage only
```

## Skill Locations

| Location | Purpose |
|----------|---------|
| `.claude/skills/` | Project-specific |
| `~/.claude/template/skills/` | Template (synced to projects) |
| `~/.claude/skills/` | Global (user-wide) |

## Common Violations

| Issue | Impact | Fix |
|-------|--------|-----|
| Description >300 chars | Harder trigger matching | Trim to essentials |
| SKILL.md >10k chars | Context waste on activation | Extract reference files |
| Inline tables >20 rows | Context bloat | Extract to PATTERNS.md |
| "Use this tool to..." prefix | Wasted chars | Start with action verb |

## After Completion

Record this review:

```bash
~/.claude/skills/systems-review/review-tracker.sh record skills-review
```
