---
name: rules-review
description: >
  Review Claude Code rules for proper organization and separation of concerns.
  Use when auditing rules, checking for cross-technology contamination, or
  ensuring rules follow the single-technology principle. Helps maintain clean
  rule boundaries.
---

# Rules Review

Audit `.claude/rules/` to ensure proper separation of concerns.

## Core Principle

**Each rule file should focus on ONE technology.** Cross-technology patterns belong in separate integration files.

| Pattern | Example |
|---------|---------|
| Pure technology | `nextjs.md`, `supabase.md`, `tailwind.md` |
| Integration | `nextjs-supabase.md`, `tailwind-shadcn.md` |

## Review Process

### Step 1: List All Tech Rules

```bash
ls -la .claude/rules/tech/
```

### Step 2: Analyze Each File

For each file, check:

1. **Title/tagline** - Does it mention only one technology?
2. **Code examples** - Do they import from multiple frameworks?
3. **Decision tables** - Do they compare "use X vs use Y" across technologies?
4. **Anti-patterns** - Do they reference other technologies?

### Step 3: Identify Cross-Technology Content

**Red flags that indicate content should be split:**

| Red Flag | Example | Should Be |
|----------|---------|-----------|
| "Use Server Component instead of X" | Tanstack Query mentioning Next.js RSC | `nextjs-tanstack-query.md` |
| Framework-specific imports in examples | Supabase examples with Next.js cookies | `nextjs-supabase.md` |
| "When using X with Y" sections | Testing patterns for Supabase | `supabase-testing.md` |
| Middleware/context-specific patterns | Supabase client selection by context | `nextjs-supabase.md` |

### Step 4: Report Findings

For each file with issues, report:

```markdown
## `filename.md`

**Status:** Needs split / Clean

**Cross-technology content found:**
- [Line X]: References to [other technology]
- [Section Y]: Integration pattern for [tech A + tech B]

**Recommendation:**
- Extract [content] to `tech-a-tech-b.md`
- Keep [content] in `tech-a.md`
```

## Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Pure technology | `{technology}.md` | `react.md`, `postgres.md` |
| Integration | `{tech-a}-{tech-b}.md` | `react-redux.md`, `express-postgres.md` |

## After Splitting

1. **Update the source file** - Remove cross-technology content
2. **Create integration file** - Add extracted content with proper context
3. **Rebuild agents** - Run build command if using agent build system
4. **Update docs** - Add new file to rules reference

## Common Violations

| Violation | Often Found In | Fix |
|-----------|----------------|-----|
| "Use Server Component instead" | Data fetching libs | Extract to `nextjs-{lib}.md` |
| Cookie/middleware patterns | Auth/database libs | Extract to `nextjs-{lib}.md` |
| Component library specifics | CSS framework rules | Extract to `{css}-{component}.md` |
| Test setup with real DB | Database rules | Extract to `{db}-testing.md` |

## Project Rules Review

Ensure project-specific content lives in `rules/project/` and follows naming conventions.

### Check for Misplaced Project Content

```bash
# List all rule folders
ls -la .claude/rules/

# Check each non-project folder for project-specific content
grep -l "this project\|this codebase\|our app" .claude/rules/tech/*.md
grep -l "this project\|this codebase\|our app" .claude/rules/patterns/*.md
```

**Project-specific content belongs in `rules/project/`, not in tech/patterns/meta.**

### Standard Project Rule Files

| File | Purpose | Content |
|------|---------|---------|
| `overview.md` | Quick reference | Tech stack, commands, file organization |
| `architecture.md` | System design | Routes, data flow, integrations |
| `testing.md` | Test setup | Fixtures, utilities, test user management |
| `environment.md` | Setup | Env vars, credentials, external services |
| `troubleshooting.md` | Common issues | Debugging tips, known gotchas |
| `code-review.md` | Review checklist | Project-specific review criteria |

Not all projects need every file - create based on complexity.

### Signs of Misplaced Content

| Found In | Red Flag | Move To |
|----------|----------|---------|
| `tech/*.md` | References to "our database schema" | `project/architecture.md` |
| `patterns/*.md` | "In this project we..." | `project/overview.md` |
| `meta/*.md` | Project URLs, credentials | `project/environment.md` |

## Agent Configuration Review

Also check `.claude/agents-src/` for proper separation between template and project config.

### `_project.yaml` Convention

`_project.yaml` should primarily use `$includes.project.*` references. Template rules belong in `_template.yaml`.

```bash
# Check for non-project includes in _project.yaml
grep -E '\$includes\.(tech|patterns|meta|testing)\.' .claude/agents-src/_project.yaml
```

If non-project includes are found, analyze whether they're intentional:

| Pattern | Likely Intentional | Likely Mistake |
|---------|-------------------|----------------|
| Adding rules template bundle lacks | Project needs extra context | Should update template bundle |
| Duplicating what template already includes | Redundant, remove it | - |
| Overriding for specific agent type | Project has unique needs | Should be in template if reusable |
