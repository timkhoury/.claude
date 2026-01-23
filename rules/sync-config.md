# Sync Configuration

> Configure what gets synced between template and projects.

## Overview

The sync config defines what content is always copied, and what is copied based on detected technologies.

**Config:** `~/.claude/config/sync-config.yaml`
**Script:** `~/.claude/scripts/detect-technologies.sh`

## Configuration Sections

| Section | Purpose |
|---------|---------|
| `always` | Rules and skills copied to every project |
| `technologies` | Tech-specific rules (includes integrations) |
| `tools` | Workflow tools and integrations (beads, openspec) |

## Detection Methods

| Method | What It Checks |
|--------|----------------|
| `packages` | package.json dependencies/devDependencies |
| `configs` | Config file existence (next.config.js, etc.) |
| `directories` | Directory existence (supabase/, components/ui/) |
| `requires` | Other detected items (for integrations) |
| `requires_any` | At least one of these (optional with `requires`) |

## Configuration Format

```yaml
# Always copied (not technology-dependent)
always:
  rules:
    - meta/
    - patterns/
    - workflow/
  skills:
    - authoring/
    - quality/
    - workflow/
    - automation/

# Technology-specific rules
technologies:
  nextjs:
    detect:
      packages:
        - next
      configs:
        - next.config.js
        - next.config.ts
    rules:
      - tech/nextjs.md

  # Integration (uses requires instead of packages/configs)
  nextjs-supabase:
    detect:
      requires:
        - nextjs
        - supabase
    rules:
      - tech/nextjs-supabase.md

  supabase-testing:
    detect:
      requires:
        - supabase
      requires_any:
        - vitest
        - playwright
    rules:
      - tech/supabase-testing.md

# Workflow tools
tools:
  beads:
    detect:
      directories:
        - .beads/
    rules:
      - workflow/beads-workflow.md
    skills:
      - workflow/beads-cleanup/
    commands:
      - work.md

  # Tool integration (uses requires)
  beads+openspec:
    detect:
      requires:
        - beads
        - openspec
    rules:
      - workflow/workflow-integration.md
    commands:
      - wrap.md
```

## Adding New Technologies

1. Edit `~/.claude/config/sync-config.yaml`
2. Add detection patterns under `technologies`
3. Create the rule file in `~/.claude/template/rules/tech/`
4. Test with `~/.claude/scripts/detect-technologies.sh --report`

## Script Usage

```bash
# Human-readable report
~/.claude/scripts/detect-technologies.sh --report

# List detected technology names
~/.claude/scripts/detect-technologies.sh --techs

# List rule paths to copy
~/.claude/scripts/detect-technologies.sh --rules

# List skill paths to copy
~/.claude/scripts/detect-technologies.sh --skills

# JSON output for scripts
~/.claude/scripts/detect-technologies.sh --json
```

## Used By

| Skill | How It Uses Detection |
|-------|----------------------|
| `/project-setup` | Initial setup - copies detected tech rules |
| `/project-sync` | Adds new tech rules, removes unused (with confirmation) |
