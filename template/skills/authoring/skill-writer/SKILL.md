---
name: skill-writer
description: Use when creating or modifying skill files in .claude/skills/. Auto-activates for skill definition tasks, including writing new skills or updating existing ones.
---

# Skill Writing Guidelines

Standards for creating and maintaining Claude Code skills.

## Core Principles

### 1. Context Over Configuration

**Skills should be generic and read from project context.**

| Do | Don't |
|----|-------|
| "Run the project's lint command" | "Run `npm run lint`" |
| "Check CLAUDE.md for the test command" | Hardcode specific commands |
| "Use the patterns from project rules" | Embed project-specific patterns |

**Why:** Project-specific details belong in CLAUDE.md and `.claude/rules/`, which are already in context. Skills that reference context are portable and don't duplicate information.

### 2. Skills vs Agents

| Aspect | Skill | Agent |
|--------|-------|-------|
| Activation | Auto-activates via description matching | Explicit invocation or Task tool |
| Purpose | Pattern reference, quick lookup | Complex reasoning, multi-step tasks |
| State | Stateless (use files for persistence) | Can maintain session memory |
| Scope | Narrow, focused domain | Broader expertise |

**Rule:** If it's a quick reference or pattern guide → Skill. If it requires complex reasoning or orchestration → Agent.

### 3. Description is Critical

The `description` field determines when Claude auto-activates the skill. Claude uses it to select from 100+ available skills.

| Practice | Why |
|----------|-----|
| Write in third person | Injected into system prompt; POV consistency aids discovery |
| Include WHAT + WHEN | Claude needs function AND trigger scenarios to select correctly |
| Use keywords users would say | Enables discovery from natural language |
| Keep concise (~100 tokens) | Progressive disclosure; full content loads on activation |

**Pattern:**
```
[What it does]. Use when [trigger 1], [trigger 2], or [trigger 3].
```

**Good:**
```yaml
description: >
  Creates architecture decision records following project conventions.
  Use when documenting technical decisions, recording architectural choices,
  or when user says "create ADR" or "document decision".
```

**Bad:**
```yaml
description: ADR helper.  # Too vague, no triggers
```

### 4. Token Efficiency

Skills should be scannable and concise. Use tables and bullet points instead of prose.

## Skill Structure

```markdown
---
name: skill-name
description: >
  What this skill does and when to use it. Include trigger keywords.
  Specific use cases help Claude activate appropriately.
allowed-tools: [Read, Glob, Grep]  # Optional: restrict tools
---

# Skill Name Guide

[One-line summary of what this skill provides]

## Critical Rules

[3-5 most important rules - numbered list]

## [Main Reference Section]

[Tables, code examples, patterns]

## [Additional Sections as Needed]

## Reference

See `docs/RELATED.md` for detailed documentation.
```

## Skills Directory Structure

**Template** (categorized for organization):

```
~/.claude/template/skills/
├── authoring/      # Content creation (ADRs, agents, skills, rules)
├── quality/        # Code review, spec validation, testing patterns
├── workflow/       # Task management, issue tracking, process automation
├── automation/     # Browser testing, dependency updates, background processes
└── tech/           # Technology-specific (conditional sync based on detection)
```

**Project** (flat - categories stripped on sync):

```
.claude/skills/
├── adr-writer/           # From authoring/
├── pr-check/             # From quality/
├── work/                 # From workflow/
├── supabase-advisors/    # From tech/ (if detected)
└── my-project-skill/     # Project-specific (never synced)
```

### Template vs Global Isolation

**Template skills must never reference global skills.**

| Location | Syncs to Projects | Can Reference |
|----------|-------------------|---------------|
| `~/.claude/template/skills/` | Yes | Template skills/scripts only |
| `~/.claude/skills/` | No | Global or template skills |

**Why:** Template skills sync to project `.claude/skills/`. Collaborators won't have your global skills.

### Naming Conventions

- Descriptive names indicate purpose (`adr-writer`, `pr-check`, `spec-review`)
- Prefix when needed for clarity (`deps-updater` not just `updater`)
- Categories flattened on sync to projects
- Tech-specific skills sync only when technology detected

## YAML Frontmatter

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `name` | Lowercase, hyphenated, max 64 chars | `spec-review` |
| `description` | When to use, trigger keywords, use cases | Multi-line with `>` |

### Optional Fields

| Field | Description | Values |
|-------|-------------|--------|
| `allowed-tools` | Restrict available tools | `[Read, Glob, Grep, Bash]` |
| `model` | Override model for this skill | `claude-haiku-4-5` |

**Note:** Skills do NOT use `color` fields (those are for agents).

## Description Checklist

Before finalizing a description, verify:

- [ ] Starts with action verb (third person)
- [ ] Includes "Use when" trigger scenarios
- [ ] Contains keywords users would say
- [ ] Under ~100 tokens (concise)
- [ ] No "Use this tool to..." prefix (wasted chars)

## Content Patterns

### Critical Rules Section

Start with the most important rules:

```markdown
## Critical Rules

1. **Rule name** - Brief explanation
2. **Rule name** - Brief explanation
3. **Rule name** - Brief explanation
```

### Reference Tables

Use tables for quick lookup:

```markdown
| Context | Action | Example |
|---------|--------|---------|
| Server Component | Use X | `import { X } from '...'` |
| Client Component | Use Y | `import { Y } from '...'` |
```

### Code Examples

Show correct and incorrect patterns:

```markdown
**Correct:**
```typescript
// Good pattern here
```

**Wrong:**
```typescript
// Bad pattern here
```
```

### Workflow Steps

For procedural guidance:

```markdown
### Step 1: Do This

```bash
command here
```

Brief explanation of what this does.

### Step 2: Then This

...
```

## When to Create Skills

**Create when:**
- Quick pattern lookup needed frequently
- Reference material for specific domain
- Checklist or workflow that benefits from structure
- Domain that auto-activates based on keywords

**Don't create when:**
- Complex reasoning required → Use Agent
- One-off task → Just do it
- Overlaps with existing skill → Extend existing
- Too narrow → Fold into related skill

## Progress Tracking (for Long Tasks)

Skills are stateless. For long-running tasks that need pause/resume:

1. **Create a progress file** in a tracked location
2. **Document the format** in the skill
3. **Include resume instructions**

```markdown
## Progress Tracking

Progress is tracked at `path/to/PROGRESS.md`.

### Resume Instructions

1. Check if progress file exists
2. Read current position
3. Continue from last checkpoint
```

## Shell Scripts vs Inline Bash

**Prefer deterministic scripts over inline bash commands.**

| Aspect | Script | Inline Bash |
|--------|--------|-------------|
| Permissions | Grant once, runs always | Needs approval each time |
| Testing | Can test independently | Manual verification |
| Reuse | Easy to invoke | Copy-paste prone |
| Debugging | Clear, traceable | Scattered in conversation |

### When to Extract to Script

Extract to a colocated script when:
- File copying, moving, or comparing
- Complex conditional logic based on file system state
- Operations that should be testable independently
- Pattern matching on file paths
- Operations that will run repeatedly

### Script Colocation

Scripts live alongside the skill that uses them:

```
.claude/skills/my-skill/
├── SKILL.md
├── my-operation.sh    # Colocated script
└── PATTERNS.md        # Optional reference
```

**Only put scripts in `.claude/scripts/`** if shared across multiple skills.

### Script Design Principles

1. **Safe defaults** - `--report` mode by default, require explicit flags for changes
2. **Self-documenting** - Include `--help` with examples
3. **Idempotent** - Running twice produces the same result
4. **Colored output** - Use ANSI colors for clear feedback

### Keep in Skill When

Keep logic in SKILL.md (not a script) when:
- Gathering user input (AskUserQuestion)
- Making decisions requiring codebase understanding
- Operations needing AI judgment (code review, refactoring)
- Orchestrating multiple steps with user feedback

See `rules/meta/deterministic-systems.md` for detailed patterns.

## Tool Restrictions

Use `allowed-tools` for read-only or security-sensitive skills:

```yaml
# Read-only skill
allowed-tools: [Read, Glob, Grep]

# Skill that needs bash for CLI tools
allowed-tools: [Read, Glob, Grep, Bash]
```

## File Naming

| Component | Convention | Example |
|-----------|------------|---------|
| Directory | `kebab-case` | `.claude/skills/spec-review/` |
| Skill file | Always `SKILL.md` | `SKILL.md` |
| Supporting docs | `SCREAMING_CASE.md` | `PATTERNS.md`, `REFERENCE.md` |

## Checklist for New Skills

- [ ] Directory created at `.claude/skills/skill-name/`
- [ ] SKILL.md has proper frontmatter (name, description)
- [ ] Description includes trigger keywords and use cases
- [ ] Critical Rules section at top
- [ ] Uses tables for reference material
- [ ] Code examples show correct/wrong patterns
- [ ] References external docs where appropriate
- [ ] Tool restrictions if needed (`allowed-tools`)
- [ ] Progress tracking if long-running task
- [ ] Complex bash logic extracted to colocated scripts

## Maintenance

Review skills periodically for:
- **Accuracy**: Do patterns still match the codebase?
- **Relevance**: Are all sections still needed?
- **Triggers**: Does the description match actual use cases?
- **Consistency**: Do all skills follow these guidelines?
