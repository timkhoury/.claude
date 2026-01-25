---
name: project-sync
description: >
  Sync project .claude/ with ~/.claude/template/. Detects technologies
  to copy only relevant rules.
allowed-tools: [Bash, AskUserQuestion]
---

# Project Sync

Sync project `.claude/` with `~/.claude/template/` using the deterministic sync script.

## Usage

```bash
~/.claude/skills/project-sync/sync-project.sh
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
| `openspec/` | OpenSpec | `workflow/openspec.md` |
| Both | Beads + OpenSpec | `workflow/workflow-integration.md`, `wrap.md` |

**Files for disabled tools are skipped**, not copied.

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
~/.claude/skills/project-sync/sync-project.sh
```

The script reports:
1. Detected technologies (package.json, config files, directories)
2. Detected tools (beads, openspec)
3. **Updated** - Files that differ from template
4. **Added** - Files missing from project
5. **Skipped** - Files for undetected technologies/tools
6. **Protected** - Files that need manual review (CLAUDE.md, _project.yaml)
7. **Unused** - Rules in project for technologies no longer detected

## After Running

Review the report and copy files as needed:

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
