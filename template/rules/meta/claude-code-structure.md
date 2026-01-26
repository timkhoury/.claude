# Claude Code Structure

> Convention for organizing `.claude/` configuration.

## Directory Overview

```
.claude/
├── rules/          # Always-loaded context
│   ├── tech/       # Technology patterns (syncs)
│   ├── patterns/   # Cross-cutting patterns (syncs)
│   ├── workflow/   # Workflow rules (syncs)
│   ├── meta/       # Meta rules (syncs)
│   └── project/    # Project-specific (NEVER syncs)
├── skills/         # On-demand workflows
└── agents/         # Subagent definitions
```

## Rule vs Skill

| Use | When |
|-----|------|
| **Rule** | Always-needed context (patterns, conventions) |
| **Skill** | On-demand workflows, reference docs |

## Authoring Guidance

Use `/rule-writer` for creating rules (placement, naming, sync config).

Use `/skill-writer` for creating skills (structure, descriptions, directory conventions).
