---
name: Fix
description: Evaluate and fix review feedback, update specs if needed, and commit
category: Quality
tags: [fix, review, feedback, commit]
---

# Fix Command

Fix review feedback by evaluating correctness, implementing fixes, updating specs, and committing changes.

## Usage

```
/fix <review-feedback>
```

The `<review-feedback>` argument should contain the review comment or issue to address.

## Examples

```
/fix Security: OAuth Token Encryption Key Validation doesn't verify valid base64
```

```
/fix Performance: Token Generation N+1 Pattern in repositories.ts:135
```

```
/fix Test Data Setup Using Old Schema Format in repositories.test.ts:86-93
```

## Workflow

Execute the following steps for each review feedback item:

### Step 1: Evaluate Correctness

Before implementing any fix:

1. **Read the relevant code** at the specified location
2. **Assess if the feedback is still valid**:
   - Has this already been fixed?
   - Is the concern actually a problem in this codebase?
   - Does the suggested fix make sense for our architecture?
3. **Report your assessment** to the user:
   - If already fixed: "This has already been addressed in [location]"
   - If not applicable: "This feedback doesn't apply because [reason]"
   - If valid: "Yes, this is correct. Here's what needs to be fixed..."

### Step 2: Propose and Implement Fix

If the feedback is valid:

1. **Explain the fix** briefly before implementing
2. **Make the code changes** following project patterns (see CLAUDE.md)
3. **Run type check** to verify changes compile: `npm run typecheck`
4. **Run tests if applicable**: `npm run test` (for affected areas)

### Step 3: Evaluate Spec Updates

After implementing the fix, check if OpenSpec documentation needs updates:

1. **Check for active OpenSpec changes**:
   ```bash
   npx openspec list
   ```

2. **If the fix relates to an active change**, check these files:
   - `openspec/changes/<change-id>/tasks.md` - Does this complete a task?
   - `openspec/changes/<change-id>/design.md` - Does the design need updating?
   - `openspec/changes/<change-id>/specs/*/spec.md` - Do spec deltas need updating?

3. **If the fix introduces new behavior**, consider:
   - Does it need a new requirement in a spec delta?
   - Does it change existing requirements?
   - Should it be documented in the design?

4. **Update specs if needed** following OpenSpec conventions

5. **Validate specs**:
   ```bash
   npx openspec validate --specs --strict
   ```

### Step 4: Commit Changes

Use the GitButler skill to commit:

1. **Check status**: `but status`
2. **Assign files to the appropriate branch**: `but rub <file-id> <branch>`
3. **Commit with descriptive message**:
   ```bash
   but commit <branch> --only -m "<message>"
   ```

**Commit message format:**
- Start with action verb: "Fix", "Add", "Update", "Remove"
- Reference the issue fixed
- List key changes in body if multiple files affected

## Output Format

Report progress at each step:

```markdown
## Evaluating: [Feedback Summary]

### Assessment
- **Status**: Valid / Already Fixed / Not Applicable
- **Location**: file:line
- **Analysis**: [Brief explanation]

### Fix Applied (if valid)
- **Changes**: [List of changes made]
- **Files Modified**: [List of files]

### Spec Updates (if needed)
- **Updated**: [List of spec files updated, or "None needed"]

### Committed
- **Commit**: [commit hash]
- **Branch**: [branch name]
- **Message**: [commit message summary]
```

## Multiple Feedback Items

If the user provides multiple feedback items (numbered list or separated by newlines):

1. Process each item sequentially
2. Group related fixes into single commits when logical
3. Summarize all changes at the end

## Important Notes

- **Always verify before fixing** - Don't assume feedback is still valid
- **Follow project patterns** - Check CLAUDE.md for coding standards
- **Use GitButler** - Use `but commit` instead of raw `git commit`
- **Update specs proactively** - If a fix changes documented behavior, update specs
- **Run validation** - Ensure typecheck passes before committing
