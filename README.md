# .claude

Personal Claude Code configuration repository serving as both global preferences and a project template system.

## What This Does

This repository provides:

- **Global Configuration** - Preferences, rules, and settings applied across all Claude Code projects
- **Project Template** - A baseline `.claude/` directory that syncs to projects
- **Workflow Skills** - Automation for common tasks like git operations, project sync, and reviews
- **Agent System** - YAML-defined agents compiled to markdown for multi-role assistance

## Directory Structure

```
.claude/
├── CLAUDE.md              # Global preferences (git workflow, code style, communication)
├── settings.json          # Model, plugins, permissions
├── rules/                 # Always-loaded rules
│   └── git-rules.md       # Git workflow constraints (GitButler, conventional commits)
├── skills/                # On-demand workflows
│   ├── gitbutler/         # Virtual branch management
│   ├── project-setup/     # Bootstrap new projects
│   ├── project-sync/      # Sync template → project
│   ├── template-updater/  # Sync project → template
│   └── ...
└── template/              # Project template baseline
    ├── rules/             # Tech-specific rules (Next.js, Supabase, etc.)
    ├── skills/            # Project skills (reviews, quality checks)
    ├── commands/          # Slash commands (/plan, /check, /review, etc.)
    └── agents-src/        # YAML agent definitions
```

## Key Concepts

### Rules vs Skills

- **Rules** are always loaded and define patterns, conventions, and constraints
- **Skills** are invoked on-demand for workflows that require step-by-step processes

### Bidirectional Sync

The template system supports two-way synchronization:

1. `project-sync` - Syncs relevant template content to a project (technology-aware)
2. `template-updater` - Propagates improvements from a project back to the template

### GitButler Integration

All git operations use GitButler virtual branches instead of traditional git:

| Instead of | Use |
|------------|-----|
| `git commit` | `but commit <branch> --only -m "..."` |
| `git push` | `but push <branch>` |
| `git status` | `but status` |

## Global Skills

| Skill | Purpose |
|-------|---------|
| `gitbutler` | Git operations via GitButler virtual branches |
| `project-setup` | Initialize new projects with template and tools |
| `project-sync` | Sync template rules/skills to a project |
| `template-updater` | Sync project improvements back to template |
| `sync` | Bidirectional sync (runs both directions) |
| `systems-review` | Aggregate status of all review skills |
| `template-review` | Validate template structure and integrity |
| `permissions-review` | Audit settings.json for global promotion |
| `claude-md-editor` | CLAUDE.md maintenance and best practices |

## Tool Integrations

- **GitButler** - Required for git operations (virtual branches)
- **Beads** - Optional issue tracking with dependencies (`bd` CLI)
- **OpenSpec** - Optional change/spec management (`openspec` CLI)

## Getting Started

### For a new project

```bash
# From the new project directory
claude  # Start Claude Code
# Then: /project-setup
```

This initializes the project with the template and configures tools.

### Sync template to existing project

```bash
# From the project directory
claude
# Then: /project-sync
```

Reviews differences and syncs relevant rules based on detected technologies.

## Configuration

### settings.json

Key settings:
- **Model**: `opus`
- **Plugins**: frontend-design, security-guidance, beads
- **Permissions**: Granular bash/skill access for GitButler, Beads, npm, Docker, GitHub

### CLAUDE.md

Global preferences:
- Git workflow (GitButler, conventional commits, single-line messages)
- Code style (no emojis, minimal changes, avoid over-engineering)
- Communication (concise, no time estimates, cite file:line)
- Session management (track work, land the plane, document remaining work)

## Design Principles

**Context-over-Configuration** - Skills read from project context rather than hardcoding commands. "Run the project's lint command" works across npm, cargo, go, python, etc.

**Deterministic Systems** - Sync scripts report differences but don't auto-apply. Users choose what to sync.

**Landing the Plane** - Ensure all work is committed and pushed before ending sessions. No loose ends.
