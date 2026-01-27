---
name: agent-writer
description: Create and modify agent definitions in .claude/agents/ or .claude/agents-src/. Use when writing new agents, updating existing ones, or configuring subagent behavior.
---

# Agent Writing Guidelines

Standards for creating and maintaining AI agents for Claude Code.

## Critical Rules

1. **Professional role descriptions** - Senior/experienced, not "elite" or "world-class"
2. **Generic opening statements** - Transferable, no project-specific names
3. **Description is critical** - Clear triggering conditions with 2-4 examples
4. **Explicit skill inheritance** - Subagents do NOT auto-inherit skills

## Agent Definition Approaches

### Option 1: Direct Markdown

Create agents directly as `.md` files in `.claude/agents/`.

### Option 2: YAML Build System (Recommended for Teams)

Use YAML source files that compile to markdown:
```
.claude/agents-src/*.yaml  →  build script  →  .claude/agents/*.md
```

Benefits: Variables, includes, shared configuration, version control.

See **EXAMPLES.md** for full YAML and markdown structures.

## Core Principles

### Professional Role Descriptions

**Good**: "You are a senior QA engineer specializing in..."
**Bad**: "You are an elite Testing Master with unparalleled expertise..."

**Avoid**: "elite", "unparalleled", "world-class", "guardian", "never compromise"
**Use**: "senior", "experienced", "specialized", "ensure", "maintain"

### Generic Opening Statements

Opening descriptions should be transferable, avoiding project-specific names.

**Good**: "You are a senior database engineer specializing in PostgreSQL..."
**Bad**: "You are the MyProject Database Expert..."

## Required YAML Fields

| Field | Description |
|-------|-------------|
| `name` | Lowercase, hyphens, 3-50 chars (`code-reviewer`, `test-generator`) |
| `description.summary` | Clear triggering conditions (2-3 sentences) |
| `description.examples` | 2-4 examples with context, user, assistant, commentary |
| `body` | Agent's prompt/instructions (use `|` for multi-line) |

## Optional YAML Fields

| Field | Description |
|-------|-------------|
| `color` | Visual identifier (blue, cyan, green, yellow, magenta, red) |
| `skills` | Skills the agent has access to (must be explicit) |
| `tools` | Restrict available tools (omit for all tools) |
| `permissionMode` | `acceptEdits` for code writers, `plan` for planning only |
| `includes` | Files to prepend (`@/.claude/baseline-agent.md`, `@/CLAUDE.md`) |

## When to Create New Agents

**Create when:**
- Distinct domain requiring specialized knowledge
- Recurring complex tasks benefiting from systematic approach
- Clear boundary that doesn't overlap with existing agents

**Don't create when:**
- Trivial or one-off tasks
- Overlapping responsibilities with existing agents
- Too narrow scope (rarely invoked)

## Maintenance Checklist

- [ ] Patterns match the codebase?
- [ ] All sections still needed?
- [ ] Description has 2-4 triggering examples?
- [ ] Required skills explicitly listed?
- [ ] `permissionMode: acceptEdits` only for code writers?

## Reference

- **EXAMPLES.md** - Full YAML structure, agent patterns, orchestration phases
