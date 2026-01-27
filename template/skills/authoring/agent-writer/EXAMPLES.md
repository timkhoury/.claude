# Agent Examples

## YAML Source Structure

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
```

## Code Reviewer (Read-Only)

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

## Task Implementer (Writes Code)

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

## Orchestration Phases

| Phase | Description | Examples |
|-------|-------------|----------|
| EXPLORE & PLANNING | Gathers requirements, researches, designs | `planner-researcher` |
| EXECUTE (Validator) | Validates implementation, runs checks | `tester`, `code-reviewer` |
| EXECUTE (Implementer) | Implements tasks | `task-implementer` |
| ANY (Domain Consultant) | On-demand specialized knowledge | domain experts |

## Color Reference

| Color | Suggested Use |
|-------|---------------|
| `blue` | Analysis, review |
| `cyan` | Research, planning |
| `green` | Success-oriented, implementation |
| `yellow` | Caution, validation, testing |
| `magenta` | Creative, generation |
| `red` | Critical, security |
