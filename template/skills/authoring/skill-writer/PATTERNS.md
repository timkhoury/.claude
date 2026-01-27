# Skill Content Patterns

## SKILL.md Structure

```markdown
---
name: skill-name
description: >
  What this skill does and when to use it. Include trigger keywords.
allowed-tools: [Read, Glob, Grep]  # Optional
---

# Skill Name Guide

[One-line summary]

## Critical Rules

[3-5 most important rules - numbered list]

## [Main Reference Section]

[Tables, code examples, patterns]

## Reference

See `docs/RELATED.md` for detailed documentation.
```

## Critical Rules Section

Start with the most important rules:

```markdown
## Critical Rules

1. **Rule name** - Brief explanation
2. **Rule name** - Brief explanation
3. **Rule name** - Brief explanation
```

## Reference Tables

Use tables for quick lookup:

```markdown
| Context | Action | Example |
|---------|--------|---------|
| Server Component | Use X | `import { X } from '...'` |
| Client Component | Use Y | `import { Y } from '...'` |
```

## Code Examples

Show correct and incorrect patterns:

````markdown
**Correct:**
```typescript
// Good pattern here
```

**Wrong:**
```typescript
// Bad pattern here
```
````

## Workflow Steps

For procedural guidance:

````markdown
### Step 1: Do This

```bash
command here
```

Brief explanation of what this does.

### Step 2: Then This

...
````

## Description Checklist

Before finalizing a description, verify:

- [ ] Starts with action verb (third person)
- [ ] Includes "Use when" trigger scenarios
- [ ] Contains keywords users would say
- [ ] Under ~100 tokens (concise)
- [ ] No "Use this tool to..." prefix (wasted chars)

## Progress Tracking (for Long Tasks)

Skills are stateless. For long-running tasks that need pause/resume:

```markdown
## Progress Tracking

Progress is tracked at `path/to/PROGRESS.md`.

### Resume Instructions

1. Check if progress file exists
2. Read current position
3. Continue from last checkpoint
```
