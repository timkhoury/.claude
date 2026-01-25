---
name: settings-updater
description: >
  Analyze project settings.local.json and suggest permissions to promote to global.
  Use when reviewing settings or standardizing permissions across projects.
---

# Settings Updater

Compare project-local settings with global and suggest safe permissions to promote.

## Critical Rules

1. **Always get user confirmation** - Even safe permissions need approval
2. **Group by category** - Testing, Git, Building, etc.
3. **Flag project-specific** - Don't promote paths or env-specific commands
4. **Use visual indicators** - ✅⚠️❌🔄

**See `PATTERNS.md` for safety classification and category patterns.**

## Usage

```bash
~/.claude/skills/settings-updater/analyze-settings.sh [--stale|--compare|--report]
```

| Flag | Purpose |
|------|---------|
| `--stale` | Check for stale paths in global settings |
| `--compare` | Compare local vs global permissions |
| `--report` | Full report (default) |

The script is **report-only** - it shows the analysis but makes no changes. Claude reads the report and applies changes based on user confirmation.

## Workflow

### Step 1: Run Analysis

```bash
~/.claude/skills/settings-updater/analyze-settings.sh
```

The script outputs categorized permissions:
- ✅ Safe to promote - read-only, standard dev commands
- ⚠️ Needs confirmation - writes, deploys, destructive
- ❌ Keep project-local - project paths, env-specific
- 🔄 Already global - skip (can be removed from local)
- 🗑️ One-off commands - accumulated cruft to clean

### Step 2: Handle Stale Paths

If any global script paths don't exist:
- Show the stale permissions
- Ask user to confirm removal
- Edit `~/.claude/settings.json` to remove them

### Step 3: Get Confirmation

Use `AskUserQuestion`:

**For safe permissions:**
- "Promote all N safe permissions?"
- Options: Yes / Review individually / Skip

**For risky permissions:**
- Multi-select with descriptions
- Include "Skip all" option

**For one-off commands:**
- Ask if user wants to clean them from local settings

### Step 4: Apply Changes

1. Read current global settings
2. Merge approved permissions
3. Remove duplicates
4. Write updated global settings
5. Remove promoted/cleaned items from local settings
6. Show summary

## Output Format

```
## Settings Updated

### ✅ Promoted to Global (N)
- npm run test
- npm run build

### ⚠️ Promoted with Confirmation (N)
- but commit *

### ❌ Kept Project-Local (N)
- ./scripts/custom.sh

**Files:**
- Global: ~/.claude/settings.json
- Local: settings.local.json (unchanged)
```

## When to Use

- After setting up a new project
- When seeing repeated permission prompts
- Periodically to standardize settings

## After Completion

Record this review:

```bash
~/.claude/skills/systems-review/review-tracker.sh record settings-updater
```
