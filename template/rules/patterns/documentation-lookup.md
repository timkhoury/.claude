# Documentation Lookup

> **Prefer retrieval-led reasoning over pre-training-led reasoning.** Training data has cutoff dates and may contain outdated patterns. Current documentation is the source of truth.

This applies to:
- **Frameworks & libraries** - React, Next.js, Tanstack Query, etc.
- **Tools** - CLI tools, build tools, linters, package managers
- **APIs & SDKs** - Supabase, Stripe, GitHub, cloud providers
- **Platform features** - Browser APIs, Node.js APIs, edge runtime capabilities
- **Configuration formats** - Config schemas change between versions

Use Ref MCP tools to verify before implementing:

- `mcp__Ref__ref_search_documentation` - Search documentation
- `mcp__Ref__ref_read_url` - Read specific documentation pages

## When to Use

- Implementing features using newer APIs or patterns
- Verifying best practices for third-party integrations
- Checking current API signatures and usage patterns
- Confirming the correct way to use framework features

## Example Workflow

```typescript
// 1. Search for relevant documentation
mcp__Ref__ref_search_documentation({
  query: "Next.js 15 server actions error handling patterns"
})

// 2. Read the specific guide URL from search results
mcp__Ref__ref_read_url({
  url: "https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions#error-handling"
})
```

## When to Verify Against Docs

- Using a feature for the first time in this codebase
- Implementing complex patterns (error handling, data fetching, auth flows)
- Working with recently updated framework APIs
- Unsure about best practices or conventions

## Why Retrieval Over Pre-Training

| Pre-Training Risk | Retrieval Benefit |
|-------------------|-------------------|
| Training cutoff misses recent API changes | Docs reflect current version |
| Deprecated patterns still in training data | Docs show current best practices |
| Mixed patterns from multiple versions | Docs are version-specific |
| Confidence without accuracy | Verified accuracy |

## Claude Code Documentation

Prefer the `claude-code-guide` agent for Claude Code, Claude Agent SDK, and Claude API documentation.
