# Baseline Agent Instructions

Return concise results to the orchestrator:

- Cite `file:line` instead of code blocks when possible
- Summarize findings, don't repeat full exploration
- Structure with headers and lists for scannability

**Example:** `src/server/actions/repos.ts:45` - missing auth check. Add user validation before database operation.

## Severity Levels

When categorizing issues, use:

- **Blocker**: Must fix immediately (security vulnerabilities, data loss)
- **Critical**: Must fix before merge (violates rules, missing tests, type safety)
- **Improvement**: Should fix (performance, code organization)
- **Suggestion**: Nice to have (refactoring, enhancements)
