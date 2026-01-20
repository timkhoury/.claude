# Research When Uncertain

When not entirely confident about a solution, **do online research** using `WebSearch` or `WebFetch` before implementing. Compare findings with your initial instinct.

## When to Research

- Testing strategies (isolation, mocking, fixtures)
- Security patterns (auth flows, session management, CSRF)
- Performance optimization approaches
- Integration patterns between tools/frameworks
- Edge cases or uncommon scenarios
- Anything where "it depends" might apply

## Research Workflow

1. Form an initial hypothesis based on knowledge
2. Search for how others have solved the same problem
3. Compare findings with initial instinct
4. If they differ, understand why - the research often reveals edge cases or pitfalls
5. Document the decision and link to sources

## Example

**Sign-out tests invalidating shared auth sessions:**
- Initial instinct: "Playwright isolates browser contexts, should be fine"
- Research revealed: Supabase invalidates tokens server-side, not just browser state
- Solution: Create fresh disposable sessions for sign-out tests
- Source: [Playwright Solutions article](https://playwrightsolutions.com/handling-multiple-login-states-between-different-tests-in-playwright/)

## Why This Matters

AI models have training cutoffs and may not know recent best practices. Real-world blog posts often document hard-won lessons from production issues.
