---
name: review
description: >
  Perform comprehensive code review checking quality and standards compliance.
  Use when reviewing branch changes vs main, before creating PRs, or checking code quality.
  Triggers: "review", "check code", "PR review", "code quality"
---

# Review Skill

Reviews GitButler branch changes, producing PR-style feedback.

## Syntax

```
/review              # Auto-detect branch from context or first with commits
/review <branch>     # Specific GitButler branch
```

## Workflow

### Step 1: Determine Which Branch to Review

**Always use GitButler commands, never `git diff` or `gh pr diff`.**

| Argument | Action |
|----------|--------|
| `<branch>` | Use `but diff <branch>` directly |
| None | Infer branch (see below) |

**Branch inference when no argument provided:**

1. **Check session context** - Look at files you've modified this session. Match them against branches via `but status` to identify the relevant branch.

2. **Fall back to branch discovery** - If no context clues:
   ```bash
   but branch list
   ```
   Find the first branch with actual commits (not just changes) and review that one.

3. **Report what you're reviewing** - Always tell the user which branch you selected and why.

### Step 2: Get the Diff and Invoke Code-Reviewer Agent

Get the diff using GitButler, then pass to the code-reviewer agent:

```bash
but diff <branch>
```

Invoke the code-reviewer agent with:
- Scope: [branch name]
- Diff: [output from `but diff`]
- Files: [list from diff --stat]
- Context: Branch diff for PR review

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
