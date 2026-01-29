---
name: template-updater
description: >
  Propagate project .claude/ improvements to ~/.claude/template/.
  Auto-invokes after editing skills/rules that exist in both locations.
allowed-tools: [Bash]
---

# Template Updater

Sync project `.claude/` improvements back to `~/.claude/template/`.

## Usage

```bash
~/.claude/skills/template-updater/sync-to-template.sh
```

The script is **report-only** - it shows what differs between project and template but makes no changes. Claude reads the report and decides which files to copy using Read/Write tools.

## How It Works

The script only syncs files that **already exist in the template**. This prevents project-specific files from polluting the global template.

| File Category | Behavior |
|---------------|----------|
| Exists in both, content differs | Candidate for sync |
| Only in project | Ignored (project-specific) |
| Only in template | N/A (doesn't affect project→template) |
| Protected files | Skipped (shown in report) |

## Path Mapping

The template uses hierarchical organization while projects use flat directories:

| Template | Project |
|----------|---------|
| `skills/quality/review/` | `skills/review/` |
| `skills/quality/pr-check/` | `skills/pr-check/` |
| `skills/workflow/gitbutler/` | `skills/gitbutler/` |

The script handles this mapping internally - reported paths are template-relative.

## Protected Files

Never synced to template (contain project-specific content):
- `CLAUDE.md` - Project documentation
- `agents-src/_shared.yaml` - Project skill/rule configuration

## Project-Specific Files

Skipped automatically (generated or customized per-project):
- `agents/*.md` - Generated from project-specific `_shared.yaml`

## Running the Script

```bash
~/.claude/skills/template-updater/sync-to-template.sh
```

The script reports:
1. **New** - Files in project that could be added to template
2. **Changed** - Files that differ from template
3. **Skipped (generated)** - Per-project files (agents/*.md)
4. **Skipped (protected)** - Project-specific files (CLAUDE.md, _project.yaml)

## After Running

### 1. Sync Changed Files

Copy all files listed as "Changed" to the template.

### 2. Sync Additional Skill Files

For skills that exist in the template, **sync ALL files in the skill directory**, not just SKILL.md. This includes reference files like `PATTERNS.md`, `REFERENCE.md`, `CHECKLIST.md`, and helper scripts.

**How to identify template skills:** Check if the skill directory exists in `~/.claude/template/skills/`. If it does, sync all files from the project skill directory.

**Project-specific skills** (don't sync): Skills like `content-sync/`, `env-setup/`, `troubleshoot/` that only exist in the project and handle project-specific concerns.

### 3. Copy Files

```bash
# Copy all files in a skill directory
cp .claude/skills/rules-review/*.md ~/.claude/template/skills/quality/rules-review/
cp .claude/skills/rules-review/*.sh ~/.claude/template/skills/quality/rules-review/
```

Or use Claude's Read/Write tools to copy files based on the report.

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

## Design Philosophy

- **Conservative by default** - Report mode, not auto-apply
- **Template-first** - Only syncs files that already exist in template
- **No guessing** - Deterministic rules, no AI classification needed
- **Complements project-sync** - Bidirectional workflow
