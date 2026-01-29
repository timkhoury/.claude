---
name: Plan
description: Create a comprehensive implementation plan for a feature or refactoring
category: Planning
tags: [planning, architecture, design]
---

# Plan Command

You will invoke the **planner-researcher** agent to create a comprehensive implementation plan for the requested feature or change.

## What to Pass to the Agent

Provide the planner-researcher agent with:

1. **Feature Description**: Clear description of what needs to be planned
2. **Context**: Any relevant background, constraints, or requirements
3. **User Goals**: What problem this solves for users
4. **Scope**: What's in scope and what's out of scope

## Example Usage

```
/plan Add AI-powered code review to the repository indexing feature
```

```
/plan Refactor the authentication system to support OAuth for multiple providers (GitHub, GitLab, Bitbucket)
```

```
/plan Implement real-time repository indexing status updates using websockets
```

## What the Agent Will Do

The planner-researcher agent will:

1. **Clarify Requirements**: Ask questions to understand goals and constraints
2. **Research Patterns**: Review existing code and documentation
3. **Design Architecture**: Plan data models, component hierarchy, and integration points
4. **Create Implementation Plan**: Break down work into phases with tasks
5. **Identify Risks**: Flag potential issues and mitigation strategies
6. **Invoke OpenSpec Change**: Use `/opsx:new <description>` (step-by-step) or `/opsx:ff <description>` (fast-forward) to create structured proposal

## Expected Output

For features and changes (most cases):
- Agent invokes `/opsx:new <description>` or `/opsx:ff <description>` with prepared context
- OpenSpec auto-generates change-id (e.g., `add-oauth-token-refresh-with-automatic-expiration-handling`)
- OpenSpec creates structured proposal:
  - `proposal.md` - Why, What Changes, Impact
  - `tasks.md` - Ordered implementation checklist
  - `design.md` (optional) - Technical decisions, architecture, risks (for complex changes)
  - `specs/<capability>/spec.md` - Spec deltas with requirements and scenarios

For bug fixes only (restoring existing spec behavior):
- Direct implementation checklist (no OpenSpec needed)
- Simple task list with time estimates

## After Planning

Once the OpenSpec proposal is created:
- **Review and approve the proposal** - Implementation does NOT start until approved
- OpenSpec validates the proposal automatically (`openspec validate --strict`)
- Proceed with implementation using main Claude Code or `/opsx:apply`
- Consult specialized agents as needed (supabase-expert, tester, etc.)

## Important Notes

- The planner does NOT implement code - only prepares planning information
- Planner invokes `/opsx:new` or `/opsx:ff` for most features and changes
- OpenSpec auto-generates change-id and creates all proposal files
- Proposals must be **approved before implementation** begins
- For bug fixes (restoring existing behavior), planner provides direct checklist
- Plans follow project patterns from CLAUDE.md and docs/
- Run `/opsx:onboard` for a guided walkthrough of the OpenSpec workflow
