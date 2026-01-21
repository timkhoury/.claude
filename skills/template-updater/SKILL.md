---
name: template-updater
description: >
  Detect changes in project .claude/ directory and propagate template-worthy improvements
  back to ~/.claude/template/. Use when saying "update template", "sync to template",
  "propagate changes", or after making improvements to skills/rules that should be global.
  Auto-invoke IMMEDIATELY after editing any file in .claude/skills/ or .claude/rules/ that
  exists in both the project and ~/.claude/template/ - don't wait for user to ask.
allowed-tools: [Bash]
---

# Template Updater

Sync project `.claude/` improvements back to `~/.claude/template/` using the deterministic sync script.

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

```bash
cd ~/.claude
git diff                    # Review changes
git add . && git commit -m "chore: update template"
```

## When to Use

- After improving a generic skill (deps-update, pr-check, etc.)
- After updating workflow rules (beads-workflow, landing-the-plane, etc.)
- After fixing issues in shared patterns

## Design Philosophy

- **Conservative by default** - Report mode, not auto-apply
- **Template-first** - Only syncs files that already exist in template
- **No guessing** - Deterministic rules, no AI classification needed
- **Complements project-sync** - Bidirectional workflow
