---
name: adr-writer
description: >
  Write Architecture Decision Records following standard conventions.
  Use when creating ADRs, documenting technical decisions, or formalizing
  architectural choices. Handles file naming, template format, and index updates.
---

# ADR Writer

Create Architecture Decision Records using date-based naming for conflict-free parallel writing.

## Critical Rules

1. **Backdate to actual decision date** - Use the date the decision was originally made, not today
2. **Use date-based filename** - Format: `YYYY-MM-DD-kebab-title.md` (date matches decision date)
3. **Include all sections** - Context, Decision, Rationale, Alternatives, Consequences, References
4. **Update README index** - Add link after writing
5. **Reference existing ADRs** - Check existing decisions in the ADR directory

## File Naming

```
docs/decisions/YYYY-MM-DD-kebab-title.md
```

| Component | Rule | Example |
|-----------|------|---------|
| `YYYY-MM-DD` | ISO date of decision | `2026-01-19` |
| `kebab-title` | Lowercase, hyphenated slug | `supabase-for-database` |

**Examples:**
- `2026-01-19-supabase-for-database.md`
- `2026-01-19-semantic-color-tokens.md`
- `2026-01-19-monorepo-structure.md`

**Same-day conflicts:** If multiple ADRs are created on the same day with similar topics, add a distinguishing suffix to the slug (e.g., `2026-01-19-auth-strategy.md` vs `2026-01-19-auth-implementation.md`).

## Template

```markdown
# [Title]

**Status:** Accepted
**Date:** YYYY-MM-DD

## Context

What situation led to this decision? What problem are we solving?

## Decision

What was decided?

## Rationale

Why was this decision made? What factors influenced the choice?

## Alternatives Considered

### Alternative 1: [Name]
- **Pros:** ...
- **Cons:** ...
- **Why not:** ...

### Alternative 2: [Name]
- **Pros:** ...
- **Cons:** ...
- **Why not:** ...

## Consequences

### Positive
- What benefits does this decision provide?

### Negative
- What trade-offs or limitations does this introduce?

### Neutral
- What changes are required as a result?

## References

- Related ADRs: [Title](./YYYY-MM-DD-title.md)
- External docs: [Link](url)
```

## Workflow

### Step 1: Check existing ADRs

```bash
ls docs/decisions/
```

Review existing ADRs to understand established patterns and avoid duplication.

### Step 2: Determine the decision date

**Always backdate to when the decision was actually made.** Find the date from:
- PR merge date (`gh pr view <num> --json mergedAt`)
- Commit date when pattern was introduced
- Documentation that added the rule

Only use today's date for genuinely new decisions being made now.

### Step 3: Write the ADR

Create file at `docs/decisions/YYYY-MM-DD-kebab-title.md` using the decision date from Step 2.

### Step 4: Update README index

Add to appropriate section in `docs/decisions/README.md`:
```markdown
### Infrastructure & Database
- [Use Supabase for database and auth](./2026-01-19-supabase-for-database.md)
```

## Parallel Writing Safety

Date-based naming eliminates race conditions. Multiple agents can write different ADRs simultaneously - each ADR has a unique topic slug.

## When to Create ADRs

**Create for:**
- Foundational technology choices (database, framework, auth)
- Cross-cutting patterns and conventions
- Decisions affecting multiple features
- Choices future developers will question

**Don't create for:**
- Feature-specific decisions (use design docs or comments)
- Trivial or obvious choices
- Temporary solutions

## Status Values

| Status | Meaning |
|--------|---------|
| Accepted | Decision is in effect |
| Proposed | Under discussion, not yet decided |
| Deprecated | Superseded by another ADR |
| Rejected | Considered but not adopted |
