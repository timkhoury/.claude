# Claude Code Project Template

This template provides a standardized Claude Code configuration with:

- **Agent YAML Build System** - Define agents in YAML, compile to markdown
- **Workflow Commands** - `/work`, `/wrap`, `/status` for beads + OpenSpec
- **Quality Gates** - Pre-PR checks via `/pr-check`
- **Session Management** - Landing the plane protocol

## Design Philosophy

**Template items should be generic and context-aware.**

Skills and rules in this template are designed to work across different projects by reading from project context rather than requiring per-project customization.

| Principle | Implementation |
|-----------|----------------|
| **Context over configuration** | Skills read commands from CLAUDE.md/rules, not hardcoded |
| **Generic instructions** | "Run the project's lint command" not "Run `npm run lint`" |
| **Project rules are the source of truth** | CLAUDE.md defines commands, patterns, architecture |
| **Minimize template edits** | Copy template, edit CLAUDE.md, done |

**Example:** The `pr-check` skill says "Run the project's lint command" and looks at CLAUDE.md to find what that command is. This works for npm, cargo, go, python - any project.

**What goes where:**

| Location | Content | Edited? |
|----------|---------|---------|
| `~/.claude/template/` | Generic, reusable patterns | Rarely |
| `.claude/rules/` | Project-specific rules and patterns | Per project |
| `CLAUDE.md` | Project overview, commands, architecture | Per project |

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
│   ├── _shared.yaml      # Shared config
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

### 1. Edit CLAUDE.md

This is where project-specific information lives:

```markdown
## Quick Commands

```bash
npm run dev          # Start dev server
npm run build        # Production build
npm run test         # Run tests
npm run lint         # Linter
npm run typecheck    # TypeScript checking
```
```

Skills like `pr-check` will read these commands from context.

### 2. Add Project-Specific Rules

Create rule files in `.claude/rules/`:

```markdown
# .claude/rules/architecture.md

## Route Structure

| Route | Purpose |
|-------|---------|
| `/api/*` | REST endpoints |
| `/app/*` | Next.js pages |
```

Reference in CLAUDE.md:

```markdown
## Rules Reference

| Rule File | Contents |
|-----------|----------|
| `architecture.md` | Route structure, data flow |
```

### 3. Configure Agent Build System (Optional)

If using the YAML agent build system:

```bash
# Install yaml package
npm install yaml

# Build agents from YAML
npx tsx .claude/scripts/build-agents.ts
```

Edit `.claude/agents-src/_shared.yaml` to add your project's skills and rules:

```yaml
skillSets:
  patterns:
    - your-pattern-skill

includes:
  architecture: "@/.claude/rules/architecture.md"

ruleBundles:
  implementation:
    - $includes.baseline
    - $includes.architecture
```

## Prerequisites

This template assumes you're using:

- **Beads** for issue tracking (`bd` CLI)
- **GitButler** for virtual branches (`but` CLI)
- **OpenSpec** for change management (optional)

If not using these tools, remove the related commands and rules.

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
