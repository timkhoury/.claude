---
name: review
description: >
  Review branch changes for quality and standards compliance.
  Use when "review", "check code", "PR review", or "code quality".
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
- Files: [extract file paths from the diff output header lines (e.g., "M src/foo.tsx")]
- Context: Branch diff for PR review

### Step 3: Display Review

The agent will output PR-comment style feedback:

- Constructive and specific
- Reference `file:line` for issues
- Explain WHY something is a problem
- Suggest concrete fixes
- Group by severity: Blockers > Issues > Suggestions

### Step 4: Detect UI Changes

Check if the branch contains UI-related changes by examining the diff output for:
- Files in `app/**/page.tsx`, `app/**/page.client.tsx`
- Files in `**/components/**/*.tsx`
- Files in `components/ui/**`
- Tailwind class changes (className with `bg-`, `text-`, `flex`, `grid`, etc.)
- CSS/style file changes

Set `hasUIChanges = true` if any UI-related files were modified.

### Step 5: Prompt for Action

After displaying the review, use `AskUserQuestion` to let the user choose next steps.

**If `hasUIChanges` is true**, include the design review option:

```
Question: "UI changes detected. What would you like to do next?"
Header: "Next step"
Options:
  - "Design review" / "Get frontend design quality feedback using /fed"
  - "Continue" / "Proceed without changes"
  - "Run checks" / "Run /pr-check for automated validation"
  - "Fix issues" / "Implement fixes using /fix skill"
```

**If no UI changes**, use standard options:

```
Question: "What would you like to do next?"
Header: "Next step"
Options:
  - "Continue" / "Proceed without changes"
  - "Run checks" / "Run /pr-check for automated validation"
  - "Fix issues" / "Implement fixes using /fix skill"
  - "Create PR" / "Create pull request for this branch"
```

Then execute the chosen action. For "Design review", invoke `/fed` with the changed UI files as context.

## Review Focus

Based on CLAUDE.md and project rules:

| Area | What to Check |
|------|---------------|
| Code quality | Best practices, patterns |
| Bugs | Potential issues, edge cases |
| Performance | N+1 queries, unnecessary operations |
| Security | Auth checks, injection, XSS |
| Tests | Coverage, cleanup, isolation |
| UI patterns | Semantic colors, shadcn/ui usage, component organization |

**Note**: Code review covers UI *patterns* (correct usage of components, semantic tokens). For *design quality* assessment (aesthetics, typography, visual hierarchy), use `/fed` after the code review.

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
```

## Verdict Meanings

| Verdict | Meaning | Action |
|---------|---------|--------|
| Approved | Ready to merge | Minor suggestions may be provided |
| Changes Requested | Fix issues first | Must address before merging |
| Blocked | Security/breaking issues | Do not merge |
