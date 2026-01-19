---
name: project-sync
description: >
  Compare project Claude Code config against global template and apply updates.
  Use when saying "sync project", "update claude config", "check for template updates",
  or after updating ~/.claude/template/ to propagate changes to projects.
---

# Project Sync Guide

Compare and sync project `.claude/` configuration against `~/.claude/template/`.

## Prerequisites

- Project must have `.claude/` directory (run `project-setup` first if not)
- Template must exist at `~/.claude/template/`

## Sync Flow

### Phase 1: Inventory

Build file inventories for comparison:

```bash
# Template files
find ~/.claude/template -type f -name "*.md" -o -name "*.yaml" -o -name "*.ts" | sort

# Project files
find .claude -type f -name "*.md" -o -name "*.yaml" -o -name "*.ts" | sort
```

### Phase 2: Categorize Files

**File Categories:**

| Category | Template Path | Update Strategy |
|----------|---------------|-----------------|
| Scripts | `scripts/build-agents.ts` | Auto-update (no customization) |
| Baseline | `baseline-agent.md` | Auto-update (no customization) |
| Agent YAMLs | `agents-src/*.yaml` (except `_shared.yaml`) | Show diff, ask before updating |
| Shared Config | `agents-src/_shared.yaml` | Never auto-update (customized) |
| Rules | `rules/*.md` | Add if missing, show diff for existing |
| Skills | `skills/*/SKILL.md` | Add if missing, show diff for existing |
| Commands | `commands/*.md` | Add if missing, show diff for existing |
| CLAUDE.md | `CLAUDE.md` | Never auto-update (project-specific) |

### Phase 3: Detect Changes

For each template file, determine status:

```
Template File                    | Project Status
---------------------------------|---------------
scripts/build-agents.ts          | ✓ Up to date / ⚠ Outdated / ✗ Missing
baseline-agent.md                | ✓ Up to date / ⚠ Outdated / ✗ Missing
agents-src/code-reviewer.yaml    | ✓ Up to date / ⚠ Outdated / ✗ Missing
rules/beads-workflow.md          | ✓ Up to date / ⚠ Outdated / ✗ Missing
...
```

**Detection method:**
```bash
# Compare files (ignoring whitespace)
diff -q ~/.claude/template/<path> .claude/<path>
```

### Phase 4: Generate Report

Present findings to user:

```markdown
## Project Sync Report

### Summary
- **Up to date:** X files
- **Outdated:** Y files
- **Missing:** Z files
- **Project-only:** W files (not in template)

### Outdated Files (recommend update)

| File | Action |
|------|--------|
| `scripts/build-agents.ts` | Auto-update available |
| `agents-src/code-reviewer.yaml` | Review diff before updating |
| `rules/beads-workflow.md` | Review diff before updating |

### Missing Files (available to add)

| File | Description |
|------|-------------|
| `commands/wrap.md` | Session wrap command |
| `skills/new-skill/SKILL.md` | New skill from template |

### Protected Files (manual review only)

| File | Status |
|------|--------|
| `CLAUDE.md` | Template has updates (review manually) |
| `agents-src/_shared.yaml` | Template has updates (merge manually) |
```

### Phase 5: User Selection

Use `AskUserQuestion`:

```
Header: "Updates"
Question: "Which updates do you want to apply?"
Options:
  - "All safe updates (Recommended)" - Auto-update scripts, baseline, add missing
  - "Review each file" - Show diff for each, decide individually
  - "Only add missing" - Add new files, don't update existing
  - "None" - Just show report, no changes
MultiSelect: false
```

### Phase 6: Apply Updates

**For auto-update files:**
```bash
cp ~/.claude/template/scripts/build-agents.ts .claude/scripts/
cp ~/.claude/template/baseline-agent.md .claude/
```

**For add-missing files:**
```bash
# Create directory if needed
mkdir -p .claude/skills/new-skill/
cp ~/.claude/template/skills/new-skill/SKILL.md .claude/skills/new-skill/
```

**For review-each mode:**

For each outdated file, show diff and ask:

```bash
diff ~/.claude/template/<path> .claude/<path>
```

Then ask:
```
Header: "Update"
Question: "Update .claude/<path>?"
Options:
  - "Yes" - Replace with template version
  - "No" - Keep current version
  - "Show full diff" - Display complete diff
MultiSelect: false
```

### Phase 7: Rebuild Agents

If any agent YAML files were updated:

```bash
npx tsx .claude/scripts/build-agents.ts
```

### Phase 8: Summary

```markdown
## Sync Complete

### Applied Updates
- Updated: `scripts/build-agents.ts`
- Updated: `baseline-agent.md`
- Added: `commands/wrap.md`
- Rebuilt agents from YAML

### Skipped (manual review needed)
- `agents-src/_shared.yaml` - Template has new skillSets
- `CLAUDE.md` - Template has new sections

### Next Steps
1. Review skipped files for manual updates
2. Run `git diff` to review all changes
3. Commit: `git commit -am "chore: sync claude config with template"`
```

## Handling _shared.yaml Updates

Since `_shared.yaml` contains project customizations, never auto-update. Instead:

1. **Detect new template features:**
   ```bash
   # Show what's new in template
   diff ~/.claude/template/agents-src/_shared.yaml .claude/agents-src/_shared.yaml
   ```

2. **Report additions:**
   ```
   Template _shared.yaml has new entries:
   - New skillSet: `security`
   - New include: `apiPatterns`
   - New ruleBundle: `security`

   Consider adding these to your project's _shared.yaml manually.
   ```

## Handling CLAUDE.md Updates

Template CLAUDE.md is a skeleton. Project CLAUDE.md has real content. Never replace.

Instead, detect structural changes:

1. **Check for new sections in template**
2. **Report what might be missing:**
   ```
   Template CLAUDE.md has sections not found in project:
   - "## New Section Name"

   Consider reviewing ~/.claude/template/CLAUDE.md for ideas.
   ```

## Quick Commands

| Command | Purpose |
|---------|---------|
| `project-sync` | Full sync workflow |
| `project-sync --report` | Just show report, no changes |
| `project-sync --auto` | Apply all safe updates automatically |

## File Reference

### Safe to Auto-Update

These files have no project-specific customization:

- `scripts/build-agents.ts` - Build script
- `baseline-agent.md` - Base agent instructions

### Add If Missing

These are additive and don't conflict:

- `rules/*.md` - Rule files
- `skills/*/SKILL.md` - Skill files
- `commands/*.md` - Command files
- `agents-src/*.yaml` - Agent definitions (except _shared)

### Never Auto-Update

These contain project-specific content:

- `CLAUDE.md` - Project documentation
- `agents-src/_shared.yaml` - Project skill/rule configuration
- Any file with `<!-- PROJECT-SPECIFIC -->` marker

## Troubleshooting

### "Template not found"
Ensure `~/.claude/template/` exists. Run `project-setup` in a new project to create it, or manually create the template structure.

### "No .claude/ directory"
Project hasn't been set up yet. Run `project-setup` first.

### Merge conflicts in _shared.yaml
Manually merge changes. Compare:
```bash
diff ~/.claude/template/agents-src/_shared.yaml .claude/agents-src/_shared.yaml
```
