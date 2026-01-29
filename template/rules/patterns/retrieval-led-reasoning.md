# Retrieval-Led Reasoning

> **Explore project patterns first, verify against current sources when uncertain.** Training data has cutoffs; current documentation, existing code, and real-world solutions are the source of truth.

## Workflow

1. **Explore project patterns first** - check existing implementations in this codebase
2. **Verify against sources if uncertain** - use tools below to confirm
3. **Prefer project conventions** - existing patterns take precedence over generic best practices

## Official Documentation

For API signatures, framework features, and third-party integrations.

**Tools:** `mcp__Ref__ref_search_documentation`, `mcp__Ref__ref_read_url`

**When to use:**
- Using a feature for the first time in this codebase
- Implementing features using newer APIs or patterns
- Checking current API signatures and usage patterns
- Working with recently updated framework APIs

**For Claude Code docs:** Prefer the `claude-code-guide` agent.

## Web Research

For edge cases, complex problems, and "it depends" situations.

**Tools:** `WebSearch`, `WebFetch`

**When to use:**
- Testing strategies (isolation, mocking, fixtures)
- Security patterns (auth flows, session management)
- Performance optimization approaches
- Anything where "it depends" might apply

**Research workflow:**
1. Form initial hypothesis
2. Search for how others solved the same problem
3. Compare findings with instinct - differences often reveal edge cases
4. Document the decision and link to sources

**Example:**
> Sign-out tests invalidating shared auth sessions:
> - Initial instinct: "Playwright isolates browser contexts, should be fine"
> - Research revealed: Supabase invalidates tokens server-side
> - Solution: Create fresh disposable sessions for sign-out tests

## Why Retrieval Over Pre-Training

| Risk | Benefit |
|------|---------|
| Training cutoff misses recent changes | Docs reflect current version |
| Deprecated patterns in training data | Current best practices |
| Confidence without accuracy | Verified accuracy |
| Missing edge cases | Real-world lessons from production |
