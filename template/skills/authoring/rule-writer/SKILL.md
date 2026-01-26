---
name: rule-writer
description: >
  Creates and organizes Claude Code rules with proper placement and sync behavior.
  Use when creating new rules, deciding between project vs template rules, adding
  technology detection, or understanding what syncs between template and projects.
---

# Rule Writing Guidelines

Standards for creating and organizing Claude Code rules.

## Critical Rules

1. **One technology per file** - Cross-technology patterns go in integration files (`nextjs-supabase.md`)
2. **Project rules never sync** - Content in `rules/project/` stays in the project
3. **Testing suffix for non-testing tech** - `supabase-testing.md` not `supabase.md` for test patterns
4. **Rules are always-loaded** - Keep them concise; use skills for on-demand content

## Rule Placement Decision Tree

```
Is this rule project-specific?
│
├─ YES (specific to this codebase's architecture)
│  └─ rules/project/* ONLY
│     Examples: architecture, infrastructure, testing config
│
└─ NO (reusable across projects)
   │
   ├─ Technology pattern?
   │  └─ rules/tech/{tech}.md
   │
   ├─ Cross-cutting pattern?
   │  └─ rules/patterns/{pattern}.md
   │
   ├─ Workflow process?
   │  └─ rules/workflow/{workflow}.md
   │
   └─ Claude Code configuration?
      └─ rules/meta/{topic}.md
```

**Key question:** Would this rule make sense in a different project using the same technology? If no → `project/`.

## Rules Directory Structure

```
.claude/rules/
├── tech/           # Technology-specific patterns (syncs)
├── patterns/       # Cross-cutting patterns (syncs)
├── workflow/       # Workflow rules (syncs)
├── meta/           # Meta rules (syncs)
└── project/        # Project-specific (NEVER syncs)
```

| Directory | Content | Synced to Template |
|-----------|---------|-------------------|
| `tech/` | Single-technology patterns | Yes |
| `patterns/` | Reusable patterns | Yes |
| `workflow/` | Workflow processes | Yes |
| `meta/` | Claude Code configuration | Yes |
| `project/` | Project-specific content | **No** |

## Tech Rules Naming

**One technology per file.** Cross-technology patterns belong in integration files.

| Pattern | Example |
|---------|---------|
| Pure technology | `nextjs.md`, `supabase.md` |
| Integration | `nextjs-supabase.md`, `tailwind-shadcn.md` |

### Testing Rules (`tech/testing/`)

Testing-related rules live in `tech/testing/`. Naming depends on whether the technology is a testing framework:

| Technology Type | Naming | Example |
|-----------------|--------|---------|
| Testing framework | Use framework name | `vitest.md`, `playwright.md` |
| Non-testing tech with testing patterns | Add `-testing` suffix | `supabase-testing.md` |

**Why the suffix?** It distinguishes testing patterns from general usage patterns. `supabase.md` covers clients, RLS, and queries; `supabase-testing.md` covers test cleanup and fixtures.

**Agent configuration:** The `tech/testing/` folder is configured as a separate include (`$includes.testing`) in `_template.yaml`, not auto-discovered under `$includes.tech`. This allows the `testing` bundle to include only testing-related rules.

## Rule vs Skill Decision

| Use | When |
|-----|------|
| **Rule** | Always-needed context (patterns, conventions, architecture) |
| **Skill** | On-demand workflows (setup, sync, troubleshooting) |

**Quick test:** Is this needed for most coding tasks? → Rule. Is this a workflow triggered occasionally? → Skill.

## Template Sync Rules

**From project to template (`template-updater`):**
- Syncs `rules/tech/`, `rules/patterns/`, `rules/workflow/`, `rules/meta/`
- **Never syncs** `rules/project/`

**From template to project (`project-sync`):**
- Copies detected technology rules
- **Never overwrites** `rules/project/`

---

# Sync Configuration

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
| `/project-sync` | Adds new tech rules, removes unused (with confirmation) |

## Checklist for New Rules

- [ ] Determined correct location (tech/patterns/workflow/meta/project)
- [ ] Project-specific content in `rules/project/` only
- [ ] One technology per file (integrations separate)
- [ ] Testing rules use `-testing` suffix if not a testing framework
- [ ] Updated sync-config.yaml if new technology detection needed
- [ ] Tested detection with `detect-technologies.sh --report`
