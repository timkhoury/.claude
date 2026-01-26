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
# Run full analysis (size + description quality)
.claude/skills/skills-review/analyze-skills.sh --all

# Run individual analyses
.claude/skills/skills-review/analyze-skills.sh --report        # Size only
.claude/skills/skills-review/analyze-descriptions.sh --report  # Description quality only

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

### Step 1: Run Size Analysis

```bash
.claude/skills/skills-review/analyze-skills.sh --report
```

The script identifies:
- **Critical** skills (>10k chars) needing immediate reduction
- **Warning** skills (>4k chars) worth optimizing
- Verbose descriptions (>200 chars)
- Large tables (>20 rows) that should be extracted

### Step 2: Run Description Quality Analysis

```bash
.claude/skills/skills-review/analyze-descriptions.sh --report
```

The script checks:
- **Action verb**: Does description start with third-person verb?
- **Trigger phrase**: Contains "Use when..." or similar?
- **Length**: 15-100 words (not too vague, not context waste)
- **Red flags**: First-person language, generic terms

### Step 3: Analyze Flagged Skills

For each flagged skill, check:

1. **Reference tables** - Extract to `PATTERNS.md` or `REFERENCE.md`
2. **Code examples** - Remove redundant examples
3. **Duplicate content** - Compare with related skills

### Step 4: Apply Optimizations

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

**Always fix global skills too.** When issues are found in `~/.claude/skills/`, suggest and apply fixes there as well - these affect all projects.

## Common Violations

| Issue | Impact | Fix |
|-------|--------|-----|
| Description >300 chars | Harder trigger matching | Trim to essentials |
| SKILL.md >10k chars | Context waste on activation | Extract reference files |
| Inline tables >20 rows | Context bloat | Extract to PATTERNS.md |
| "Use this tool to..." prefix | Wasted chars | Start with action verb |

## Description Quality Checks

Good descriptions follow the WHAT + WHEN pattern for discoverability.

| Check | Requirement | Why |
|-------|-------------|-----|
| Length | 20-100 tokens | Too short = vague; too long = noise |
| Trigger scenarios | Contains "Use when..." | Claude needs activation cues |
| Action verb | Starts with third-person verb | POV consistency in system prompt |
| Keywords | Includes user-facing terms | Natural language discovery |

**Red flags** (review manually after running `analyze-skills.sh`):
- Description < 20 words (too vague for reliable activation)
- No "Use when" or trigger phrases (Claude can't select correctly)
- First-person language ("I will help you...")
- Generic terms without domain specifics ("Helper for stuff")

## After Completion

Record this review:

```bash
.claude/scripts/review-tracker.sh record skills-review
```
