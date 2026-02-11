---
name: project-setup
description: >
  Initialize Claude Code configuration for new projects. Copies template,
  configures tools (GitButler, OpenSpec), and scaffolds rules.
  Use when setting up a new project or onboarding to Claude Code.
---

# Project Setup

Initialize Claude Code configuration using the deterministic setup script.

## Usage

```bash
~/.claude/skills/project-setup/setup-project.sh [options]
```

| Option | Description |
|--------|-------------|
| `--tools=TOOLS` | Tools to enable: `all`, `openspec`, `none` (default: `all`) |
| `--framework=NAME` | Framework: `nextjs`, `react`, `node`, `other` (optional) |
| `--scaffold-rules` | Create scaffolded rule files (overview.md, architecture.md) |
| `--skip-init` | Skip tool initialization (openspec init) |
| `--skip-build` | Skip agent building step |

## Interactive Workflow

When invoked as a skill, gather information first:

### Question 1: Tools

```
Header: "Tools"
Question: "Which tools do you want to enable?"
Options:
  - "All (Recommended)" → --tools=all
  - "OpenSpec only" → --tools=openspec
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
4. **Initializes tools** (openspec)
5. **Builds agents**

## What Gets Copied

Skills are **flattened** from template's nested structure to project's flat structure:
- Template: `skills/{category}/{skill}/` or `skills/tools/{tool}/{skill}/`
- Project: `skills/{skill}/`

### Always Copied

| Template Source | Project Destination |
|-----------------|---------------------|
| `CLAUDE.md` | `./CLAUDE.md` |
| `baseline-agent.md` | `.claude/baseline-agent.md` |
| `agents-src/` | `.claude/agents-src/` |
| `scripts/` | `.claude/scripts/` |
| `rules/workflow/` | `.claude/rules/workflow/` |
| `rules/meta/` | `.claude/rules/meta/` |
| `rules/patterns/` | `.claude/rules/patterns/` |
| `skills/quality/pr-check/` | `.claude/skills/pr-check/` |
| `skills/quality/review/` | `.claude/skills/review/` |
| `skills/automation/deps-updater/` | `.claude/skills/deps-updater/` |
| `skills/authoring/adr-writer/` | `.claude/skills/adr-writer/` |
| `skills/authoring/skill-writer/` | `.claude/skills/skill-writer/` |
| `skills/authoring/agent-writer/` | `.claude/skills/agent-writer/` |
| `skills/authoring/rule-writer/` | `.claude/skills/rule-writer/` |
| `commands/plan.md` | `.claude/commands/plan.md` |
| `commands/check.md` | `.claude/commands/check.md` |
| `commands/fix.md` | `.claude/commands/fix.md` |
| `commands/fix-tests.md` | `.claude/commands/fix-tests.md` |

### If OpenSpec Enabled

| Template Source | Project Destination |
|-----------------|---------------------|
| `skills/quality/rules-review/` | `.claude/skills/rules-review/` |
| `skills/tools/openspec/spec-review/` | `.claude/skills/spec-review/` |
| `commands/openspec/` | `.claude/commands/openspec/` |
| `commands/wrap.md` | `.claude/commands/wrap.md` |

## Examples

```bash
# Full setup with all tools
~/.claude/skills/project-setup/setup-project.sh --tools=all --scaffold-rules

# Next.js project with all tools
~/.claude/skills/project-setup/setup-project.sh --tools=all --framework=nextjs --scaffold-rules

# Minimal setup (no tools)
~/.claude/skills/project-setup/setup-project.sh --tools=none
```

## After Setup

1. **Customize CLAUDE.md** - Add project description, commands, rules reference
2. **Customize _shared.yaml** - Add project-specific skills to bundles
3. **Customize scaffolded rules** - Fill in overview.md, architecture.md
4. **Commit** (load gitbutler skill first with `/gitbutler`):
   ```bash
   but status                        # Review changes
   but branch new claude-setup       # Create branch
   # Stage files (use bulk-stage.sh for multiple files)
   ~/.claude/skills/gitbutler/bulk-stage.sh claude-setup .claude/ CLAUDE.md
   # Add openspec/ if applicable
   but commit claude-setup --only -m "chore: add claude code configuration"
   ```

## Tool Installation

If tools are missing, install them:

| Tool | Install Command |
|------|-----------------|
| GitButler | `curl -fsSL https://app.gitbutler.com/install.sh \| sh` |
| OpenSpec | `npm install -g @fission-ai/openspec@latest` |

## Troubleshooting

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
