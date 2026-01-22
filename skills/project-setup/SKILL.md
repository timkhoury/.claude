---
name: project-setup
description: >
  Initialize Claude Code configuration for a new project. Copies template structure,
  installs and configures tools (GitButler, Beads, OpenSpec), creates scaffolded
  rule files, and parameterizes templates. Use when setting up a new project,
  saying "setup project", "initialize claude", or "configure claude code".
---

# Project Setup

Initialize Claude Code configuration using the deterministic setup script.

## Usage

```bash
~/.claude/skills/project-setup/setup-project.sh [options]
```

| Option | Description |
|--------|-------------|
| `--tools=TOOLS` | Tools to enable: `all`, `beads+openspec`, `beads`, `openspec`, `none` (default: `all`) |
| `--framework=NAME` | Framework: `nextjs`, `react`, `node`, `other` (optional) |
| `--scaffold-rules` | Create scaffolded rule files (architecture.md, project-overview.md, danger-zone.md) |
| `--project-name=NAME` | Project name for beads prefix (default: directory name) |
| `--skip-init` | Skip tool initialization (bd init, openspec init) |
| `--skip-build` | Skip agent building step |

## Interactive Workflow

When invoked as a skill, gather information first:

### Question 1: Tools

```
Header: "Tools"
Question: "Which tools do you want to enable?"
Options:
  - "All (Recommended)" → --tools=all
  - "Beads + OpenSpec" → --tools=beads+openspec
  - "Beads only" → --tools=beads
  - "None" → --tools=none
```

### Question 2: Framework (optional)

```
Header: "Framework"
Question: "What framework is this project using?"
Options:
  - "Next.js" → --framework=nextjs
  - "React (Vite/CRA)" → --framework=react
  - "Node.js" → --framework=node
  - "Other/None" → (omit flag)
```

### Question 3: Scaffolding

```
Header: "Rules"
Question: "Create scaffolded rule files for project documentation?"
Options:
  - "Yes (Recommended)" → --scaffold-rules
  - "No" → (omit flag)
```

### Run Script

After gathering answers, run:

```bash
~/.claude/skills/project-setup/setup-project.sh --tools=<choice> [--framework=<choice>] [--scaffold-rules]
```

## What the Script Does

1. **Initializes git** (if not already a repo)
2. **Copies template files** to `.claude/`
3. **Scaffolds rule files** (optional)
4. **Initializes tools** (beads, openspec)
5. **Builds agents**

## What Gets Copied

### Always Copied

| Source | Destination |
|--------|-------------|
| `CLAUDE.md` | `./CLAUDE.md` |
| `baseline-agent.md` | `.claude/baseline-agent.md` |
| `agents-src/` | `.claude/agents-src/` |
| `scripts/` | `.claude/scripts/` |
| `rules/landing-the-plane.md` | `.claude/rules/` |
| `rules/deterministic-systems.md` | `.claude/rules/` |
| `rules/research-patterns.md` | `.claude/rules/` |
| `rules/documentation-lookup.md` | `.claude/rules/` |
| `rules/agents-system.md` | `.claude/rules/` |
| `skills/pr-check/` | `.claude/skills/` |
| `skills/deps-update/` | `.claude/skills/` |
| `skills/adr-writer/` | `.claude/skills/` |
| `skills/skill-writer/` | `.claude/skills/` |
| `skills/agent-writer/` | `.claude/skills/` |
| `commands/plan.md` | `.claude/commands/` |
| `commands/check.md` | `.claude/commands/` |
| `commands/fix.md` | `.claude/commands/` |
| `commands/review.md` | `.claude/commands/` |
| `commands/test.md` | `.claude/commands/` |

### If Beads Enabled

| Source | Destination |
|--------|-------------|
| `rules/beads-workflow.md` | `.claude/rules/` |
| `skills/beads-cleanup/` | `.claude/skills/` |
| `commands/work.md` | `.claude/commands/` |
| `commands/status.md` | `.claude/commands/` |

### If OpenSpec Enabled

| Source | Destination |
|--------|-------------|
| `rules/openspec.md` | `.claude/rules/` |
| `skills/quality/` | `.claude/skills/` |
| `commands/openspec/` | `.claude/commands/` |

### If Beads + OpenSpec Enabled

| Source | Destination |
|--------|-------------|
| `rules/workflow-integration.md` | `.claude/rules/` |
| `commands/wrap.md` | `.claude/commands/` |

## Examples

```bash
# Full setup with all tools
~/.claude/skills/project-setup/setup-project.sh --tools=all --scaffold-rules

# Next.js project with all tools
~/.claude/skills/project-setup/setup-project.sh --tools=all --framework=nextjs --scaffold-rules

# Just beads for issue tracking
~/.claude/skills/project-setup/setup-project.sh --tools=beads --project-name=myapp

# Minimal setup (no tools)
~/.claude/skills/project-setup/setup-project.sh --tools=none
```

## After Setup

1. **Customize CLAUDE.md** - Add project description, commands, rules reference
2. **Customize _shared.yaml** - Add project-specific skills to bundles
3. **Customize scaffolded rules** - Fill in architecture.md, danger-zone.md, etc.
4. **Commit** (load gitbutler skill first with `/gitbutler`):
   ```bash
   but status                        # Review changes
   but branch new claude-setup       # Create branch
   # Stage files (use bulk-stage.sh for multiple files)
   ~/.claude/skills/gitbutler/bulk-stage.sh claude-setup .claude/ CLAUDE.md
   # Add .beads/ openspec/ if applicable
   but commit claude-setup --only -m "chore: add claude code configuration"
   ```

## Tool Installation

If tools are missing, install them:

| Tool | Install Command |
|------|-----------------|
| GitButler | `curl -fsSL https://app.gitbutler.com/install.sh \| sh` |
| Beads | `npm install -g beads-ui@latest` |
| OpenSpec | `npm install -g @fission-ai/openspec@latest` |

## Troubleshooting

### "bd: command not found"
Install beads: `npm install -g beads-ui@latest`

### "openspec: command not found"
Install openspec: `npm install -g @fission-ai/openspec@latest`

### Agent build fails
Install required packages: `npm install --save-dev yaml tsx`
Then rebuild: `npm run build:agents`

### "build:agents" script missing
The setup script adds this automatically. If missing, add manually:
```bash
npm install --save-dev yaml tsx
npm pkg set scripts.build:agents="npx tsx .claude/scripts/build-agents.ts"
```
