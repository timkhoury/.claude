# Completion Criteria

> Work isn't done until it's verified, documented, and handed over cleanly.

## Task Level

A task is complete when:
- Code works as specified
- Typecheck passes with no new errors
- Changes are committed with a clear commit message

## Feature Level

A feature is complete when:
- All tasks are completed
- Tests written and passing (unit + integration, E2E if user-facing)
- Code review is clean (no blockers or unresolved issues)
- Quality gates pass (`/pr-check`)
- Documentation updated if behavior changed
- Decision recorded if an architectural choice was made (`/adr-writer`)

## When Documentation Is Required

| Change Type | Documentation |
|------------|---------------|
| New user-facing feature | Update relevant docs |
| API endpoint added/changed | Update API docs or inline comments |
| Architectural decision | Write a decision record |
| Config/env change | Update setup docs |
| Bug fix | None (unless it reveals a pattern) |
| Refactor | None |

## When Decisions Should Be Recorded

Record a decision when:
- Choosing between multiple valid approaches
- Introducing a new dependency or pattern
- Changing an existing convention
- Making a trade-off future developers need to understand

Skip recording for:
- Following an existing pattern
- Obvious choices with no alternatives
- Temporary workarounds (create a tracking issue instead)

## Root Cause Principle

A task is not complete if:
- The fix works but the underlying issue remains
- Tests pass only because symptoms were patched
- The same issue will recur in a different form
