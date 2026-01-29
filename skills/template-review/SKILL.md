---
name: template-review
description: >
  Validate ~/.claude/template/ structure and sync-config integrity.
  Checks for missing files, broken references, and circular dependencies.
  Use when sync fails or to audit template health.
---

# Template Review

Deterministic validation of the template directory structure, sync-config references, and skill organization.

## Quick Start

```bash
# Run all checks
~/.claude/skills/template-review/validate-template.sh

# JSON output for scripting
~/.claude/skills/template-review/validate-template.sh --json

# Run specific checks
~/.claude/skills/template-review/validate-template.sh sync-config
~/.claude/skills/template-review/validate-template.sh skills rules
```

## Check Categories

| Check | What It Validates |
|-------|-------------------|
| `sync-config` | Rules/skills/commands paths exist, requires chains valid |
| `skills` | SKILL.md exists with valid frontmatter |
| `rules` | Rule files exist and are valid markdown |
| `commands` | Command files exist |
| `circular` | No circular dependencies in requires chains |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks pass |
| 1 | Warnings found (non-breaking) |
| 2 | Errors found (breaking issues) |

## Output Modes

**Report mode (default):**
```
Checking sync-config...
  OK: rules/meta/ exists
  ERROR: commands/work.md not found
  WARN: skill description >300 chars

Summary: 2 errors, 1 warning
```

**JSON mode:**
```json
{
  "errors": [...],
  "warnings": [...],
  "passed": [...]
}
```

## Workflow

1. Run `/template-review` after editing sync-config or template structure
2. Fix any errors before syncing to projects
3. Warnings are informational but worth reviewing

## See Also

- `CHECKS.md` - Detailed check descriptions
- `/project-updater` - Update projects from template
- `/skills-review` - Audit skill context efficiency

## After Completion

Record this review:

```bash
~/.claude/template/scripts/systems-tracker.sh record template-review
```
