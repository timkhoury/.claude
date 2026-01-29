---
name: rule-writer
description: >
  Creates Claude Code rules with proper placement and sync behavior.
  Use when creating new rules, deciding project vs template location,
  or configuring technology detection.
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

| Technology Type | Naming | Example |
|-----------------|--------|---------|
| Testing framework | Use framework name | `vitest.md`, `playwright.md` |
| Non-testing tech with testing patterns | Add `-testing` suffix | `supabase-testing.md` |

**Why the suffix?** Distinguishes testing patterns from general usage patterns.

## Rule vs Skill Decision

| Use | When |
|-----|------|
| **Rule** | Always-needed context (patterns, conventions, architecture) |
| **Skill** | On-demand workflows (setup, sync, troubleshooting) |

**Quick test:** Is this needed for most coding tasks? → Rule. Is this a workflow triggered occasionally? → Skill.

## Rule Compression Guidelines

Rules are always-loaded context. Keep them concise to maximize signal-to-noise ratio.

| Technique | Example |
|-----------|---------|
| Pipe-delimited tables | `Context \| Client \| Notes` instead of prose |
| Cross-references | `See supabase.md for core patterns` instead of duplicating |
| Compressed lists | `Applies to frameworks, libraries, tools, APIs` instead of bullet list |
| Remove redundant examples | One example per pattern, not three |

**Integration rules** (e.g., `nextjs-supabase.md`) should:
- Reference base rules for shared concepts
- Only document what's unique to the integration
- Avoid duplicating content from either base rule

## Template Sync Rules

**From project to template (`template-updater`):**
- Syncs `rules/tech/`, `rules/patterns/`, `rules/workflow/`, `rules/meta/`
- **Never syncs** `rules/project/`

**From template to project (`project-updater`):**
- Copies detected technology rules
- **Never overwrites** `rules/project/`

## Checklist for New Rules

- [ ] Determined correct location (tech/patterns/workflow/meta/project)
- [ ] Project-specific content in `rules/project/` only
- [ ] One technology per file (integrations separate)
- [ ] Testing rules use `-testing` suffix if not a testing framework
- [ ] Updated sync-config.yaml if new technology detection needed
- [ ] Tested detection with `detect-technologies.sh --report`

## Reference

- **SYNC-CONFIG.md** - Detection methods, configuration format, adding new technologies
