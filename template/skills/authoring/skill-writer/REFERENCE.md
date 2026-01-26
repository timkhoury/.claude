# Skill Writer Reference

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

## Naming Conventions

- Descriptive names indicate purpose (`adr-writer`, `pr-check`, `spec-review`)
- Prefix when needed for clarity (`deps-updater` not just `updater`)
- Categories flattened on sync to projects
- Tech-specific skills sync only when technology detected

## File Naming

| Component | Convention | Example |
|-----------|------------|---------|
| Directory | `kebab-case` | `.claude/skills/spec-review/` |
| Skill file | Always `SKILL.md` | `SKILL.md` |
| Supporting docs | `SCREAMING_CASE.md` | `PATTERNS.md`, `REFERENCE.md` |

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
| `protected` | Skip from skills-review analysis | `true` |

**Note:** Skills do NOT use `color` fields (those are for agents).

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

See `rules/meta/deterministic-systems.md` for detailed patterns.
