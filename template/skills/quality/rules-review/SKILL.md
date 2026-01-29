---
name: rules-review
description: >
  Review Claude Code rules for organization and separation of concerns.
  Use when auditing rules, checking for cross-technology contamination,
  or evaluating rule-vs-skill decisions.
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

### Step 1: List Tech Rules

```bash
ls -la .claude/rules/tech/
```

### Step 2: Check Each File

For each file, check:
- Title mentions only one technology?
- Code examples import from single framework?
- Decision tables don't compare across technologies?

See **PATTERNS.md** for red flags and common violations.

### Step 3: Report Findings

```markdown
## `filename.md`

**Status:** Needs split / Clean

**Cross-technology content found:**
- [Line X]: References to [other technology]

**Recommendation:**
- Extract [content] to `tech-a-tech-b.md`
```

## Global Rules Review

**Always review and fix global rules too.** When checking rules, also audit:
- `~/.claude/rules/` - Global rules affecting all projects
- `~/.claude/template/rules/` - Template rules synced to projects

Issues in global/template rules affect all projects and should be fixed proactively.

## Project Rules Review

Check for misplaced content:

```bash
grep -l "this project\|this codebase\|our app" .claude/rules/tech/*.md
```

**Project-specific content belongs in `rules/project/`, not tech/patterns/meta.**

### Standard Project Rule Files

| File | Purpose |
|------|---------|
| `overview.md` | Tech stack, commands |
| `architecture.md` | Routes, data flow |
| `infrastructure.md` | Database, services |
| `testing.md` | Fixtures, test users |
| `code-review.md` | Review checklist |

## Rules vs Skills Analysis

See **CHECKLIST.md** for decision criteria and questions to ask.

Quick test: Is this needed for most coding tasks? → Rule. Workflow triggered occasionally? → Skill.

## Agent Config Review

Check `_project.yaml` uses mainly `$includes.project.*` references:

```bash
grep -E '\$includes\.(tech|patterns|meta)\.' .claude/agents-src/_project.yaml
```

## After Completion

```bash
.claude/scripts/systems-tracker.sh record rules-review
```

## Reference

- **PATTERNS.md** - Red flags, common violations, naming conventions
- **CHECKLIST.md** - Review questions, decision criteria, agent config review
