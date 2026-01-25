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

## Workflow

### Step 1: Read Settings

```bash
cat ~/.claude/settings.json       # Global
cat settings.local.json           # Project-local
```

### Step 2: Analyze Permissions

For each permission in local settings:
- ✅ Safe - read-only, standard dev commands
- ⚠️ Needs confirmation - writes, deploys, destructive
- ❌ Keep local - project paths, env-specific
- 🔄 Already global - skip

### Step 3: Present Findings

```
### ✅ Safe to Promote (N permissions)
**Testing** - npm run test, npm run test:coverage
**Building** - npm run build, npm run dev

### ⚠️ Needs Approval (N permissions)
**Git Mutations** - but commit * (creates commits)

### ❌ Keep Project-Local
- ./scripts/custom.sh (hardcoded path)

### 🔄 Already Global
- npm install
```

### Step 4: Get Confirmation

Use `AskUserQuestion`:

**For safe permissions:**
- "Promote all N safe permissions?"
- Options: Yes / Review individually / Skip

**For risky permissions:**
- Multi-select with descriptions
- Include "Skip all" option

### Step 5: Apply Changes

1. Read current global settings
2. Merge approved permissions
3. Remove duplicates
4. Sort by category
5. Write updated settings
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
