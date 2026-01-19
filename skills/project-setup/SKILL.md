---
name: project-setup
description: >
  Initialize Claude Code configuration for a new project. Copies template structure,
  installs and configures tools (GitButler, Beads, OpenSpec), creates scaffolded
  rule files, and parameterizes templates. Use when setting up a new project,
  saying "setup project", "initialize claude", or "configure claude code".
---

# Project Setup Guide

Interactive setup for Claude Code project configuration.

## Prerequisites

Ensure you're in the project root directory before running this skill.

## Setup Flow

### Phase 1: Gather Information

Use `AskUserQuestion` to collect:

**Question 1: Project Info**
```
Header: "Project"
Question: "What is this project? (name and brief description)"
```
(Free text - use "Other" option)

**Question 2: Tools to Enable**
```
Header: "Tools"
Question: "Which tools do you want to enable?"
Options:
  - "All (Recommended)" - GitButler + Beads + OpenSpec
  - "GitButler + Beads" - Issue tracking without specs
  - "GitButler only" - Just virtual branches
  - "None" - Manual git workflow
MultiSelect: false
```

**Question 3: Framework (if applicable)**
```
Header: "Framework"
Question: "What framework is this project using?"
Options:
  - "Next.js" - React Server Components, App Router
  - "React (Vite/CRA)" - Client-side React
  - "Node.js" - Backend/CLI project
  - "Other" - Different framework or none
MultiSelect: false
```

**Question 4: Rule Scaffolding**
```
Header: "Rules"
Question: "Create scaffolded rule files for project-specific documentation?"
Options:
  - "Yes (Recommended)" - Creates architecture.md, patterns.md, danger-zone.md
  - "No" - Skip rule scaffolding
MultiSelect: false
```

### Phase 2: Tool Installation Check

For each enabled tool, verify installation:

```bash
# GitButler
which but && but --version

# Beads
which bd && bd --version

# OpenSpec
which openspec && openspec --version
```

If missing, provide installation commands:

| Tool | Install Command |
|------|-----------------|
| GitButler | `curl -fsSL https://app.gitbutler.com/install.sh \| sh` |
| Beads | `npm install -g beads-ui@latest` |
| OpenSpec | `npm install -g @fission-ai/openspec@latest` |

### Phase 3: Copy Template Structure

Based on tool selections, copy from `~/.claude/template/`:

**Always copy:**
- `CLAUDE.md` → `./CLAUDE.md`
- `baseline-agent.md` → `./.claude/baseline-agent.md`
- `agents-src/` → `./.claude/agents-src/`
- `scripts/build-agents.ts` → `./.claude/scripts/build-agents.ts`

**If Beads enabled:**
- `rules/beads-workflow.md` → `./.claude/rules/beads-workflow.md`
- `skills/beads-cleanup/` → `./.claude/skills/beads-cleanup/`
- `commands/work.md` → `./.claude/commands/work.md`
- `commands/status.md` → `./.claude/commands/status.md`

**If OpenSpec enabled:**
- `rules/openspec.md` → `./.claude/rules/openspec.md`

**If Beads + OpenSpec enabled:**
- `rules/workflow-integration.md` → `./.claude/rules/workflow-integration.md`
- `commands/wrap.md` → `./.claude/commands/wrap.md`

**Always copy (from template):**
- `rules/landing-the-plane.md` → `./.claude/rules/landing-the-plane.md`
- `skills/pr-check/` → `./.claude/skills/pr-check/`

### Phase 4: Tool Initialization

**GitButler:**
```bash
# Check if already initialized
but status 2>/dev/null || echo "Not initialized"

# If not initialized, prompt user to open GitButler desktop app
# CLI init not available - requires desktop app
```

**Beads:**
```bash
# Check if already initialized
ls .beads/ 2>/dev/null || bd init --prefix=<project-name>
```

**OpenSpec:**
```bash
# Check if already initialized
ls openspec/ 2>/dev/null || openspec init --tools=claude
```

### Phase 5: Parameterize Templates

**Update `_shared.yaml`** based on framework:

```yaml
# For Next.js projects, add:
skillSets:
  patterns:
    - nextjs-patterns
    - ui-patterns-reference
    - test-patterns-guide

includes:
  # Add framework-specific rules if they exist
  nextjsPatterns: "@/.claude/rules/nextjs-patterns.md"
```

**Update `CLAUDE.md`** with project info:

1. Replace `<!-- Describe your project here -->` with project description
2. Update Quick Commands section based on package.json scripts
3. Add framework-specific sections

### Phase 6: Create Scaffolded Rules (if enabled)

Create empty rule files with templates:

**`.claude/rules/architecture.md`:**
```markdown
# Architecture

## Overview

<!-- Describe your architecture here -->

## Key Patterns

<!-- Document important patterns -->

## Data Flow

<!-- How data moves through the system -->
```

**`.claude/rules/patterns.md`:**
```markdown
# Project Patterns

## Code Patterns

<!-- Common patterns in this codebase -->

## Naming Conventions

<!-- Project-specific naming rules -->

## File Organization

<!-- How files are organized -->
```

**`.claude/rules/danger-zone.md`:**
```markdown
# Danger Zone

> These actions cause problems. Never do them.

## Commands

| Never | Consequence |
|-------|-------------|
| <!-- Add project-specific "never do" rules --> | |

## Code Patterns

| Never | Consequence |
|-------|-------------|
| <!-- Add anti-patterns to avoid --> | |
```

### Phase 7: Build Agents

```bash
# Install yaml dependency if needed
npm list yaml 2>/dev/null || npm install --save-dev yaml

# Build agents from YAML
npx tsx .claude/scripts/build-agents.ts
```

### Phase 8: Git Setup

```bash
# Add .claude/ to git
git add .claude/

# Add CLAUDE.md
git add CLAUDE.md

# If beads initialized, add .beads/
git add .beads/ 2>/dev/null || true

# If openspec initialized, add openspec/
git add openspec/ 2>/dev/null || true
```

### Phase 9: Summary

Print setup summary:

```
## Project Setup Complete

**Project:** <name>
**Tools enabled:** <list>

### Next Steps

1. Review and customize `.claude/rules/` files
2. Update `_shared.yaml` with project-specific skills
3. Run `npx tsx .claude/scripts/build-agents.ts` after changes
4. Commit the setup: `git commit -m "chore: add claude code configuration"`

### Quick Reference

| Command | Purpose |
|---------|---------|
| `bd ready` | Find available work |
| `/work <id>` | Execute a task |
| `/status` | Check workflow state |
| `/wrap` | End session workflow |
| `/pr-check` | Run quality gates |
```

## Tool Reference

### Installation Commands

| Tool | Check | Install |
|------|-------|---------|
| GitButler | `but --version` | `curl -fsSL https://app.gitbutler.com/install.sh \| sh` |
| Beads | `bd --version` | `npm install -g beads-ui@latest` |
| OpenSpec | `openspec --version` | `npm install -g @fission-ai/openspec@latest` |

### Initialization Commands

| Tool | Check | Initialize |
|------|-------|------------|
| GitButler | `but status` | Open GitButler desktop app |
| Beads | `ls .beads/` | `bd init --prefix=<name>` |
| OpenSpec | `ls openspec/` | `openspec init --tools=claude` |

## Troubleshooting

### "but: command not found"
GitButler CLI not installed. Run the install script or download from gitbutler.com.

### "bd: command not found"
Beads not installed. Run `npm install -g beads-ui@latest`.

### "openspec: command not found"
OpenSpec not installed. Run `npm install -g @fission-ai/openspec@latest`.

### Build agents fails
Ensure `yaml` package is installed: `npm install --save-dev yaml`
