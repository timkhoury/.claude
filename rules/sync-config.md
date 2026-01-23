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
| `technologies` | Tech-specific rules copied when detected |
| `integrations` | Rules for technology combinations |

## Technology Detection

| Method | What It Checks |
|--------|----------------|
| `packages` | package.json dependencies/devDependencies |
| `configs` | Config file existence (next.config.js, etc.) |
| `directories` | Directory existence (supabase/, components/ui/) |

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

# Integration rules (require multiple technologies)
integrations:
  - name: nextjs-supabase
    requires:
      - nextjs
      - supabase
    rules:
      - tech/nextjs-supabase.md

  - name: supabase-testing
    requires:
      - supabase
    requires_any:        # At least one of these
      - vitest
      - playwright
    rules:
      - tech/supabase-testing.md
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

# JSON output for scripts
~/.claude/scripts/detect-technologies.sh --json
```

## Used By

| Skill | How It Uses Detection |
|-------|----------------------|
| `/project-setup` | Initial setup - copies detected tech rules |
| `/project-sync` | Adds new tech rules, removes unused (with confirmation) |
