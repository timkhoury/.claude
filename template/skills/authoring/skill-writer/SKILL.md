---
name: skill-writer
description: >
  Create and modify skill definitions in .claude/skills/.
  Use when writing new skills, editing SKILL.md files, updating skill descriptions
  or frontmatter, or optimizing skill structure.
---

# Skill Writing Guidelines

Standards for creating and maintaining Claude Code skills.

## Critical Rules

1. **Context over configuration** - Skills read from project context; avoid hardcoding commands
2. **Description is critical** - Third person, includes WHAT + WHEN, contains trigger keywords
3. **Token efficiency** - Use tables and bullets, not prose
4. **Skills are stateless** - Use files for persistence in long-running tasks

## Core Principles

### Context Over Configuration

**Skills should be generic and read from project context.**

| Do | Don't |
|----|-------|
| "Run the project's lint command" | "Run `npm run lint`" |
| "Check CLAUDE.md for the test command" | Hardcode specific commands |
| "Use the patterns from project rules" | Embed project-specific patterns |

**Why:** Project-specific details belong in CLAUDE.md and `.claude/rules/`, which are already in context.

### Skills vs Agents

| Aspect | Skill | Agent |
|--------|-------|-------|
| Activation | Auto-activates via description matching | Explicit invocation or Task tool |
| Purpose | Pattern reference, quick lookup | Complex reasoning, multi-step tasks |
| State | Stateless (use files for persistence) | Can maintain session memory |
| Scope | Narrow, focused domain | Broader expertise |

**Rule:** Quick reference or pattern guide → Skill. Complex reasoning or orchestration → Agent.

### Description Best Practices

The `description` field determines when Claude auto-activates the skill.

| Practice | Why |
|----------|-----|
| Write in third person | POV consistency aids discovery |
| Include WHAT + WHEN | Function AND trigger scenarios |
| Use keywords users would say | Enables natural language discovery |
| Keep concise (~100 tokens) | Progressive disclosure |

**Pattern:** `[What it does]. Use when [trigger 1], [trigger 2], or [trigger 3].`

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

## Tool Restrictions

Use `allowed-tools` for read-only or security-sensitive skills:

```yaml
# Read-only skill
allowed-tools: [Read, Glob, Grep]

# Skill that needs bash for CLI tools
allowed-tools: [Read, Glob, Grep, Bash]
```

## Maintenance

Review skills periodically for:
- **Accuracy**: Do patterns still match the codebase?
- **Relevance**: Are all sections still needed?
- **Triggers**: Does the description match actual use cases?
- **Consistency**: Do all skills follow these guidelines?

## Reference

- **REFERENCE.md** - Directory structure, naming conventions, YAML fields, checklist
- **PATTERNS.md** - Content organization formats, description checklist
