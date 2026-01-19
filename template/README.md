# Claude Code Project Template

This template provides a standardized Claude Code configuration with:

- **Agent YAML Build System** - Define agents in YAML, compile to markdown
- **Workflow Commands** - `/work`, `/wrap`, `/status` for beads + OpenSpec
- **Quality Gates** - Parameterized pr-check skill
- **Session Management** - Landing the plane protocol

## Quick Setup

```bash
# Copy template to your project
cp -r ~/.claude/template/.  /path/to/your/project/.claude/
cp ~/.claude/template/CLAUDE.md /path/to/your/project/

# Or use rsync to merge with existing .claude/
rsync -av ~/.claude/template/ /path/to/your/project/.claude/
```

## Structure

```
.claude/
├── agents-src/           # YAML agent definitions (source)
│   ├── _shared.yaml      # Shared config (customize this!)
│   ├── code-reviewer.yaml
│   ├── task-implementer.yaml
│   ├── planner-researcher.yaml
│   └── tester.yaml
├── agents/               # Generated markdown (don't edit)
├── baseline-agent.md     # Common agent instructions
├── commands/             # Slash commands
│   ├── work.md           # /work - execute beads tasks
│   ├── wrap.md           # /wrap - session completion
│   └── status.md         # /status - workflow overview
├── rules/                # Modular rules
│   ├── beads-workflow.md
│   ├── openspec.md
│   ├── workflow-integration.md
│   └── landing-the-plane.md
├── skills/               # Auto-activated skills
│   ├── pr-check/         # Pre-PR quality checks
│   └── beads-cleanup/    # Database maintenance
└── scripts/
    └── build-agents.ts   # Agent compiler
```

## Customization Steps

### 1. Configure `_shared.yaml`

Edit `.claude/agents-src/_shared.yaml` to add your project's skills and rules:

```yaml
skillSets:
  patterns:
    - your-pattern-skill
    - another-skill

includes:
  # Add your rule files
  architecture: "@/.claude/rules/architecture.md"
  patterns: "@/.claude/rules/patterns.md"

ruleBundles:
  implementation:
    - $includes.baseline
    - $includes.architecture
    - $includes.patterns
```

### 2. Build Agents

```bash
# Install yaml package if needed
npm install yaml

# Build agents from YAML
npx tsx .claude/scripts/build-agents.ts

# Or add to package.json:
# "build:agents": "tsx .claude/scripts/build-agents.ts"
```

### 3. Configure pr-check

Edit `.claude/skills/pr-check/SKILL.md` with your project's commands:

```markdown
| Check | Your Project |
|-------|--------------|
| Lint | `npm run lint` |
| Typecheck | `npm run typecheck` |
| Test | `npm run test` |
| Build | `npm run build` |
```

### 4. Update CLAUDE.md

Edit `CLAUDE.md` with your project's:
- Overview and quick commands
- Architecture description
- Danger zone rules
- Links to documentation

## Prerequisites

This template assumes you're using:

- **Beads** for issue tracking (`bd` CLI)
- **GitButler** for virtual branches (`but` CLI)
- **OpenSpec** for change management (optional)

If not using these tools, you can remove the related commands and rules.

## Global Skills

This template works alongside global skills in `~/.claude/skills/`:

- `gitbutler` - Git workflow
- `adr-writer` - Architecture Decision Records
- `skill-writer` - Writing skills
- `agent-writer` - Writing agents
- `claude-md-editor` - CLAUDE.md best practices

These are automatically available in all projects.

## Workflow Overview

### Starting Work

```bash
bd ready              # Find available tasks
/work <task-id>       # Execute a task
/work <epic-id>       # Execute all tasks in epic
```

### During Work

```bash
/status               # Check current state
# Implement, commit via gitbutler
```

### Ending Session

```bash
/wrap                 # Complete session checklist
```

## Adding Project-Specific Rules

Create rule files in `.claude/rules/`:

```markdown
# .claude/rules/my-patterns.md

## My Pattern Rules

- Rule 1
- Rule 2
```

Then reference in `_shared.yaml`:

```yaml
includes:
  myPatterns: "@/.claude/rules/my-patterns.md"

ruleBundles:
  implementation:
    - $includes.myPatterns
```

Rebuild agents to apply: `npx tsx .claude/scripts/build-agents.ts`
