# Sync Configuration Reference

Configure technology detection and sync behavior in `~/.claude/config/sync-config.yaml`.

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
  openspec:
    detect:
      directories:
        - openspec/
    rules:
      - workflow/openspec.md
      - workflow/task-workflow.md
    skills:
      - tools/openspec/spec-review/
    commands:
      - wrap.md
```

## Adding New Technologies

1. Edit `~/.claude/config/sync-config.yaml`
2. Add detection patterns under `technologies`
3. Create the rule file in `~/.claude/template/rules/tech/`
4. Test with `~/.claude/scripts/detect-technologies.sh --report`

## Detection Script

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

| Skill | How It Uses Detection |
|-------|----------------------|
| `/project-setup` | Initial setup - copies detected tech rules |
| `/project-updater` | Adds new tech rules, removes unused (with confirmation) |
