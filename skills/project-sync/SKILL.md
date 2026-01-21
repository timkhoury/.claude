---
name: project-sync
description: >
  Compare project Claude Code config against global template and apply updates.
  Use when saying "sync project", "update claude config", "check for template updates",
  or after updating ~/.claude/template/ to propagate changes to projects.
allowed-tools: [Bash]
---

# Project Sync

Sync project `.claude/` with `~/.claude/template/` using the deterministic sync script.

## Usage

```bash
~/.claude/skills/project-sync/sync-project.sh [--auto|--report|--force]
```

| Flag | Behavior |
|------|----------|
| (none) | Same as `--auto` |
| `--auto` | Apply all safe updates, skip protected files |
| `--report` | Show what would change, no modifications |
| `--force` | Update everything including protected (dangerous) |

## Tool Detection

The script detects enabled tools by directory existence:

| Directory | Detected Tool | Files Synced |
|-----------|---------------|--------------|
| `.beads/` | Beads | `beads-workflow.md`, `beads-cleanup/`, `work.md`, `status.md` |
| `openspec/` | OpenSpec | `openspec.md` |
| Both | Beads + OpenSpec | `workflow-integration.md`, `wrap.md` |

**Files for disabled tools are skipped**, not copied. This matches what `project-setup` does during initial setup.

## Quick Sync

```bash
~/.claude/skills/project-sync/sync-project.sh
```

This will:
1. Detect enabled tools (beads, openspec)
2. Compare relevant template files with project
3. Update outdated files
4. Add missing files
5. Skip tool-specific files if tool not enabled
6. Skip protected files (CLAUDE.md, _shared.yaml)
7. Show summary

## Protected Files

Never auto-updated (contain project-specific content):
- `CLAUDE.md` - Project documentation
- `agents-src/_shared.yaml` - Project skill/rule configuration
- Files with `<!-- PROJECT-SPECIFIC -->` marker

## Agent YAMLs

Agent definition files (`agents-src/*.yaml` except `_shared.yaml`) **are synced** from template. This keeps agent definitions generic across projects. Project-specific customization happens through:
- `_shared.yaml` - Define which rules go in each bundle
- Rule files - Create project-specific rules included via bundles

## After Sync

```bash
# Review changes
git diff .claude/

# If agent YAMLs changed, rebuild
npx tsx .claude/scripts/build-agents.ts

# Commit
git add .claude/ && git commit -m "chore: sync claude config"
```

## Design Philosophy

Template files follow **context-over-configuration**:
- Skills/rules are generic and read from project context
- Syncing should "just work" without per-file decisions
- Tool-specific files only sync when that tool is enabled
- Only `_shared.yaml` and `CLAUDE.md` need project customization
