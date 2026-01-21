---
name: template-updater
description: >
  Detect changes in project .claude/ directory and propagate template-worthy improvements
  back to ~/.claude/template/. Use when saying "update template", "sync to template",
  "propagate changes", or after making improvements to skills/rules that should be global.
---

# Template Updater

Reverse of `project-sync`: detects project improvements and propagates them to the global template.

## Overview

| Direction | Tool | Purpose |
|-----------|------|---------|
| template → project | `project-sync` | Pull updates |
| project → template | `template-updater` | Push improvements |

## Phase 1: Detect Changed Files

Compare project `.claude/` files against `~/.claude/template/`:

```bash
# Find files that exist in both locations
for f in $(find .claude -type f -name "*.md" -o -name "*.yaml" -o -name "*.ts" 2>/dev/null); do
  template_path="$HOME/.claude/template/${f#.claude/}"
  if [ -f "$template_path" ]; then
    if ! diff -q "$f" "$template_path" >/dev/null 2>&1; then
      echo "CHANGED: $f"
    fi
  else
    echo "NEW: $f"
  fi
done
```

Organize findings into categories:
- **Changed files** - Exist in both, content differs
- **New files** - Exist in project only, might be additions

## Phase 2: Classify Changes

Infer classification from file content and naming. No markers needed.

### Always Skip (Project-Specific)

These files contain project-specific configuration and should never be synced:

| File | Reason |
|------|--------|
| `CLAUDE.md` | Project documentation, tech stack, commands |
| `agents-src/_shared.yaml` | Project-specific skill/rule includes |
| `rules/architecture.md` | Project architecture details |
| `rules/danger-zone.md` | Project-specific anti-patterns |
| `rules/project-overview.md` | Project description |
| `rules/environment-setup.md` | Project env vars |
| `rules/troubleshooting.md` | Project-specific issues |

### Skip if Contains Project References

Scan file content for project-specific indicators:

```
# Framework references (skip if found)
- Supabase, Next.js, React, Stripe, Tailwind
- @supabase/, @stripe/, @tanstack/
- specific table names, API endpoints

# Project paths (skip if found)
- src/app/, src/lib/, src/components/
- specific route patterns

# Environment variables (skip if found)
- NEXT_PUBLIC_*, SUPABASE_*, STRIPE_*
```

**Heuristic:** If a file contains 3+ project-specific references, classify as project-specific.

### Likely Template-Worthy

Files that are generic and work across projects:

| Category | Examples |
|----------|----------|
| **Workflow rules** | `beads-workflow.md`, `openspec.md`, `workflow-integration.md`, `landing-the-plane.md` |
| **Generic skills** | `deps-update/`, `pr-check/`, `adr-writer/`, `skill-writer/`, `agent-writer/` |
| **Build scripts** | `scripts/build-agents.ts` |
| **Commands** | `commands/work.md`, `commands/status.md`, `commands/wrap.md` |
| **Patterns** | `research-patterns.md`, `documentation-lookup.md`, `deterministic-systems.md` |

### Classification Decision Tree

```
Is file in "Always Skip" list?
├─ Yes → Skip
└─ No → Continue

Does filename suggest project-specific content?
├─ Yes (architecture, environment, troubleshooting) → Skip
└─ No → Continue

Scan file content for project references:
├─ 3+ framework/path references → Skip (project-specific)
└─ 0-2 references → Likely template-worthy
```

## Phase 3: Present Findings

Display categorized changes and use AskUserQuestion for selection.

### Output Format

```markdown
## Template Update Analysis

### Files with Changes (template-worthy)
| File | Status | Change Summary |
|------|--------|----------------|
| skills/deps-update/SKILL.md | Modified | Added ecosystem grouping |
| rules/beads-workflow.md | Modified | Updated sync commands |

### New Files (template-worthy)
| File | Description |
|------|-------------|
| skills/new-skill/SKILL.md | New skill for X |

### Skipped (project-specific)
| File | Reason |
|------|--------|
| rules/architecture.md | Contains project architecture |
| CLAUDE.md | Project documentation |
```

### Interactive Selection

Use AskUserQuestion with multiSelect for file selection:

```
Question: "Which changes should be propagated to the global template?"
Header: "Template"
MultiSelect: true
Options:
  - "skills/deps-update/SKILL.md - Added ecosystem grouping"
  - "rules/beads-workflow.md - Updated sync commands"
  - "All template-worthy changes (Recommended)"
  - "None - just show the analysis"
```

## Phase 4: Apply Updates

For each selected file, copy to template:

```bash
# Copy file to template
cp ".claude/$file" "$HOME/.claude/template/$file"
```

### Create Missing Directories

```bash
# Ensure parent directory exists
mkdir -p "$(dirname "$HOME/.claude/template/$file")"
```

### Verification

After copying, show confirmation:

```markdown
## Updates Applied

| Source | Destination | Status |
|--------|-------------|--------|
| .claude/skills/deps-update/SKILL.md | ~/.claude/template/skills/deps-update/SKILL.md | Copied |

### Next Steps

1. Review changes in ~/.claude/template/
2. Commit template changes: `cd ~/.claude && git add . && git commit -m "chore: update template"`
3. Run `project-sync` in other projects to propagate
```

## Phase 5: Diff Preview (Optional)

If user wants to see specific changes before applying:

```bash
# Show diff for a specific file
diff -u "$HOME/.claude/template/$file" ".claude/$file"
```

Present as:

```markdown
### Diff: skills/deps-update/SKILL.md

```diff
- Old content
+ New content
```
```

## Quick Reference

### Trigger Phrases

- "update template"
- "sync to template"
- "propagate changes"
- "push to template"
- "template-updater"

### Common Workflows

**After improving a skill:**
```
User: I updated the deps-update skill, sync it to template
Claude: [Runs template-updater, detects deps-update changes, offers to sync]
```

**Check for any template-worthy changes:**
```
User: /template-updater
Claude: [Analyzes all .claude/ files, presents template-worthy changes]
```

**Selective sync:**
```
User: Only sync the workflow rules to template
Claude: [Filters to rules/*, presents those for selection]
```

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Sync CLAUDE.md to template | Overwrites template placeholder |
| Sync _shared.yaml to template | Breaks project-specific includes |
| Sync without reviewing diffs | May propagate project-specific content |
| Sync architecture/patterns files | These are project documentation |

## Design Philosophy

- **No markers required** - Classification is inferred from content
- **Conservative by default** - When in doubt, skip (false negatives are safer)
- **User confirms** - Always present selection before applying
- **Bidirectional awareness** - Complements project-sync for full workflow
