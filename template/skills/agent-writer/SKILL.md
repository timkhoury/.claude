---
name: agent-writer
description: Use when creating or modifying agent files in .claude/agents/ or .claude/agents-src/. Auto-activates for agent definition tasks, including writing new agents or updating existing ones.
---

# Agent Writing Guidelines

Standards for creating and maintaining AI agents for Claude Code.

## Agent Definition Approaches

### Option 1: Direct Markdown

Create agents directly as `.md` files in `.claude/agents/`:

```markdown
# Agent Name

You are a [role] specializing in [domain].

## Your Responsibilities
...
```

### Option 2: YAML Build System (Recommended for Teams)

Use YAML source files that compile to markdown:

```
.claude/agents-src/*.yaml  →  build script  →  .claude/agents/*.md
```

Benefits: Variables, includes, shared configuration, version control of source.

## Core Principles

### 1. Professional Role Descriptions

Agents represent experienced professionals, not superhuman experts.

**Good**: "You are a senior QA engineer specializing in..."
**Bad**: "You are an elite Testing Master with unparalleled expertise..."

### 2. Generic Opening Statements

Opening descriptions should be transferable, avoiding project-specific names.

**Good**: "You are a senior database engineer specializing in PostgreSQL..."
**Bad**: "You are the MyProject Database Expert..."

### 3. No Superlatives

**Avoid**: "elite", "unparalleled", "world-class", "guardian", "never compromise"
**Use**: "senior", "experienced", "specialized", "ensure", "maintain"

## Agent Markdown Structure

```markdown
# Agent Name

You are a [senior/experienced] [role] specializing in [domain].
Your expertise [includes/spans] [area 1], [area 2], and [area 3].

**Orchestration Phase**: [EXPLORE | PLANNING | EXECUTE | ANY]

[1-2 sentences explaining when this agent operates]

## Critical Constraint

You are a [role], not a [what you're not].

**What You Do:**
- [Responsibility 1]
- [Responsibility 2]

**What You Do NOT Do:**
- [Anti-pattern 1]
- [Anti-pattern 2]

After completing your [task], **report findings to the main orchestrator**.

## Your Core Responsibilities

1. [Responsibility 1]
2. [Responsibility 2]

[Additional domain-specific sections...]

[Closing statement about the agent's role]
```

## YAML Source Structure (Build System)

Create files in `.claude/agents-src/<agent-name>.yaml`:

```yaml
# Comment describing the agent
name: agent-name
color: blue                    # Visual identifier
permissionMode: acceptEdits    # Only for agents that write code

includes:
  - "@/.claude/baseline-agent.md"
  - "@/CLAUDE.md"              # For implementers needing full rules

description:
  summary: >
    Use this agent when [triggering conditions].
    [What it does]. [What it doesn't do].
  examples:
    - context: Scenario description
      user: What user says
      assistant: How Claude responds
      commentary: Why this agent is appropriate

body: |
  You are a [senior/experienced] [role] specializing in [domain].
  ...
```

## Required Fields

### name (required)

Agent identifier. Format: lowercase, numbers, hyphens only. Length: 3-50 characters.

**Good**: `code-reviewer`, `test-generator`, `api-docs-writer`
**Bad**: `helper` (too generic), `my_agent` (underscores), `ag` (too short)

### description (required)

**This is the most important field.** It defines when Claude triggers the agent.

**Requirements:**
- `summary`: Clear triggering conditions (2-3 sentences)
- `examples`: 2-4 examples showing when to use the agent
- Each example needs: `context`, `user`, `assistant`, `commentary`

### body (required)

The agent's prompt/instructions. Use YAML block scalar (`|`) for multi-line content.

## Optional Fields

### color

Visual identifier for the agent.

| Color | Suggested Use |
|-------|---------------|
| `blue` | Analysis, review |
| `cyan` | Research, planning |
| `green` | Success-oriented, implementation |
| `yellow` | Caution, validation, testing |
| `magenta` | Creative, generation |
| `red` | Critical, security |

### skills

List of skills the agent should have access to:

```yaml
skills:
  - gitbutler
  - test-patterns-guide
```

**CRITICAL: Subagents do NOT automatically inherit skills.** You must explicitly list them.

### tools

Restrict available tools:

```yaml
tools: ["Read", "Bash", "Grep", "Glob"]  # Read-only agent
```

**If omitted:** Agent has access to ALL tools.

### permissionMode

Controls permission handling.

| Value | Behavior | Use For |
|-------|----------|---------|
| (omit) | Normal prompts | Read-only agents |
| `acceptEdits` | Auto-accept edits | Implementers that write code |
| `plan` | Plan mode only | Pure planning agents |

**Only use `acceptEdits` for agents that write code.**

### includes

Files to prepend to the agent's body:

```yaml
includes:
  - "@/.claude/baseline-agent.md"    # Common instructions
  - "@/CLAUDE.md"                    # Project rules (for implementers)
```

## Orchestration Phases

| Phase | Description | Examples |
|-------|-------------|----------|
| EXPLORE & PLANNING | Gathers requirements, researches, designs | `planner-researcher` |
| EXECUTE (Validator) | Validates implementation, runs checks | `tester`, `code-reviewer` |
| EXECUTE (Implementer) | Implements tasks | `task-implementer` |
| ANY (Domain Consultant) | On-demand specialized knowledge | domain experts |

## Common Agent Patterns

### Code Reviewer (Read-Only)

```yaml
name: code-reviewer
color: blue
# No permissionMode - read-only

description:
  summary: >
    Use to review code quality and enforce standards.
    Reports findings only, does not write code.

body: |
  You are a senior code quality engineer...

  ## Critical Constraint
  You are a reviewer, not a fixer.
  **What You Do:** Analyze, identify, recommend
  **What You Do NOT Do:** Make changes, fix issues
```

### Task Implementer (Writes Code)

```yaml
name: task-implementer
color: green
permissionMode: acceptEdits
skills:
  - gitbutler

includes:
  - "@/CLAUDE.md"

description:
  summary: >
    Use to implement specific tasks with full project context.
    Writes code and commits changes.

body: |
  You are a task implementer...
  ## Your Process
  1. Understand the task
  2. Implement changes
  3. Run checks
  4. Commit via gitbutler
```

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

Review agents periodically for:
- **Accuracy**: Do patterns still match the codebase?
- **Relevance**: Are all sections still needed?
- **Consistency**: Do all agents follow these guidelines?
- **Examples**: Description has 2-4 triggering examples?
- **Skills**: Required skills explicitly listed?
- **Permissions**: `permissionMode: acceptEdits` only for agents that write code?
