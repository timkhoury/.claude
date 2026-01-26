---
name: review
description: >
  Perform comprehensive code review checking quality and standards compliance.
  Use when reviewing branch changes vs main, before creating PRs, or checking code quality.
  Triggers: "review", "check code", "PR review", "code quality"
---

# Review Skill

Reviews branch changes against main, producing PR-style feedback.

## Syntax

```
/review              # All workspace changes vs main
/review <branch>     # Specific GitButler branch vs main
```

## Workflow

### Step 1: Get the Diff

Determine the scope of changes to review:

| Argument | Diff Command |
|----------|--------------|
| None | `git diff main...HEAD` (all workspace changes) |
| `<branch>` | `but diff <branch>` (specific GitButler branch) |

### Step 2: Invoke Code-Reviewer Agent

Pass the diff scope to the code-reviewer agent:

```
Invoke the code-reviewer agent with:
- Scope: [branch name or "all workspace changes"]
- Files: [list from diff --stat]
- Context: Branch diff vs main for PR review
```

### Step 3: Display Review

The agent will output PR-comment style feedback:

- Constructive and specific
- Reference `file:line` for issues
- Explain WHY something is a problem
- Suggest concrete fixes
- Group by severity: Blockers > Issues > Suggestions

### Step 4: Prompt for Action

After review completes, ask the user what they want to do next:

| Option | Description |
|--------|-------------|
| Fix issues | Implement the fixes using `/fix` skill |
| Run checks | Run `/pr-check` for automated validation |
| Continue | Proceed without changes |

## Review Focus

Based on CLAUDE.md and project rules:

| Area | What to Check |
|------|---------------|
| Code quality | Best practices, patterns |
| Bugs | Potential issues, edge cases |
| Performance | N+1 queries, unnecessary operations |
| Security | Auth checks, injection, XSS |
| Tests | Coverage, cleanup, isolation |

## Output Format

PR-comment style (not rigid template):

```markdown
## Code Review: [Scope Summary]

### Verdict: [Approved / Changes Requested / Blocked]

[1-2 sentence summary of overall assessment]

### Issues

**[Severity]**: [Category] in `file:line`

[Explanation of why this is a problem]

```suggestion
// Suggested fix
```

### Suggestions

- [Optional improvements that are nice-to-have]

---

What would you like to do?
- Fix the issues
- Run automated checks (`/pr-check`)
- Continue without changes
```

## Verdict Meanings

| Verdict | Meaning | Action |
|---------|---------|--------|
| Approved | Ready to merge | Minor suggestions may be provided |
| Changes Requested | Fix issues first | Must address before merging |
| Blocked | Security/breaking issues | Do not merge |
