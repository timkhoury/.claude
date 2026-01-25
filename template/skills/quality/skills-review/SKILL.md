---
name: skills-review
description: >
  Analyze Claude Code skills for context efficiency. Checks description verbosity,
  file sizes, duplication, and extraction opportunities. Use when auditing skills
  or optimizing context usage.
---

# Skills Review

Audit `.claude/skills/` to optimize context consumption while maintaining effectiveness.

## Core Principle

**Skills should be lean.** Large files waste context. Reference content should be extracted.

| Metric | Target | Red Flag |
|--------|--------|----------|
| Description | 100-200 chars | >300 chars |
| Total SKILL.md | <4k chars | >10k chars |
| Reference tables | Extracted | Inline in SKILL.md |

## Review Process

### Step 1: Measure All Skills

```bash
# List skills with sizes
for d in .claude/skills/*/; do
  if [[ -f "$d/SKILL.md" ]]; then
    size=$(wc -c < "$d/SKILL.md")
    name=$(basename "$d")
    printf "%-30s %6d chars\n" "$name" "$size"
  fi
done | sort -t' ' -k2 -nr
```

### Step 2: Check Descriptions

Extract and measure each description:

```bash
# For each SKILL.md, extract description length
grep -A10 "^description:" .claude/skills/*/SKILL.md | head -20
```

**Description guidelines:**
- Include trigger keywords and use cases
- Skip obvious context (don't say "Use this tool to...")
- Avoid marketing language

### Step 3: Identify Large Files

For files >5k chars, analyze:

1. **Reference tables** - Can they be extracted to `PATTERNS.md`, `REFERENCE.md`, etc.?
2. **Code examples** - Are they necessary or just verbose?
3. **Duplicate content** - Is this repeated from another skill?

### Step 4: Check for Duplication

Compare skills that seem related:

| Pattern | Example | Fix |
|---------|---------|-----|
| Shared workflows | spec-coverage + test-quality | Create orchestrator skill |
| Repeated tables | Multiple skills with same patterns | Extract to shared reference |
| Copy-paste sections | Same steps in multiple skills | Abstract to common skill |

### Step 5: Report Findings

```markdown
## Skills Audit Report

### Size Summary
| Skill | Size | Status |
|-------|------|--------|
| skill-name | 12.3k | Needs optimization |
| other-skill | 2.1k | OK |

### Optimization Opportunities

#### `skill-name` (12.3k chars)
**Issues:**
- [ ] Description verbose (340 chars → target 150)
- [ ] Reference tables inline (extract ~4k to PATTERNS.md)
- [ ] Duplicates content from other-skill

**Recommendation:**
- Extract tables to `skill-name/PATTERNS.md`
- Trim description to essential triggers
- Consider thin orchestrator pattern
```

## Optimization Patterns

### 1. Extract Reference Content

**Before (inline):**
```markdown
## Ecosystems
| Ecosystem | Packages |
|-----------|----------|
| React | react, react-dom, @types/react |
| Next.js | next, eslint-config-next |
... (20+ rows)
```

**After (reference file):**
```markdown
## Ecosystems
**See `ECOSYSTEMS.md` for complete tables.**
```

### 2. Thin Orchestrator

When multiple skills share significant logic, create an orchestrator:

```markdown
## Workflow

### Step 1: Run First Analysis
Use the Skill tool: skill: "sub-skill-1"

### Step 2: Run Second Analysis
Use the Skill tool: skill: "sub-skill-2"

### Step 3: Combine Results
Merge outputs into unified report.
```

### 3. Trim Descriptions

**Before (verbose):**
```yaml
description: >
  This skill helps you detect changes in the project .claude/ directory
  and propagate any template-worthy improvements back to ~/.claude/template/.
  Use this when saying "update template", "sync to template", "propagate changes",
  or after making improvements to skills/rules that should be global.
```

**After (lean):**
```yaml
description: >
  Propagate project .claude/ improvements to ~/.claude/template/.
  Auto-invokes after editing skills/rules that exist in both locations.
```

## Skill Locations

Check all three locations when auditing:

| Location | Purpose |
|----------|---------|
| `.claude/skills/` | Project-specific skills |
| `~/.claude/template/skills/` | Template skills (synced to projects) |
| `~/.claude/skills/` | Global skills (user-wide) |

## Common Violations

| Violation | Impact | Fix |
|-----------|--------|-----|
| Description >300 chars | Harder to match triggers | Trim to essentials |
| SKILL.md >10k chars | Wastes context on every activation | Extract reference files |
| Duplicate logic | Maintenance burden | Use orchestrator pattern |
| Inline tables >20 rows | Context bloat | Extract to reference file |
| "Use this tool to..." prefix | Wasted chars | Start with action |
