---
name: sync
description: >
  Synchronize project and template configurations bidirectionally.
  Runs template-updater then project-sync in correct order.
  Use when syncing changes between project .claude/ and ~/.claude/template/.
allowed-tools: [Bash, Read, Write, AskUserQuestion]
---

# Sync

Bidirectional sync between project `.claude/` and `~/.claude/template/`.

## Why Order Matters

1. **template-updater first** - Push local improvements to template
2. **project-sync second** - Pull template updates to project

Running in wrong order would overwrite local improvements before they're pushed.

## Usage

Invoke both skills in order:

1. `/template-updater` - Push local improvements to template
2. `/project-sync` - Pull template updates to project

## Workflow

1. Invoke `/template-updater` skill
2. Handle any file copies needed
3. Invoke `/project-sync` skill
4. Handle any file copies needed
5. Summarize what changed

## After Sync

If any files were copied, commit the changes:

**Project changes:**
```bash
but status
but commit <branch> --only -m "chore: sync claude config from template"
```

**Template changes:**
```bash
cd ~/.claude && but status
but commit <branch> --only -m "chore: update template from project"
```

## When to Use

- At session start (get latest template updates)
- After improving shared skills/rules (push to template)
- Periodically to keep project and template aligned
