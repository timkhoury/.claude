---
name: project-updater
description: >
  Update project .claude/ configuration from ~/.claude/template/. Detects
  technologies to copy only relevant rules. Use when updating a project
  from template or after template changes.
allowed-tools: [Bash, AskUserQuestion]
---

# Project Updater

Update project `.claude/` from `~/.claude/template/` using the deterministic update script.

## Usage

```bash
~/.claude/skills/project-updater/update-project.sh
```

The script is **report-only** - it shows what differs between template and project but makes no changes. Claude reads the report and decides which files to copy using Read/Write tools.

## Technology Detection

The script uses `~/.claude/scripts/detect-technologies.sh` to determine which tech rules to sync:

| Detection Method | Examples |
|-----------------|----------|
| package.json dependencies | `next`, `@supabase/supabase-js`, `tailwindcss` |
| Config files | `next.config.js`, `vitest.config.ts`, `playwright.config.ts` |
| Directories | `supabase/`, `components/ui/` |

**Only rules for detected technologies are synced.** When a technology is removed from a project, its rules become "unused".

## Tool Detection

The script also detects workflow tools by directory existence:

| Directory | Detected Tool | Files Synced |
|-----------|---------------|--------------|
| `.beads/` | Beads | `workflow/beads-workflow.md`, `beads-cleanup/`, `work.md`, `status.md` |
| `openspec/` | OpenSpec | `workflow/openspec.md`, hooks (see below) |
| Both | Beads + OpenSpec | `workflow/workflow-integration.md`, `wrap.md` |

**Files for disabled tools are skipped**, not copied.

## Hook Syncing

The script also syncs Claude Code hooks from template based on tool detection. Hooks are defined in `~/.claude/config/sync-config.yaml` under each tool's `hooks` section.

**Example hook definition in sync-config.yaml:**
```yaml
tools:
  openspec:
    detect:
      directories:
        - openspec/
    hooks:
      PostToolUse:
        - matcher: "ExitPlanMode"
          type: "prompt"
          prompt: "/execute-plan"
          _templateId: "openspec:execute-plan"
```

**How it works:**
- Template hooks have a `_templateId` field to distinguish them from project hooks
- Project hooks without `_templateId` are preserved
- Same `_templateId` = project override wins (template version skipped)
- Hooks are added to `.claude/settings.json`

**Disable a template hook:**
Add the template ID to `_disabledTemplateHooks` in project settings.json:
```json
{
  "_disabledTemplateHooks": ["openspec:execute-plan"],
  "hooks": { ... }
}
```

**Apply hooks:**
```bash
~/.claude/skills/project-updater/sync-hooks.sh --apply
```

## Folder Structure

Template rules are organized in folders:

```
~/.claude/template/rules/
├── workflow/     # Beads, OpenSpec, session management
├── tech/         # Technology-specific (Next.js, Supabase, etc.)
├── patterns/     # Cross-cutting patterns (data retention, organization)
└── meta/         # Process rules (research, documentation lookup)
```

The sync script handles nested folders automatically. Project-specific rules should go in `.claude/rules/project/` which is NOT synced from template.

## Path Mapping

The template uses hierarchical organization while projects use flat directories for skills:

| Template | Project |
|----------|---------|
| `skills/quality/review/` | `skills/review/` |
| `skills/quality/pr-check/` | `skills/pr-check/` |
| `skills/workflow/gitbutler/` | `skills/gitbutler/` |

The script handles this mapping internally - reported paths are template-relative.

## Opting Out of Template Files (.syncignore)

Create `.claude/.syncignore` to permanently opt out of specific template files:

```
# Don't sync frontend design skill - not a frontend project
skills/fed/

# Using custom auth, don't want template's supabase rules
rules/tech/supabase*.md

# Skip a specific workflow rule
rules/workflow/some-rule.md
```

**Patterns:**
- Glob patterns supported (`*.md`, `skills/*/`)
- Directory patterns should end with `/`
- Comments start with `#`
- One pattern per line

**When to use .syncignore:**
- Project will never need certain template files
- Template files conflict with project-specific implementations
- Cleaner than repeatedly declining to add files

**Report output:**
```
Ignored (per .syncignore):
  - skills/fed/ (per .syncignore)
  - rules/tech/supabase*.md (per .syncignore)
```

## Pruning Unused Rules

When technologies are removed from a project, the sync script identifies orphaned rules in the "Unused" section:

```
Unused (tech not detected):
  - rules/tech/vue.md
  - rules/tech/angular.md

Note: Remove unused rules manually if desired.
```

**The script does not auto-remove files.** When you see unused rules:

1. Review the list - confirm the technology is truly no longer used
2. If removing, use AskUserQuestion to confirm with the user:

```
Which unused rules should be removed?
- [ ] rules/tech/vue.md (vue not detected)
- [ ] rules/tech/angular.md (angular not detected)
- [ ] Keep all
```

3. Remove confirmed files: `rm .claude/rules/tech/vue.md`

**Rules in `rules/project/` are never flagged as unused** - they're project-specific and not tied to technology detection.

## Running the Script

```bash
~/.claude/skills/project-updater/update-project.sh
```

The script reports:
1. Detected technologies (package.json, config files, directories)
2. Detected tools (beads, openspec)
3. **Changed** - Files that differ, with timestamps and sync direction
4. **Added** - Files missing from project
5. **Skipped** - Files for undetected technologies/tools
6. **Protected** - Files that need manual review (CLAUDE.md, _project.yaml)
7. **Unused** - Rules in project for technologies no longer detected
8. **Hooks** - Template hooks to add based on detected tools

## Determining Sync Direction

The script compares file modification timestamps and shows direction for each changed file:

| Direction | Meaning | Action |
|-----------|---------|--------|
| `template is newer -> sync to project` | Template was edited more recently | Copy template → project |
| `project is newer -> use /template-updater` | Project was edited more recently | Skip (run `/template-updater` instead) |

**Only sync files where the template is newer.** Files where the project is newer should be pushed to the template via `/template-updater`, not overwritten.

## After Running

Review the report and copy files where the template is newer:

```bash
# Read a file that needs updating
cat ~/.claude/template/rules/tech/nextjs.md

# Copy it to project
cp ~/.claude/template/rules/tech/nextjs.md .claude/rules/tech/nextjs.md
```

Or use Claude's Read/Write tools to selectively copy files based on the report.

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

**Load the gitbutler skill first** (`/gitbutler`), then commit the changes:

```bash
but status                          # Review changes
npm run build:agents                # If agent YAMLs changed (script auto-adds npm script if missing)
but stage <file-id> <branch>        # Stage changed files
but commit <branch> --only -m "chore: sync claude config"
```

**Consider running `/rules-review`** if:
- New tech rules were synced (verify no project content leaked into tech rules)
- Project has grown significantly since last review
- Rules feel disorganized or overlapping

## Design Philosophy

Template files follow **context-over-configuration**:
- Skills/rules are generic and read from project context
- Syncing should "just work" without per-file decisions
- Tool-specific files only sync when that tool is enabled
- Only `_shared.yaml` and `CLAUDE.md` need project customization
