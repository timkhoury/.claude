---
name: Check
description: Evaluate code review feedback for correctness without implementing fixes
category: Quality
tags: [check, review, feedback, evaluate, validate]
---

# Check Command

Evaluate code review feedback to determine if it's correct, without implementing any fixes.

## Usage

```
/check <review-feedback>
```

The `<review-feedback>` argument should contain the review comment or issue to evaluate.

## Examples

```
/check Security: OAuth Token Encryption Key Validation doesn't verify valid base64
```

```
/check Performance: Token Generation N+1 Pattern in repositories.ts:135
```

```
/check "You should use useMemo here for the filtered list"
```

## When to Use

- **Triage**: Quickly validate multiple review comments before deciding what to fix
- **Pushback**: When you want analysis before responding to feedback you disagree with
- **Learning**: Understanding whether feedback is correct without changing code
- **Batch review**: Evaluating a list of review comments to prioritize fixes

## Workflow

For each feedback item:

### Step 1: Locate the Code

1. **Identify the location** mentioned in the feedback
2. **Read the relevant code** and surrounding context
3. **Understand the current implementation** before judging

### Step 2: Evaluate Correctness

Assess the feedback against these criteria:

1. **Factual accuracy**: Is the technical claim correct?
2. **Current state**: Has this already been addressed?
3. **Applicability**: Does this apply to our codebase/architecture?
4. **Severity**: If valid, how important is this fix?
5. **Trade-offs**: Are there reasons the current approach is intentional?

### Step 3: Report Assessment

Provide a clear verdict with reasoning.

## Output Format

```markdown
## Checking: [Feedback Summary]

### Verdict: ✅ Valid | ⚠️ Partially Valid | ❌ Not Valid | 🔄 Already Fixed

### Location
- **File**: [file path]
- **Line(s)**: [line numbers if applicable]

### Analysis
[Detailed explanation of why the feedback is or isn't valid]

### Current Code
```[language]
[Relevant code snippet]
```

### Evidence
[Specific reasons supporting your verdict]
- [Point 1]
- [Point 2]

### Recommendation
- **If Valid**: [Brief description of what fix would look like]
- **If Not Valid**: [How to respond to the reviewer]
- **Priority**: High / Medium / Low / None
```

## Multiple Feedback Items

If evaluating multiple items:

1. Process each item separately
2. Provide individual verdicts
3. Summarize at the end with a triage table:

```markdown
## Summary

| # | Feedback | Verdict | Priority |
|---|----------|---------|----------|
| 1 | OAuth token validation | ✅ Valid | High |
| 2 | useMemo optimization | ❌ Not Valid | None |
| 3 | Error handling | ⚠️ Partial | Medium |

### Recommended Action
- Fix #1 and #3
- Respond to #2 explaining why current approach is correct
```

## Verdict Criteria

| Verdict | Meaning |
|---------|---------|
| ✅ **Valid** | Feedback is correct and should be addressed |
| ⚠️ **Partially Valid** | Some aspects are correct, others aren't |
| ❌ **Not Valid** | Feedback is incorrect or doesn't apply |
| 🔄 **Already Fixed** | Issue was valid but has been addressed |

## Important Notes

- **Read before judging** - Always examine the actual code first
- **Consider context** - What makes sense in isolation may not fit our patterns
- **Be objective** - Don't dismiss valid feedback defensively
- **Explain clearly** - Provide enough detail to respond to the reviewer
- **No changes** - This command only evaluates, use `/fix` to implement

## Related Commands

- `/fix <feedback>` - Evaluate AND implement fixes
- `/review` - Run comprehensive code review (generates feedback)
