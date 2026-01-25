---
name: rules-review
description: >
  Review Claude Code rules for organization, separation of concerns, and
  rule-vs-skill decisions. Use when auditing rules, checking for cross-technology
  contamination, evaluating if rules should be skills, or ensuring proper
  boundaries. Covers tech rules, project rules, and agent configuration.
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
| `infrastructure.md` | Database/services | Schema separation, client configuration |
| `testing.md` | Test setup | Fixtures, utilities, test user management |
| `code-review.md` | Review checklist | Project-specific review criteria |

Not all projects need every file - create based on complexity.

**Note:** Setup instructions (`environment.md`) and troubleshooting guides are better as skills since they're on-demand workflows, not always-needed context.

### Signs of Misplaced Content

| Found In | Red Flag | Move To |
|----------|----------|---------|
| `tech/*.md` | References to "our database schema" | `project/architecture.md` |
| `patterns/*.md` | "In this project we..." | `project/overview.md` |
| `meta/*.md` | Project URLs, credentials | `project/environment.md` |

## Rules vs Skills Analysis

Evaluate whether each rule should remain a rule or become a skill.

### Decision Criteria

| Factor | Rule (Always Loaded) | Skill (On-Demand) |
|--------|---------------------|-------------------|
| **Frequency** | Needed for most tasks | Needed occasionally |
| **Content type** | Patterns, conventions, constraints | Workflows, step-by-step processes |
| **Context** | Shapes how code is written | Guides specific operations |
| **Size** | Any size if always relevant | Large files waste context if rarely used |

### Questions to Ask

For each rule file, ask:

1. **Is this needed for typical coding tasks?** If no → candidate for skill
2. **Is this a workflow with steps?** If yes → should be a skill
3. **Does it reference external tools/commands primarily?** If yes → likely a skill
4. **Would an agent need this for most implementations?** If no → candidate for skill

### Common Patterns

| Pattern | Likely Should Be | Example |
|---------|------------------|---------|
| Setup instructions | Skill | Environment setup, project onboarding |
| Git subtree/submodule workflows | Skill | Content syncing, dependency management |
| Troubleshooting guides | Rule (small) or Skill (large) | Common issues reference |
| External service workflows | Skill | Deployment, CI/CD, migrations |
| Code conventions | Rule | Naming, structure, patterns |
| Architecture decisions | Rule | Data flow, component organization |

### Review Process

```bash
# List project rules with line counts
wc -l .claude/rules/project/*.md | sort -n
```

For each file, evaluate:

```markdown
## `filename.md`

**Lines:** X
**Purpose:** [brief description]

**Frequency analysis:**
- Needed for typical coding? Yes/No
- Workflow-based content? Yes/No
- External tool focus? Yes/No

**Verdict:** RULE / SKILL / SPLIT

**If SKILL:** Suggested skill name: `/skill-name`
```

### Converting Rules to Skills

When a rule should become a skill, use `/skill-writer` to create it properly:

```
/skill-writer
```

The skill-writer will:
1. Create the skill folder and SKILL.md with proper frontmatter
2. Structure the content as a workflow
3. Handle naming conventions

After skill creation:
1. Remove the old rule file
2. Update any references (CLAUDE.md, agent bundles)
3. Rebuild agents if needed

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
