---
name: template-updater
description: >
  Propagate project .claude/ improvements to ~/.claude/template/.
  Auto-invokes after editing skills/rules that exist in both locations.
allowed-tools: [Bash]
---

# Template Updater

Sync project `.claude/` improvements back to `~/.claude/template/` and audit permissions for migration opportunities.

## Features

1. **Template Sync** - Propagate skill/rule improvements to global template
2. **Permission Audit** - Identify local permissions that could be global

## Usage

```bash
~/.claude/skills/template-updater/sync-to-template.sh [--report|--auto|--force]
```

| Flag | Behavior |
|------|----------|
| (none) | Same as `--report` |
| `--report` | Show what would change, no modifications (default) |
| `--auto` | Apply all safe updates to template |
| `--force` | Update everything including protected (dangerous) |

## How It Works

The script only syncs files that **already exist in the template**. This prevents project-specific files from polluting the global template.

| File Category | Behavior |
|---------------|----------|
| Exists in both, content differs | Candidate for sync |
| Only in project | Ignored (project-specific) |
| Only in template | N/A (doesn't affect project→template) |
| Protected files | Skipped (shown in report) |

## Protected Files

Never synced to template (contain project-specific content):
- `CLAUDE.md` - Project documentation
- `agents-src/_shared.yaml` - Project skill/rule configuration

## Project-Specific Files

Skipped automatically (generated or customized per-project):
- `agents/*.md` - Generated from project-specific `_shared.yaml`

## Quick Check

```bash
~/.claude/skills/template-updater/sync-to-template.sh
```

This will show what's changed without modifying anything.

## Apply Updates

```bash
~/.claude/skills/template-updater/sync-to-template.sh --auto
```

This will:
1. Find files that exist in both project and template
2. Copy changed files from project to template
3. Show summary

## After Sync

**Load the gitbutler skill first** (`/gitbutler`), then commit the template changes:

```bash
cd ~/.claude && but status          # Review changes
but branch new template-sync        # Create branch (if needed)
but stage <file-id> template-sync   # Stage changed files
but commit template-sync --only -m "chore: update template"
```

## When to Use

- After improving a generic skill (deps-update, pr-check, etc.)
- After updating workflow rules (beads-workflow, landing-the-plane, etc.)
- After fixing issues in shared patterns
- When `settings.local.json` has grown with many permissions

---

## Permission Audit

Identify permissions in `.claude/settings.local.json` that could move to global `~/.claude/settings.json`.

### Usage

```bash
~/.claude/skills/template-updater/audit-permissions.sh [--report|--json]
```

| Flag | Behavior |
|------|----------|
| (none) | Same as `--report` |
| `--report` | Human-readable categorized report (default) |
| `--json` | JSON output for programmatic use |

### How It Works

The script categorizes each permission in `settings.local.json`:

| Category | Description | Action |
|----------|-------------|--------|
| **Global candidates** | Generic tools (npm, docker, lsof, etc.) | Consider moving to global |
| **Project-specific** | Database CLIs, project MCP servers | Keep local |
| **Already global** | Already in `~/.claude/settings.json` | Can remove from local |
| **Needs review** | Couldn't auto-classify | Manual decision |

### Example Output

```
=== Permission Audit Report ===

Candidates for global settings:
(These look generic enough to move to ~/.claude/settings.json)
  + Bash(npm run:*)
  + Bash(docker exec:*)
  + Skill(frontend-design)

Project-specific (keep local):
  - Bash(npx supabase:*)
  - mcp__supabase__execute_sql

Summary:
  Global candidates:  3
  Needs review:       0
  Project-specific:   2
  Already global:     5
```

### After Audit

1. Review candidates and decide which to migrate
2. Add to `~/.claude/settings.json`
3. Remove from `.claude/settings.local.json`

---

## Design Philosophy

- **Conservative by default** - Report mode, not auto-apply
- **Template-first** - Only syncs files that already exist in template
- **No guessing** - Deterministic rules, no AI classification needed
- **Complements project-sync** - Bidirectional workflow
